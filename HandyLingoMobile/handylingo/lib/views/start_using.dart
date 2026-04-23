// ============================================================
//  start_using.dart  — FIXED VERSION
//
//  KEY CHANGES vs previous version:
//  1. Frame orientation fix:
//     - Android CameraImage is rotated by `sensorOrientation`
//       degrees CW (dart image pkg v4 uses CW-positive).
//     - NO horizontal flip is applied in Flutter; none on the
//       server either.  Training used back-cam + software-mirror
//       + Python flip = un-mirrored view = right hand on LEFT.
//       A properly rotated front-cam raw image also has the
//       right hand on LEFT → they match.
//
//  2. Real-time hand skeleton:
//     - During the 3-second capture window, the last collected
//       frame is sent to /landmark every 300 ms.
//     - Returned (x,y) landmarks are drawn on the preview using
//       LandmarkPainter (a CustomPainter).
//     - Because the Flutter CameraPreview mirrors the front
//       camera, landmark x-coords are flipped (x = 1 - lm.x)
//       when rendering so the skeleton aligns with what the
//       user sees.
//
//  3. After prediction, the skeleton from the best-detection
//     frame (returned by /predict) is shown as a static overlay.
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
//  MediaPipe hand connections for skeleton drawing
// ─────────────────────────────────────────────────────────────
const _kHandConnections = [
  [0, 1], [1, 2], [2, 3], [3, 4], // thumb
  [0, 5], [5, 6], [6, 7], [7, 8], // index
  [0, 9], [9, 10], [10, 11], [11, 12], // middle
  [0, 13], [13, 14], [14, 15], [15, 16], // ring
  [0, 17], [17, 18], [18, 19], [19, 20], // pinky
  [5, 9], [9, 13], [13, 17], // palm arc
];

// ─────────────────────────────────────────────────────────────
//  Isolate helpers — raw CameraImage bytes → JPEG
//
//  ORIENTATION FIX:
//  Android's CameraImage is delivered in sensor orientation
//  (usually landscape for a portrait-held phone).
//  We rotate it by sensorOrientation degrees CW so the frame
//  is upright before sending to the server.
//
//  dart image package v4 uses CLOCKWISE-positive rotation.
//  Android's sensorOrientation = degrees CW needed to make
//  the sensor image display correctly → we use it directly.
//
//  NO horizontal flip is applied because:
//    Training data = back-cam + software-mirror + cv2.flip
//                  = un-mirrored back-cam
//                  = person's right hand on LEFT of frame.
//    Front-cam raw (upright, no flip) also has right hand
//    on LEFT (same as looking at someone from in front).
//  Adding a flip would BREAK this match.
// ─────────────────────────────────────────────────────────────

// Convert a SINGLE raw frame map → JPEG bytes (or null on error)
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
        // iOS BGRA8888
        final bytes = f['bytes'] as Uint8List;
        imgObj = img.Image.fromBytes(
          width: w,
          height: h,
          bytes: bytes.buffer,
          order: img.ChannelOrder.bgra,
          numChannels: 4,
        );
        // iOS front camera CameraImage is already portrait-oriented.
        // No rotation needed.
      } else {
        // Android YUV420 — Y-plane only (greyscale, ~10× faster)
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

        // ── Rotate to upright ──────────────────────────────
        // sensorOrientation is the CW angle needed to display
        // the sensor image correctly.
        // img.copyRotate uses CW-positive (image pkg v4).
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
//  LandmarkPainter — draws hand skeleton on the camera preview
// ─────────────────────────────────────────────────────────────

class LandmarkPainter extends CustomPainter {
  final List<dynamic> leftHand;
  final List<dynamic> rightHand;
  final bool mirrorX; // true for front camera (CameraPreview mirrors)

  LandmarkPainter({
    required this.leftHand,
    required this.rightHand,
    this.mirrorX = true,
  });

  double _px(double normalizedX, double width) =>
      mirrorX ? (1.0 - normalizedX) * width : normalizedX * width;

  double _py(double normalizedY, double height) => normalizedY * height;

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

    // Connections
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

    // Joints
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
  // ⚠ Update this IP if your PC's address changes.
  // Run `ipconfig` on Windows to find your current IPv4 address.
  static const String _serverUrl = "https://handylingo-handylingo-ai.hf.space/predict";
  static const String _landmarkUrl = "https://handylingo-handylingo-ai.hf.space/landmark";

  // Tracks whether the server was reachable on the last attempt.
  // Shown as a status dot in the UI so the user knows immediately
  // if the network/firewall is the problem.
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
  double _captureSecondsLeft = 3.0;
  Timer? _captureTimer;
  Timer? _countdownTimer;

  // ── Landmark state ───────────────────────────────────────────
  List<dynamic> _leftHandLandmarks = [];
  List<dynamic> _rightHandLandmarks = [];
  Timer? _landmarkPollTimer;
  bool _isPollingSkeleton = false;

  // ── Output ──────────────────────────────────────────────────
  String _accumulatedSentence = "";
  String _currentStatus = "Ready";
  String _textSize = 'Small';

  // ── Sign.MT ─────────────────────────────────────────────────
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
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _loadVoicePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _voiceEnabled = prefs.getBool('voice_enabled') ?? true);
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('voice_enabled') ?? true;
    if (!enabled) return;
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
      ResolutionPreset.low, // 320×240 — fast + MediaPipe-friendly
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
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

  // ── Extract raw frame bytes from CameraImage ─────────────────
  Map<String, dynamic> _extractRawFrame(CameraImage image) {
    final fmt = image.format.group;
    final w = image.width;
    final h = image.height;

    // Sensor orientation — Android needs this to rotate the frame upright
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
      // Android YUV420
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

  // ── 3-second capture ────────────────────────────────────────
  Future<void> _startCaptureSequence() async {
    if (_isCapturing || _isSending || _cameraController == null) return;
    if (!(_cameraController!.value.isInitialized)) return;

    _captureRawFrames.clear();
    _captureFrameTick = 0;
    _capturedCount = 0;

    // Clear previous landmarks at start of new capture
    setState(() {
      _isCapturing = true;
      _currentStatus = "Recording...";
      _captureSecondsLeft = 3.0;
      _leftHandLandmarks = [];
      _rightHandLandmarks = [];
    });

    // Start camera stream
    if (!_isStreamActive) {
      _cameraController!.startImageStream((CameraImage image) {
        if (!_isCapturingStream) return;

        // Keep every 3rd frame ≈ 10fps → ~30 frames in 3 s
        _captureFrameTick++;
        if (_captureFrameTick % 3 != 0) return;

        try {
          _captureRawFrames.add(_extractRawFrame(image));
          if (mounted)
            setState(() => _capturedCount = _captureRawFrames.length);
        } catch (e) {
          debugPrint("Frame copy error: $e");
        }
      });
      _isStreamActive = true;
    }
    _isCapturingStream = true;

    // Countdown UI (100 ms ticks)
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _captureSecondsLeft = (_captureSecondsLeft - 0.1).clamp(0.0, 3.0);
      });
    });

    // Real-time skeleton polling — sends latest frame to /landmark
    _startSkeletonPolling();

    // Stop capture after 3 seconds
    _captureTimer = Timer(const Duration(seconds: 3), () async {
      _isCapturingStream = false;
      _landmarkPollTimer?.cancel();
      _countdownTimer?.cancel();

      if (_isStreamActive) {
        await _cameraController?.stopImageStream();
        _isStreamActive = false;
      }

      await _processAndUpload();
    });
  }

  // ── Real-time skeleton polling ────────────────────────────────
  void _startSkeletonPolling() {
    _landmarkPollTimer?.cancel();
    _landmarkPollTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => _pollLandmark(),
    );
  }

  Future<void> _pollLandmark() async {
    if (_captureRawFrames.isEmpty || _isPollingSkeleton) return;
    _isPollingSkeleton = true;

    try {
      final rawFrame = Map<String, dynamic>.from(_captureRawFrames.last);
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

      final response = await request.send().timeout(
        const Duration(milliseconds: 800),
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
      // Server unreachable — wrong IP, firewall, or server not running
      if (mounted) setState(() => _serverReachable = false);
    } on TimeoutException {
      // Server too slow — skip this poll, try again next tick
    } catch (_) {
      // Any other error — swallow, landmark polling is best-effort
    } finally {
      // Always reset — prevents permanent block after any exception
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
      // Convert all raw frames → JPEG in an isolate (no UI jank)
      final List<Uint8List> jpegFrames = await compute(
        _convertFrames,
        List<Map<String, dynamic>>.from(_captureRawFrames),
      );

      debugPrint(
        "[CAPTURE] ${_captureRawFrames.length} raw → "
        "${jpegFrames.length} JPEGs",
      );

      if (jpegFrames.isEmpty) {
        setState(() {
          _isSending = false;
          _currentStatus = "Conversion failed — retry";
        });
        return;
      }

      // Write to temp files
      final tmpDir = await getTemporaryDirectory();
      final List<File> tmpFiles = [];
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
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(await response.stream.bytesToString());
        final String word = json['prediction_label'] ?? "";
        final double confidence = (json['confidence'] ?? 0.0) * 100;

        // Update skeleton from prediction response (best-detected frame)
        final landmarks = json['landmarks'] as Map<String, dynamic>? ?? {};
        setState(() {
          _leftHandLandmarks = landmarks['left_hand'] as List<dynamic>? ?? [];
          _rightHandLandmarks = landmarks['right_hand'] as List<dynamic>? ?? [];
        });

        if (word.toUpperCase() != "(NONE)" && word.isNotEmpty) {
          setState(() {
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
        debugPrint("Upload error: server unreachable at $_serverUrl");
      }
    } catch (e) {
      if (mounted) setState(() => _currentStatus = "Error — retry");
      debugPrint("Upload error: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
      _captureRawFrames.clear();
    }
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
    setState(() => _isListening = true);
    await _speechToText.listen(
      onResult: (result) {
        setState(() => _recognizedSpeech = result.recognizedWords);
        if (result.finalResult) {
          _stopListening();
          _injectTextIntoWebView(result.recognizedWords);
        }
      },
      localeId: 'en_US',
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
            const sels = ['textarea:not([hidden]):not([disabled])','input[type="text"]:not([hidden]):not([disabled])','[contenteditable="true"]:not([hidden])'];
            for (const s of sels) { const el = document.querySelector(s); if (el) return el; }
            return Array.from(document.querySelectorAll('input,textarea,[contenteditable="true"]')).find(el => {
              const l = ((el.getAttribute('placeholder')||el.getAttribute('aria-label')||'')+'').toLowerCase();
              return ['text','enter','sign','message'].some(k=>l.includes(k));
            });
          }
          function findBtn() {
            return document.querySelector('button[type="submit"],input[type="submit"],button[aria-label*="translate"],button[class*="translate"]') ||
              Array.from(document.querySelectorAll('button,[role="button"]')).find(el=>{
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
            if(btn){['mousedown','mouseup','click'].forEach(t=>btn.dispatchEvent(new MouseEvent(t,{bubbles:true}))); return;}
            el.dispatchEvent(new KeyboardEvent('keydown',{key:'Enter',code:'Enter',keyCode:13,bubbles:true}));
            const form=el.closest('form');
            if(form){if(typeof form.requestSubmit==='function')form.requestSubmit();else form.submit();}
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
          if(window._flutterSignMt)return;
          window._flutterSignMt={};
          function patch(){
            document.querySelectorAll('button').forEach(btn=>{
              if(btn.dataset.flutterMicHooked)return;
              const icon=btn.querySelector('ion-icon[name*="mic"],svg[data-icon*="mic"],i[class*="mic"]');
              if(!icon)return;
              btn.dataset.flutterMicHooked='true';
              btn.addEventListener('click',e=>{e.preventDefault();e.stopPropagation();if(window.SpeechToText)window.SpeechToText.postMessage('start');},true);
            });
          }
          patch();
          new MutationObserver(patch).observe(document.body,{childList:true,subtree:true});
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

  // ── Camera preview with skeleton overlay ─────────────────────
  Widget _buildSignModePreview() {
    if (!(_cameraController?.value.isInitialized ?? false)) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasLandmarks =
        _leftHandLandmarks.isNotEmpty || _rightHandLandmarks.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Camera feed ───────────────────────────────────────
        CameraPreview(_cameraController!),

        // ── Server status dot (top-center) ───────────────────
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
                          ? const Color(0xFF00E676) // green = connected
                          : const Color(0xFFFF1744), // red = no server
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

        // ── Hand skeleton overlay ─────────────────────────────
        // Shown during capture (live) and after prediction (static).
        // mirrorX=true because Flutter's CameraPreview mirrors the
        // front camera — landmark x-coords must be mirrored too.
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

        // ── Recording overlay ─────────────────────────────────
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
                      value: 1.0 - (_captureSecondsLeft / 3.0),
                      backgroundColor: Colors.white24,
                      color: Colors.redAccent,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Skeleton status badge ─────────────────────────────
        if (_isCapturing && hasLandmarks)
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

        // ── Flip camera button ────────────────────────────────
        if (!_isCapturing)
          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                onPressed: _toggleCamera,
              ),
            ),
          ),

        // ── ASL / FSL toggle ──────────────────────────────────
        if (!_isCapturing)
          Positioned(
            top: 10,
            left: 10,
            child: ChoiceChip(
              label: Text(
                _languageType == SignLanguageType.asl ? "ASL" : "FSL",
              ),
              selected: true,
              onSelected: (_) => setState(
                () => _languageType = _languageType == SignLanguageType.asl
                    ? SignLanguageType.fsl
                    : SignLanguageType.asl,
              ),
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
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'speechToTextBtn',
            onPressed: !_speechAvailable && !_isListening
                ? null
                : (_isListening ? _stopListening : _startListening),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
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

  Widget _buildBottomNavigation(ThemeData theme) {
    final surfaceColor = theme.colorScheme.surface;
    return Container(
      color: surfaceColor,
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
            flex: _mode == InputMode.signLanguage ? 3 : 5,
            child: Container(
              margin: _mode == InputMode.signLanguage
                  ? const EdgeInsets.all(12)
                  : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: _mode == InputMode.signLanguage
                    ? Colors.black
                    : surfaceColor,
                borderRadius: _mode == InputMode.signLanguage
                    ? BorderRadius.circular(20)
                    : BorderRadius.zero,
              ),
              clipBehavior: Clip.antiAlias,
              child: _mode == InputMode.signLanguage
                  ? _buildSignModePreview()
                  : _buildSignMtWebView(),
            ),
          ),
          Expanded(
            flex: _mode == InputMode.signLanguage ? 2 : 1,
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
                  if (_mode == InputMode.signLanguage) ...[
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
                        child: Text(
                          _accumulatedSentence.isEmpty
                              ? "Perform your sign..."
                              : _accumulatedSentence,
                          style: TextStyle(
                            fontSize: _sentenceTextSize,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: (_isCapturing || _isSending)
                              ? null
                              : _startCaptureSequence,
                          icon: const Icon(Icons.videocam, size: 20),
                          label: Text(
                            _isCapturing
                                ? "● REC ${_captureSecondsLeft.toStringAsFixed(1)}s"
                                : _isSending
                                ? "ANALYZING..."
                                : "CAPTURE SIGN",
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCapturing
                                ? Colors.red
                                : _isSending
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
                          onPressed: () =>
                              setState(() => _accumulatedSentence = ""),
                          icon: const Icon(Icons.refresh, color: Colors.blue),
                        ),
                      ],
                    ),
                  ] else
                    const Spacer(),
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
    _flutterTts.stop();
    super.dispose();
  }
}
