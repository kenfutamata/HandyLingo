// ============================================================
//  start_using.dart  —  FIXED VERSION  (v2 — smooth skeleton)
//
//  Changes from previous revision
//  ────────────────────────────────────────────────────────────
//  FIX A — Skeleton shown BEFORE capture begins
//    Root cause: _startSkeletonPolling() was only called inside
//    _startCaptureSequence(), and _pollLandmark() bailed early
//    when _captureRawFrames was empty.  So the overlay was
//    invisible until the user pressed "CAPTURE SIGN".
//
//    Fix:
//      • _initCamera() now starts a continuous image stream
//        immediately after the controller is initialised.
//      • A lightweight _latestRawFrame field (Map?) is always
//        updated by the stream callback; capture-mode frames are
//        still collected into _captureRawFrames as before.
//      • _startSkeletonPolling() is called right after the camera
//        is ready — skeleton overlay is live in idle/preview state.
//      • _pollLandmark() uses _latestRawFrame instead of
//        _captureRawFrames.last, so it works with 0 captured frames.
//      • The "Hand detected" badge no longer requires _isCapturing.
//
//  FIX B — Smooth skeleton (no stutter / lag)
//    Root cause: 300 ms poll interval  +  800 ms HTTP timeout
//    → the skeleton could skip several poll cycles while a slow
//    request was in-flight, producing choppy animation.
//
//    Fix:
//      • Poll interval  : 300 ms → 100 ms
//      • Landmark timeout: 800 ms → 300 ms  (local LAN server)
//      • The _isPollingSkeleton guard still prevents pile-up.
//
//  FIX C — Stream lifecycle
//    Previously the image stream was started in
//    _startCaptureSequence() and stopped in _finishCapture().
//    Now the stream runs continuously from _initCamera() until
//    dispose() / camera switch.  Capture only sets/clears the
//    _isCapturingStream flag to gate frame collection.
//
//  Everything else unchanged from the previous revision.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

import 'account_page.dart';

// ─────────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────────

/// Maximum capture duration in seconds.
const double _kMaxCaptureSecs = 10.0;

/// Frame throttle — keep every Nth camera frame during capture.
/// At ~30 fps, N=3 → ~10 fps → ~100 raw frames in 10 s.
const int _kFrameSkip = 3;

/// Max frames sent to server per prediction request.
/// Flutter subsamples captured frames down to this count before
/// uploading. The server's np.linspace resampler converts any
/// input count → 100 frames, so the model always gets 100 frames.
const int _kMaxUploadFrames = 30;

// ─────────────────────────────────────────────────────────────
//  MediaPipe hand connections for skeleton drawing
// ─────────────────────────────────────────────────────────────
const _kHandConnections = [
  [0, 1],
  [1, 2],
  [2, 3],
  [3, 4],
  [0, 5],
  [5, 6],
  [6, 7],
  [7, 8],
  [0, 9],
  [9, 10],
  [10, 11],
  [11, 12],
  [0, 13],
  [13, 14],
  [14, 15],
  [15, 16],
  [0, 17],
  [17, 18],
  [18, 19],
  [19, 20],
  [5, 9],
  [9, 13],
  [13, 17],
];

// ─────────────────────────────────────────────────────────────
//  Isolate helpers — raw CameraImage bytes → JPEG
// ─────────────────────────────────────────────────────────────

Uint8List? _convertSingleFrame(Map<String, dynamic> f) {
  try {
    return _convertFrames([f]).firstOrNull;
  } catch (_) {
    return null;
  }
}

List<Uint8List> _convertFrames(List<Map<String, dynamic>> rawFrames) {
  final result = <Uint8List>[];
  for (final f in rawFrames) {
    try {
      final int w = f['w'] as int;
      final int h = f['h'] as int;
      final String fmt = f['fmt'] as String;
      final int sensorOrientation = f['sensorOrientation'] as int? ?? 0;
      img.Image imgObj;

      if (fmt == 'bgra') {
        final bytes = f['bytes'] as Uint8List;
        imgObj = img.Image.fromBytes(
          width: w,
          height: h,
          bytes: bytes.buffer,
          order: img.ChannelOrder.bgra,
          numChannels: 4,
        );
      } else {
        final Uint8List yBytes = f['y'] as Uint8List;
        final int yStride = f['yStride'] as int;
        final rgb = Uint8List(w * h * 3);
        for (int row = 0; row < h; row++) {
          final int rowBase = row * yStride;
          final int rgbBase = row * w * 3;
          for (int col = 0; col < w; col++) {
            final int gray = yBytes[rowBase + col];
            final int i = rgbBase + col * 3;
            rgb[i] = gray;
            rgb[i + 1] = gray;
            rgb[i + 2] = gray;
          }
        }
        imgObj = img.Image.fromBytes(
          width: w,
          height: h,
          bytes: rgb.buffer,
          numChannels: 3,
          order: img.ChannelOrder.rgb,
        );
        if (sensorOrientation != 0) {
          imgObj = img.copyRotate(imgObj, angle: sensorOrientation);
        }
      }
      result.add(Uint8List.fromList(img.encodeJpg(imgObj, quality: 80)));
    } catch (_) {}
  }
  return result;
}

// ─────────────────────────────────────────────────────────────
//  LandmarkPainter
// ─────────────────────────────────────────────────────────────

class LandmarkPainter extends CustomPainter {
  final List<dynamic> leftHand;
  final List<dynamic> rightHand;
  final bool mirrorX;

  const LandmarkPainter({
    required this.leftHand,
    required this.rightHand,
    this.mirrorX = true,
  });

  double _px(double x, double w) => mirrorX ? (1.0 - x) * w : x * w;
  double _py(double y, double h) => y * h;

  void _drawHand(
    Canvas canvas,
    Size size,
    List<dynamic> landmarks,
    Color dotColor,
    Color lineColor,
  ) {
    if (landmarks.isEmpty) return;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (final conn in _kHandConnections) {
      final a = landmarks[conn[0]];
      final b = landmarks[conn[1]];
      canvas.drawLine(
        Offset(
          _px((a[0] as num).toDouble(), size.width),
          _py((a[1] as num).toDouble(), size.height),
        ),
        Offset(
          _px((b[0] as num).toDouble(), size.width),
          _py((b[1] as num).toDouble(), size.height),
        ),
        linePaint,
      );
    }
    for (final lm in landmarks) {
      canvas.drawCircle(
        Offset(
          _px((lm[0] as num).toDouble(), size.width),
          _py((lm[1] as num).toDouble(), size.height),
        ),
        4,
        dotPaint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawHand(
      canvas,
      size,
      leftHand,
      const Color(0xFF00E5FF),
      const Color(0xFF0097A7),
    );
    _drawHand(
      canvas,
      size,
      rightHand,
      const Color(0xFFFFD740),
      const Color(0xFFFF6F00),
    );
  }

  @override
  bool shouldRepaint(LandmarkPainter old) =>
      old.leftHand != leftHand || old.rightHand != rightHand;
}

// ─────────────────────────────────────────────────────────────
//  Page
// ─────────────────────────────────────────────────────────────

enum InputMode { signLanguage, text }

enum SignLanguageType { asl, fsl }

class StartUsingPage extends StatefulWidget {
  const StartUsingPage({super.key});
  @override
  State<StartUsingPage> createState() => _StartUsingPageState();
}

class _StartUsingPageState extends State<StartUsingPage>
    with WidgetsBindingObserver {
  // ── Server ──────────────────────────────────────────────────
  static const String _serverUrl = "http://192.168.254.156:8001/predict";
  static const String _landmarkUrl = "http://192.168.254.156:8001/landmark";

  bool _serverReachable = true;

  final _supabase = Supabase.instance.client;
  final FlutterTts _flutterTts = FlutterTts();

  InputMode _mode = InputMode.signLanguage;
  SignLanguageType _languageType = SignLanguageType.asl;

  // ── Camera ──────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isFrontCamera = true;
  bool _isCapturing = false;
  bool _isSending = false;
  bool _isStreamActive = false;

  // ── Capture state ────────────────────────────────────────────
  final List<Map<String, dynamic>> _captureRawFrames = [];
  bool _isCapturingStream = false;
  int _captureFrameTick = 0;
  int _capturedCount = 0;
  double _captureSecondsLeft = _kMaxCaptureSecs;
  Timer? _captureTimer;
  Timer? _countdownTimer;

  // ── FIX A: always-available latest frame for skeleton polling ─
  // Updated every camera tick; does NOT require capture to be active.
  Map<String, dynamic>? _latestRawFrame;

  // ── Landmark state ───────────────────────────────────────────
  List<dynamic> _leftHandLandmarks = [];
  List<dynamic> _rightHandLandmarks = [];
  Timer? _landmarkPollTimer;
  bool _isPollingSkeleton = false;

  // ── Output ──────────────────────────────────────────────────
  String _accumulatedSentence = "";
  String _currentStatus = "Ready";
  String _textSize = 'Small';

  /// Each entry: {'word': 'HOW ARE YOU', 'pct': 98.0}
  final List<Map<String, dynamic>> _predictions = [];

  // ── Text-to-Sign input ───────────────────────────────────────
  final TextEditingController _textToSignController = TextEditingController();

  // ── Sign.MT WebView ─────────────────────────────────────────
  late final WebViewController _signWebController;
  bool _signMtReady = false;

  // ── Speech-to-text ──────────────────────────────────────────
  late final stt.SpeechToText _speechToText;
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _voiceEnabled = true;
  String _recognizedSpeech = "";

  // ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTts();
    _initSpeechRecognition();
    _initializeSignWeb();
    _loadVoicePreference();
    _loadTextSizePreference();
    _initCamera();
  }

  // ── TTS ─────────────────────────────────────────────────────
  Future<void> _initTts() async {
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _applyTtsLanguage();
  }

  Future<void> _applyTtsLanguage() async {
    final lang = _languageType == SignLanguageType.fsl ? "fil-PH" : "en-US";
    await _flutterTts.setLanguage(lang);
  }

  Future<void> _loadVoicePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _voiceEnabled = prefs.getBool('voice_enabled') ?? true);
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('voice_enabled') ?? true)) return;
    await _applyTtsLanguage();
    await _flutterTts.speak(text);
  }

  // ── Supabase ────────────────────────────────────────────────
  Future<void> _saveLogToSupabase(String word, double accuracy) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('sign_language_logs').insert({
        'id': const Uuid().v4(),
        'user_id': user.id,
        'translated_output': word,
        'accuracy': accuracy,
      });
    } catch (e) {
      debugPrint("Supabase Save Error: $e");
    }
  }

  // ── Camera init ─────────────────────────────────────────────
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Cancel skeleton polling before tearing down the old controller.
    _landmarkPollTimer?.cancel();

    if (_cameraController != null) {
      if (_isStreamActive) {
        await _cameraController!.stopImageStream();
        _isStreamActive = false;
      }
      await _cameraController!.dispose();
    }

    final selectedCamera = cameras.firstWhere(
      (c) =>
          c.lensDirection ==
          (_isFrontCamera
              ? CameraLensDirection.front
              : CameraLensDirection.back),
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.low,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;

      // ── FIX A + C: start a continuous stream immediately ─────
      // The stream feeds _latestRawFrame for live skeleton polling.
      // Capture frames are collected only while _isCapturingStream
      // is true (set/cleared by _startCaptureSequence / _finishCapture).
      await _cameraController!.startImageStream((CameraImage image) {
        // Always keep the freshest frame available for skeleton polling.
        _latestRawFrame = _extractRawFrame(image);

        // Only collect frames into the capture buffer when actively recording.
        if (!_isCapturingStream) return;

        _captureFrameTick++;
        if (_captureFrameTick % _kFrameSkip != 0) return;
        try {
          _captureRawFrames.add(_latestRawFrame!);
          if (mounted) setState(() => _capturedCount = _captureRawFrames.length);
        } catch (e) {
          debugPrint("Frame copy error: $e");
        }
      });
      _isStreamActive = true;

      // ── FIX A: start skeleton polling right away ──────────────
      _startSkeletonPolling();

      setState(() {});
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  void _toggleCamera() {
    if (_isCapturing || _isSending) return;
    setState(() => _isFrontCamera = !_isFrontCamera);
    _initCamera();
  }

  void _toggleLanguage() {
    setState(() {
      _languageType = _languageType == SignLanguageType.asl
          ? SignLanguageType.fsl
          : SignLanguageType.asl;
    });
  }

  // ── Extract raw frame bytes ──────────────────────────────────
  Map<String, dynamic> _extractRawFrame(CameraImage image) {
    final fmt = image.format.group;
    final w = image.width;
    final h = image.height;
    final int sensorOrientation =
        _cameraController!.description.sensorOrientation;

    if (fmt == ImageFormatGroup.bgra8888) {
      return {
        'fmt': 'bgra',
        'w': w,
        'h': h,
        'bytes': Uint8List.fromList(image.planes[0].bytes),
        'sensorOrientation': sensorOrientation,
      };
    } else {
      return {
        'fmt': 'yuv',
        'w': w,
        'h': h,
        'y': Uint8List.fromList(image.planes[0].bytes),
        'yStride': image.planes[0].bytesPerRow,
        'sensorOrientation': sensorOrientation,
      };
    }
  }

  // ── 10-second capture ────────────────────────────────────────
  Future<void> _startCaptureSequence() async {
    if (_isCapturing || _isSending || _cameraController == null) return;
    if (!(_cameraController!.value.isInitialized)) return;

    _captureRawFrames.clear();
    _captureFrameTick = 0;
    _capturedCount = 0;

    setState(() {
      _isCapturing = true;
      _currentStatus = "Recording...";
      _captureSecondsLeft = _kMaxCaptureSecs;
      _leftHandLandmarks = [];
      _rightHandLandmarks = [];
    });

    // ── FIX C: stream is already running — just open the gate ───
    // No need to call startImageStream() here; the stream started
    // in _initCamera().  Setting _isCapturingStream = true causes
    // the already-running callback to begin collecting frames.
    _isCapturingStream = true;

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _captureSecondsLeft = (_captureSecondsLeft - 0.1).clamp(
          0.0,
          _kMaxCaptureSecs,
        );
      });
    });

    // ── FIX A: skeleton polling is already running — no restart ─

    _captureTimer = Timer(
      Duration(seconds: _kMaxCaptureSecs.toInt()),
      () => _finishCapture(),
    );
  }

  Future<void> _finishCapture() async {
    if (!_isCapturing) return;

    // Close the capture gate; leave the image stream running so the
    // skeleton overlay stays live while the upload is in progress.
    _isCapturingStream = false;
    _countdownTimer?.cancel();
    _captureTimer?.cancel();

    // ── FIX C: do NOT stop the image stream here ─────────────────
    // The stream keeps feeding _latestRawFrame so skeleton polling
    // continues smoothly during the "Analyzing..." phase and after.

    await _processAndUpload();
  }

  // ── Real-time skeleton polling ────────────────────────────────
  void _startSkeletonPolling() {
    _landmarkPollTimer?.cancel();
    // ── FIX B: 100 ms interval (was 300 ms) ─────────────────────
    _landmarkPollTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _pollLandmark(),
    );
  }

  Future<void> _pollLandmark() async {
    // ── FIX A: use _latestRawFrame, not _captureRawFrames ────────
    // This works before, during, and after capture.
    if (_latestRawFrame == null || _isPollingSkeleton) return;
    _isPollingSkeleton = true;
    try {
      final rawFrame = Map<String, dynamic>.from(_latestRawFrame!);
      final jpegBytes = await compute(_convertSingleFrame, rawFrame);
      if (jpegBytes == null || !mounted) return;

      final request = http.MultipartRequest('POST', Uri.parse(_landmarkUrl));
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          jpegBytes,
          filename: 'landmark_frame.jpg',
        ),
      );
      // ── FIX B: 300 ms timeout (was 800 ms) — local LAN server ──
      final response = await request.send().timeout(
        const Duration(milliseconds: 300),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(await response.stream.bytesToString());
        setState(() {
          _serverReachable = true;
          _leftHandLandmarks = body['left_hand'] as List<dynamic>? ?? [];
          _rightHandLandmarks = body['right_hand'] as List<dynamic>? ?? [];
        });
      }
    } on SocketException {
      if (mounted) setState(() => _serverReachable = false);
    } on TimeoutException {
      // skip this poll — landmark is cosmetic, not critical
    } catch (_) {
    } finally {
      _isPollingSkeleton = false;
    }
  }

  // ── Convert + Upload ─────────────────────────────────────────
  Future<void> _processAndUpload() async {
    setState(() {
      _isCapturing = false;
      _isSending = true;
      _currentStatus = "Analyzing...";
    });

    if (_captureRawFrames.isEmpty) {
      setState(() {
        _isSending = false;
        _currentStatus = "No frames — try again";
      });
      return;
    }

    try {
      // Convert all captured raw frames to JPEG in a background isolate
      final List<Uint8List> allJpegFrames = await compute(
        _convertFrames,
        List<Map<String, dynamic>>.from(_captureRawFrames),
      );

      debugPrint(
        "[CAPTURE] ${_captureRawFrames.length} raw → "
        "${allJpegFrames.length} JPEGs",
      );

      if (allJpegFrames.isEmpty) {
        setState(() {
          _isSending = false;
          _currentStatus = "Conversion failed — retry";
        });
        return;
      }

      // Subsample to _kMaxUploadFrames (30) frames
      final List<Uint8List> jpegFrames;
      if (allJpegFrames.length <= _kMaxUploadFrames) {
        jpegFrames = allJpegFrames;
      } else {
        final step = (allJpegFrames.length - 1) / (_kMaxUploadFrames - 1);
        jpegFrames = List.generate(
          _kMaxUploadFrames,
          (i) => allJpegFrames[(i * step).round()],
        );
      }

      debugPrint(
        "[UPLOAD]  ${allJpegFrames.length} JPEGs subsampled → "
        "${jpegFrames.length} sent to server",
      );

      // Write subsampled frames to temp files
      final tmpDir = await getTemporaryDirectory();
      final tmpFiles = <File>[];
      for (int i = 0; i < jpegFrames.length; i++) {
        final f = File(
          '${tmpDir.path}/hcap_${i.toString().padLeft(4, '0')}.jpg',
        );
        await f.writeAsBytes(jpegFrames[i]);
        tmpFiles.add(f);
      }

      // POST to /predict
      final request = http.MultipartRequest('POST', Uri.parse(_serverUrl));
      request.fields['language'] = _languageType == SignLanguageType.asl
          ? "asl"
          : "fsl";
      for (final f in tmpFiles) {
        request.files.add(await http.MultipartFile.fromPath('files', f.path));
      }

      final response = await request.send().timeout(
        const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(await response.stream.bytesToString());
        final String word = json['prediction_label'] ?? "";
        final double confidence = (json['confidence'] ?? 0.0) * 100;

        final landmarks = json['landmarks'] as Map<String, dynamic>? ?? {};
        setState(() {
          _leftHandLandmarks = landmarks['left_hand'] as List<dynamic>? ?? [];
          _rightHandLandmarks = landmarks['right_hand'] as List<dynamic>? ?? [];
        });

        if (word.toUpperCase() != "(NONE)" && word.isNotEmpty) {
          setState(() {
            _predictions.add({'word': word, 'pct': confidence});
            _accumulatedSentence +=
                (_accumulatedSentence.isEmpty ? "" : " ") + word;
          });
          _speak(word);
          _saveLogToSupabase(word, confidence);
        }
        setState(() => _currentStatus = "Ready");
      } else {
        setState(() => _currentStatus = "Server error — retry");
      }

      for (final f in tmpFiles) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          _serverReachable = false;
          _currentStatus = "No server — check IP/firewall";
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _currentStatus = "Server timeout — try again");
      }
      debugPrint("[TIMEOUT] /predict exceeded 60s — HF CPU may be overloaded");
    } catch (e) {
      if (mounted) setState(() => _currentStatus = "Error — retry");
      debugPrint("Upload error: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
      _captureRawFrames.clear();
    }
  }

  // ── Text-to-Sign + TTS ───────────────────────────────────────
  Future<void> _submitTextToSign(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _textToSignController.clear();
    await Future.wait([_speak(trimmed), _injectTextIntoWebView(trimmed)]);
  }

  // ── Sign.MT WebView ─────────────────────────────────────────
  void _initializeSignWeb() {
    _signWebController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'SpeechToText',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'start') _startListening();
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            await _injectSignMtBridge();
            if (!mounted) return;
            setState(() => _signMtReady = true);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Sign.MT error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://sign.mt'));
  }

  Future<void> _initSpeechRecognition() async {
    _speechToText = stt.SpeechToText();
    final available = await _speechToText.initialize(
      onStatus: (s) => debugPrint('Speech: $s'),
      onError: (e) => debugPrint('Speech error: $e'),
    );
    if (!mounted) return;
    setState(() => _speechAvailable = available);
  }

  Future<void> _startListening() async {
    if (_isListening || !_speechAvailable) return;
    setState(() {
      _isListening = true;
      _recognizedSpeech = "";
    });
    await _speechToText.listen(
      onResult: (result) {
        setState(() => _recognizedSpeech = result.recognizedWords);
        if (result.finalResult) {
          _stopListening();
          _submitTextToSign(result.recognizedWords);
        }
      },
      localeId: _languageType == SignLanguageType.fsl ? 'fil_PH' : 'en_US',
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    await _speechToText.stop();
    if (!mounted) return;
    setState(() => _isListening = false);
  }

  Future<void> _injectTextIntoWebView(String text) async {
    if (!_signMtReady) {
      await _injectSignMtBridge();
      if (!mounted) return;
      setState(() => _signMtReady = true);
    }
    try {
      final encodedText = jsonEncode(text);
      await _signWebController.runJavaScript('''
        (function(text) {
          function findInput() {
            const sels = [
              'textarea:not([hidden]):not([disabled])',
              'input[type="text"]:not([hidden]):not([disabled])',
              '[contenteditable="true"]:not([hidden])'
            ];
            for (const s of sels) { const el = document.querySelector(s); if (el) return el; }
            return Array.from(document.querySelectorAll(
              'input,textarea,[contenteditable="true"]'
            )).find(el => {
              const l = ((el.getAttribute('placeholder')||el.getAttribute('aria-label')||'')+'').toLowerCase();
              return ['text','enter','sign','message'].some(k=>l.includes(k));
            });
          }
          function findBtn() {
            return document.querySelector(
              'button[type="submit"],input[type="submit"],'
              +'button[aria-label*="translate"],button[class*="translate"]'
            ) || Array.from(document.querySelectorAll('button,[role="button"]')).find(el=>{
              const t=((el.innerText||el.value||el.getAttribute('aria-label')||'')+'').toLowerCase();
              return ['translate','sign','go','send','submit','show'].some(p=>t.includes(p));
            });
          }
          const el = findInput(); if (!el) return;
          if ('value' in el) el.value=text; else el.textContent=text;
          el.dispatchEvent(new Event('input',{bubbles:true,composed:true}));
          el.dispatchEvent(new Event('change',{bubbles:true,composed:true}));
          setTimeout(()=>{
            const btn=findBtn();
            if(btn){
              ['mousedown','mouseup','click'].forEach(t=>btn.dispatchEvent(
                new MouseEvent(t,{bubbles:true})
              ));
              return;
            }
            el.dispatchEvent(new KeyboardEvent('keydown',
              {key:'Enter',code:'Enter',keyCode:13,bubbles:true}));
            const form=el.closest('form');
            if(form){
              if(typeof form.requestSubmit==='function') form.requestSubmit();
              else form.submit();
            }
          },120);
        })($encodedText);
      ''');
    } catch (e) {
      debugPrint('Sign.MT injection failed: $e');
    }
  }

  Future<void> _injectSignMtBridge() async {
    try {
      await _signWebController.runJavaScript('''
        (function(){
          if(window._flutterSignMt) return;
          window._flutterSignMt = {};
          function patch(){
            document.querySelectorAll('button').forEach(btn=>{
              if(btn.dataset.flutterMicHooked) return;
              const icon = btn.querySelector(
                'ion-icon[name*="mic"],svg[data-icon*="mic"],i[class*="mic"]'
              );
              if(!icon) return;
              btn.dataset.flutterMicHooked='true';
              btn.addEventListener('click', e=>{
                e.preventDefault(); e.stopPropagation();
                if(window.SpeechToText) window.SpeechToText.postMessage('start');
              }, true);
            });
          }
          patch();
          new MutationObserver(patch).observe(document.body,
            {childList:true,subtree:true});
        })();
      ''');
    } catch (e) {
      debugPrint('Sign.MT bridge failed: $e');
    }
  }

  Future<void> _loadTextSizePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('text_size') ?? 'Small';
    if (!mounted) return;
    setState(() => _textSize = value);
  }

  double get _sentenceTextSize {
    switch (_textSize) {
      case 'Large':
        return 24;
      case 'Medium':
        return 20;
      default:
        return 16;
    }
  }

  Color _confidenceColor(double pct) {
    if (pct >= 90) return const Color(0xFF00C853);
    if (pct >= 70) return const Color(0xFFFFD600);
    return const Color(0xFFFF6D00);
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD HELPERS
  // ─────────────────────────────────────────────────────────────

  Widget _buildLanguageChip() {
    return ChoiceChip(
      label: Text(
        _languageType == SignLanguageType.asl ? "ASL" : "FSL",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      selected: true,
      onSelected: (_) => _toggleLanguage(),
    );
  }

  Widget _buildSignModePreview() {
    if (!(_cameraController?.value.isInitialized ?? false)) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasLandmarks =
        _leftHandLandmarks.isNotEmpty || _rightHandLandmarks.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),

        // Server status dot (top-center)
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _serverReachable
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF1744),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _serverReachable
                        ? "Server connected"
                        : "Server unreachable",
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Hand skeleton overlay — always visible when landmarks exist
        if (hasLandmarks)
          Positioned.fill(
            child: CustomPaint(
              painter: LandmarkPainter(
                leftHand: _leftHandLandmarks,
                rightHand: _rightHandLandmarks,
                mirrorX: _isFrontCamera,
              ),
            ),
          ),

        // Recording overlay
        if (_isCapturing)
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _captureSecondsLeft.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Frames: $_capturedCount",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: LinearProgressIndicator(
                      value: 1.0 - (_captureSecondsLeft / _kMaxCaptureSecs),
                      backgroundColor: Colors.white24,
                      color: Colors.redAccent,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── FIX A: "Hand detected" badge — shown whenever landmarks
        // are present, not only during capture ──────────────────────
        if (hasLandmarks)
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E5FF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Hand detected",
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

        // Controls row (top-right) — flip + language toggle
        if (!_isCapturing)
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageChip(),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                    ),
                    onPressed: _toggleCamera,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSignMtWebView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _signWebController),

        // Mic button overlay
        if (!_isCapturing)
          Positioned(
            bottom: 16,
            right: 16,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.black,
              child: IconButton(
                onPressed: !_speechAvailable
                    ? null
                    : (_isListening ? _stopListening : _startListening),
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Colors.red : Colors.white,
                  size: 20,
                ),
                tooltip: _isListening ? "Stop listening" : "Speak to sign",
              ),
            ),
          ),

        // STT listening badge
        if (_isListening)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _recognizedSpeech.isEmpty
                        ? 'Listening...'
                        : _recognizedSpeech,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPredictionChips() {
    if (_predictions.isEmpty) {
      return Text(
        "Perform your sign...",
        style: TextStyle(
          fontSize: _sentenceTextSize,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: _predictions.map((p) {
        final word = p['word'] as String;
        final pct = p['pct'] as double;
        return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: word,
                style: TextStyle(
                  fontSize: _sentenceTextSize,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              TextSpan(
                text: ' (${pct.toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: _sentenceTextSize - 2,
                  fontWeight: FontWeight.w600,
                  color: _confidenceColor(pct),
                ),
              ),
              const TextSpan(text: ' '),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextToSignInputBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
      child: Row(
        children: [
          _buildLanguageChip(),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textToSignController,
              textInputAction: TextInputAction.send,
              onSubmitted: _submitTextToSign,
              decoration: InputDecoration(
                hintText: _languageType == SignLanguageType.fsl
                    ? "I-type para i-sign at magsalita..."
                    : "Type to sign + speak...",
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                filled: true,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _submitTextToSign(_textToSignController.text),
            icon: const Icon(Icons.send_rounded),
            color: theme.colorScheme.primary,
            tooltip: "Sign + Speak",
          ),
          IconButton(
            onPressed: !_speechAvailable
                ? null
                : (_isListening ? _stopListening : _startListening),
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : theme.colorScheme.primary,
            ),
            tooltip: _isListening ? "Stop listening" : "Speak to sign",
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () => setState(
              () => _mode = _mode == InputMode.signLanguage
                  ? InputMode.text
                  : InputMode.signLanguage,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _mode == InputMode.signLanguage ? '3D' : 'SL',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
                const Text(
                  'Switch',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            'HANDYLINGO',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountPage()),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 22, color: Colors.blue),
                const SizedBox(height: 4),
                Text(
                  'Account',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final isSignMode = _mode == InputMode.signLanguage;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "HandyLingo",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: isSignMode ? 3 : 5,
            child: Container(
              margin: isSignMode ? const EdgeInsets.all(12) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: isSignMode ? Colors.black : surfaceColor,
                borderRadius: isSignMode
                    ? BorderRadius.circular(20)
                    : BorderRadius.zero,
              ),
              clipBehavior: Clip.antiAlias,
              child: isSignMode
                  ? _buildSignModePreview()
                  : _buildSignMtWebView(),
            ),
          ),

          Expanded(
            flex: isSignMode ? 2 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isSignMode) ...[
                    const SizedBox(height: 10),
                    Text(
                      "MODE: ${_languageType.name.toUpperCase()} — $_currentStatus",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 10,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: _buildPredictionChips(),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_isCapturing)
                          ElevatedButton.icon(
                            onPressed: _finishCapture,
                            icon: const Icon(Icons.stop_rounded, size: 20),
                            label: Text(
                              "STOP  ${_captureSecondsLeft.toStringAsFixed(1)}s",
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _isSending
                                ? null
                                : _startCaptureSequence,
                            icon: const Icon(Icons.videocam, size: 20),
                            label: Text(
                              _isSending ? "ANALYZING..." : "CAPTURE SIGN",
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSending
                                  ? Colors.orange
                                  : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                          ),
                        IconButton(
                          onPressed: () => setState(() {
                            _accumulatedSentence = "";
                            _predictions.clear();
                          }),
                          icon: const Icon(Icons.refresh, color: Colors.blue),
                          tooltip: "Clear results",
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildTextToSignInputBar(theme),
                    const Spacer(),
                  ],

                  _buildBottomNavigation(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captureTimer?.cancel();
    _countdownTimer?.cancel();
    _landmarkPollTimer?.cancel();
    _isCapturingStream = false;
    if (_isStreamActive) _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _textToSignController.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}