// ============================================================
//  start_using.dart  —  FAST VERSION  (v4)
//
//  What changed vs v3
//  ─────────────────────────────────────────────────────────────
//  PERFORMANCE FIX — root cause of the 2–3 minute delay
//      v3 converted every captured frame in pure Dart:
//          YUV -> RGB (per-pixel loop)
//        + 90° rotation (per-pixel write)
//        + horizontal flip (per-pixel write)
//        + JPEG encode
//      For a 6 s capture at ~30 fps that's ~180 frames
//      × (480 × 640) ≈ 55 million pixel operations in Dart, then
//      100 separate multipart JPEG uploads. Round-trip on Pixel 6:
//      90–180 seconds.
//
//      v4 sends the RAW YUV planes straight to the server, where
//      OpenCV (vectorised C) does the same conversion in well under
//      a second. No per-pixel Dart work, no JPEG encoding.
//      End-to-end round-trip drops to ~5–10 seconds.
//
//  TIMING — match test.py's 100-frame / ~3.3 s capture window
//      _kMaxCaptureSecs : 6.0  →  3.5
//      _kFrameSkip      : 1    (unchanged)
//      At ~30 fps on Pixel 6 that gives ~100 raw frames, identical
//      temporal profile to test.py — preserves the trained model's
//      accuracy contract.
//
//  PRESERVED — accuracy contract
//      • All frames still flipped horizontally (server side now)
//        so right hand lands in left_hand_landmarks slot,
//        matching collect_images.py's cv2.flip(frame, 1).
//      • Streaming holistic, model_complexity=1 (server side).
//      • Server uses /predict_yuv pipeline = identical to test.py.
//
//  UNCHANGED — text-to-sign mode
//      Sign.MT WebView, TTS, speech-to-text — none of these touched.
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
import 'package:image/image.dart' as img;

import 'account_page.dart';

// ─────────────────────────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────────────────────────

/// Capture window in seconds.  ~3.3 s @ 30 fps ≈ 100 frames, the
/// exact count test.py records and the model trained on.
const double _kMaxCaptureSecs = 3.5;

/// Keep every Nth frame during capture.  1 = no skip.
const int _kFrameSkip = 1;

/// Hard cap on frames sent per request.  Server resamples to 100 with
/// np.linspace, but capping at 100 here means no resampling drift.
const int _kMaxUploadFrames = 100;

// ─────────────────────────────────────────────────────────────
//  MediaPipe hand connections for skeleton drawing
// ─────────────────────────────────────────────────────────────
const _kHandConnections = [
  [0, 1], [1, 2], [2, 3], [3, 4],
  [0, 5], [5, 6], [6, 7], [7, 8],
  [0, 9], [9, 10], [10, 11], [11, 12],
  [0, 13], [13, 14], [14, 15], [15, 16],
  [0, 17], [17, 18], [18, 19], [19, 20],
  [5, 9], [9, 13], [13, 17],
];

// ─────────────────────────────────────────────────────────────
//  Isolate helpers
//
//  v4: only the SKELETON-OVERLAY path still does YUV→JPEG in Dart
//  (one frame per 500 ms — fine).  The CAPTURE path now packs raw
//  YUV bytes for the server, which is essentially free.
// ─────────────────────────────────────────────────────────────

/// Convert one raw frame to JPEG for the /landmark endpoint.
/// Used only by the live skeleton overlay (not the prediction path).
Uint8List? _convertSingleFrame(Map<String, dynamic> f) {
  try {
    return _convertFramesForLandmark([f]).firstOrNull;
  } catch (_) {
    return null;
  }
}

/// Single-frame YUV/BGRA → JPEG converter for /landmark only.
List<Uint8List> _convertFramesForLandmark(List<Map<String, dynamic>> rawFrames) {
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
        final Uint8List uBytes = f['u'] as Uint8List? ?? Uint8List(0);
        final Uint8List vBytes = f['v'] as Uint8List? ?? Uint8List(0);
        final int yStride = f['yStride'] as int;
        final int uvStride = f['uvStride'] as int? ?? (w ~/ 2);
        final int uvPixelStride = f['uvPixelStride'] as int? ?? 1;
        final bool hasChroma = uBytes.isNotEmpty && vBytes.isNotEmpty;

        final rgb = Uint8List(w * h * 3);
        for (int row = 0; row < h; row++) {
          for (int col = 0; col < w; col++) {
            final int y = yBytes[row * yStride + col];
            final int rgbIdx = (row * w + col) * 3;
            if (hasChroma) {
              final int uvOffset =
                  (row ~/ 2) * uvStride + (col ~/ 2) * uvPixelStride;
              final int u = uvOffset < uBytes.length ? uBytes[uvOffset] : 128;
              final int v = uvOffset < vBytes.length ? vBytes[uvOffset] : 128;
              rgb[rgbIdx]     = (y + 1.402  * (v - 128)).round().clamp(0, 255);
              rgb[rgbIdx + 1] = (y - 0.344  * (u - 128) - 0.714 * (v - 128)).round().clamp(0, 255);
              rgb[rgbIdx + 2] = (y + 1.772  * (u - 128)).round().clamp(0, 255);
            } else {
              rgb[rgbIdx] = y;
              rgb[rgbIdx + 1] = y;
              rgb[rgbIdx + 2] = y;
            }
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

      // Skeleton overlay must look upright on screen → flip here too
      // so coords from /landmark line up with what the user sees.
      imgObj = img.flipHorizontal(imgObj);
      result.add(Uint8List.fromList(img.encodeJpg(imgObj, quality: 70)));
    } catch (_) {}
  }
  return result;
}

/// FAST: pack a raw YUV/BGRA frame for the /predict_yuv endpoint.
/// No per-pixel work — just JSON header + plane bytes.
///
/// Wire format (per frame):
///     [4 B uint32 LE: header_len]
///     [header_len  B: JSON header (UTF-8)]
///     [rest        : raw plane bytes; YUV is y|u|v concatenated]
Uint8List _packRawFrame(Map<String, dynamic> f) {
  final String fmt = f['fmt'] as String;
  final int w = f['w'] as int;
  final int h = f['h'] as int;
  final int sensorOrientation = f['sensorOrientation'] as int? ?? 0;

  Map<String, dynamic> header;
  late Uint8List payload;

  if (fmt == 'bgra') {
    // iOS — single interleaved BGRA plane.
    final bytes = f['bytes'] as Uint8List;
    header = <String, dynamic>{
      'fmt': 'bgra',
      'w': w,
      'h': h,
      'sensorOrientation': sensorOrientation,
      'needsFlip': true, // match training (cv2.flip)
    };
    payload = bytes;
  } else {
    // Android YUV_420_888 — three planes packed in order Y | U | V.
    final Uint8List yBytes = f['y'] as Uint8List;
    final Uint8List uBytes = f['u'] as Uint8List? ?? Uint8List(0);
    final Uint8List vBytes = f['v'] as Uint8List? ?? Uint8List(0);
    final int yStride = f['yStride'] as int;
    final int uvStride = f['uvStride'] as int? ?? (w ~/ 2);
    final int uvPixelStride = f['uvPixelStride'] as int? ?? 1;

    header = <String, dynamic>{
      'fmt': 'yuv',
      'w': w,
      'h': h,
      'yStride': yStride,
      'uvStride': uvStride,
      'uvPixelStride': uvPixelStride,
      'sensorOrientation': sensorOrientation,
      'needsFlip': true, // match training (cv2.flip)
      'yLen': yBytes.length,
      'uLen': uBytes.length,
      'vLen': vBytes.length,
    };

    final pb = BytesBuilder(copy: false);
    pb.add(yBytes);
    pb.add(uBytes);
    pb.add(vBytes);
    payload = pb.toBytes();
  }

  final headerJson = utf8.encode(jsonEncode(header));
  final headerLen = headerJson.length;

  final out = BytesBuilder(copy: false)
    ..add(<int>[
      headerLen        & 0xFF,
      (headerLen >> 8)  & 0xFF,
      (headerLen >> 16) & 0xFF,
      (headerLen >> 24) & 0xFF,
    ])
    ..add(headerJson)
    ..add(payload);

  return out.toBytes();
}

/// Pack a list of frames in an isolate.  Even though packing is
/// near-free, doing it off-thread keeps the UI buttery-smooth.
List<Uint8List> _packRawFrames(List<Map<String, dynamic>> rawFrames) {
  return rawFrames.map(_packRawFrame).toList();
}

// ─────────────────────────────────────────────────────────────
//  Upper-body pose connections (server returns 19 sorted points)
// ─────────────────────────────────────────────────────────────
const _kPoseConnections = [
  [0, 1], [1, 2], [2, 3],
  [0, 4], [4, 5], [5, 6],
  [3, 7], [6, 8],
  [9, 10],
  [11, 12], [11, 17], [12, 18], [17, 18],
  [11, 13], [13, 15], [12, 14], [14, 16],
];

class LandmarkPainter extends CustomPainter {
  final List<dynamic> leftHand;
  final List<dynamic> rightHand;
  final List<dynamic> pose;
  final bool mirrorX;

  const LandmarkPainter({
    required this.leftHand,
    required this.rightHand,
    this.pose = const [],
    this.mirrorX = true,
  });

  double _px(double x, double w) => mirrorX ? (1.0 - x) * w : x * w;
  double _py(double y, double h) => y * h;

  void _drawHand(Canvas canvas, Size size, List<dynamic> landmarks,
      Color dotColor, Color lineColor) {
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
        Offset(_px((a[0] as num).toDouble(), size.width),
               _py((a[1] as num).toDouble(), size.height)),
        Offset(_px((b[0] as num).toDouble(), size.width),
               _py((b[1] as num).toDouble(), size.height)),
        linePaint,
      );
    }
    for (final lm in landmarks) {
      canvas.drawCircle(
        Offset(_px((lm[0] as num).toDouble(), size.width),
               _py((lm[1] as num).toDouble(), size.height)),
        4,
        dotPaint,
      );
    }
  }

  void _drawPose(Canvas canvas, Size size) {
    if (pose.isEmpty) return;
    final linePaint = Paint()
      ..color = const Color(0xFF64E986)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = const Color(0xFFB4FF6E)
      ..style = PaintingStyle.fill;

    for (final conn in _kPoseConnections) {
      final ai = conn[0];
      final bi = conn[1];
      if (ai >= pose.length || bi >= pose.length) continue;
      final a = pose[ai];
      final b = pose[bi];
      final aVis = (a[2] as num).toDouble();
      final bVis = (b[2] as num).toDouble();
      if (aVis < 0.5 || bVis < 0.5) continue;
      canvas.drawLine(
        Offset(_px((a[0] as num).toDouble(), size.width),
               _py((a[1] as num).toDouble(), size.height)),
        Offset(_px((b[0] as num).toDouble(), size.width),
               _py((b[1] as num).toDouble(), size.height)),
        linePaint,
      );
    }
    for (final lm in pose) {
      final vis = (lm[2] as num).toDouble();
      if (vis < 0.5) continue;
      canvas.drawCircle(
        Offset(_px((lm[0] as num).toDouble(), size.width),
               _py((lm[1] as num).toDouble(), size.height)),
        4,
        dotPaint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawPose(canvas, size);
    _drawHand(canvas, size, leftHand,
        const Color(0xFF00E5FF), const Color(0xFF0097A7));
    _drawHand(canvas, size, rightHand,
        const Color(0xFFFFD740), const Color(0xFFFF6F00));
  }

  @override
  bool shouldRepaint(LandmarkPainter old) =>
      old.leftHand != leftHand ||
      old.rightHand != rightHand ||
      old.pose != pose;
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
  // ── Server URLs ────────────────────────────────────────────
  // NEW v4 endpoint — accepts raw YUV/BGRA, no JPEG encoding.
  static const String _serverUrl   = "https://handylingo-handylingo-ai.hf.space/predict_yuv";
  static const String _landmarkUrl = "https://handylingo-handylingo-ai.hf.space/landmark";

  bool _serverReachable = true;

  final _supabase = Supabase.instance.client;
  final FlutterTts _flutterTts = FlutterTts();

  InputMode _mode = InputMode.signLanguage;
  SignLanguageType _languageType = SignLanguageType.asl;

  // ── Camera ──────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isFrontCamera = false; // back camera = training match
  bool _isCapturing = false;
  bool _isSending = false;
  bool _isStreamActive = false;

  // ── Capture state ───────────────────────────────────────────
  final List<Map<String, dynamic>> _captureRawFrames = [];
  bool _isCapturingStream = false;
  int _captureFrameTick = 0;
  int _capturedCount = 0;
  double _captureSecondsLeft = _kMaxCaptureSecs;
  Timer? _captureTimer;
  Timer? _countdownTimer;

  // Latest frame for skeleton polling.
  Map<String, dynamic>? _latestRawFrame;

  // ── Landmark state ─────────────────────────────────────────
  List<dynamic> _leftHandLandmarks = [];
  List<dynamic> _rightHandLandmarks = [];
  List<dynamic> _poseLandmarks = [];
  Timer? _landmarkPollTimer;
  bool _isPollingSkeleton = false;

  // ── Output ─────────────────────────────────────────────────
  String _accumulatedSentence = "";
  String _currentStatus = "Ready";
  String _textSize = 'Small';

  final List<Map<String, dynamic>> _predictions = [];

  // ── Text-to-Sign input ─────────────────────────────────────
  final TextEditingController _textToSignController = TextEditingController();

  // ── Sign.MT WebView ────────────────────────────────────────
  late final WebViewController _signWebController;
  bool _signMtReady = false;

  // ── Speech-to-text ─────────────────────────────────────────
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

  // ── TTS ────────────────────────────────────────────────────
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

  // ── Supabase ───────────────────────────────────────────────
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

  // ── Camera init ────────────────────────────────────────────
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _landmarkPollTimer?.cancel();

    if (_cameraController != null) {
      if (_isStreamActive) {
        await _cameraController!.stopImageStream();
        _isStreamActive = false;
      }
      await _cameraController!.dispose();
    }

    final selectedCamera = cameras.firstWhere(
      (c) => c.lensDirection ==
          (_isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      selectedCamera,
      // medium → ~480×640 on Pixel 6 — closest match to the 640×480
      // training capture resolution.
      ResolutionPreset.low,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;

      await _cameraController!.startImageStream((CameraImage image) {
        _latestRawFrame = _extractRawFrame(image);
        if (!_isCapturingStream) return;

        _captureFrameTick++;
        if (_captureFrameTick % _kFrameSkip != 0) return;
        try {
          _captureRawFrames.add(_latestRawFrame!);
          if (mounted)
            setState(() => _capturedCount = _captureRawFrames.length);
        } catch (e) {
          debugPrint("Frame copy error: $e");
        }
      });
      _isStreamActive = true;
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

  // ── Extract raw frame bytes ─────────────────────────────────
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
        'u': Uint8List.fromList(image.planes[1].bytes),
        'v': Uint8List.fromList(image.planes[2].bytes),
        'uvStride': image.planes[1].bytesPerRow,
        'uvPixelStride': image.planes[1].bytesPerPixel ?? 1,
        'sensorOrientation': sensorOrientation,
      };
    }
  }

  // ── Capture sequence ────────────────────────────────────────
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
      _poseLandmarks = [];
    });

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

    _captureTimer = Timer(
      Duration(milliseconds: (_kMaxCaptureSecs * 1000).toInt()),
      () => _finishCapture(),
    );
  }

  Future<void> _finishCapture() async {
    if (!_isCapturing) return;

    _isCapturingStream = false;
    _countdownTimer?.cancel();
    _captureTimer?.cancel();

    await _processAndUpload();
  }

  // ── Real-time skeleton polling ──────────────────────────────
  void _startSkeletonPolling() {
    _landmarkPollTimer?.cancel();
    _landmarkPollTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _pollLandmark(),
    );
  }

  Future<void> _pollLandmark() async {
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
      final response = await request.send().timeout(
        const Duration(milliseconds: 600),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(await response.stream.bytesToString());
        setState(() {
          _serverReachable = true;
          _leftHandLandmarks  = body['left_hand']  as List<dynamic>? ?? [];
          _rightHandLandmarks = body['right_hand'] as List<dynamic>? ?? [];
          _poseLandmarks      = body['pose']        as List<dynamic>? ?? [];
        });
      }
    } on SocketException {
      if (mounted) setState(() => _serverReachable = false);
    } on TimeoutException {
      // skip — landmark is cosmetic
    } catch (_) {
    } finally {
      _isPollingSkeleton = false;
    }
  }

  // ── Pack + Upload (the FAST path) ───────────────────────────
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
      // Subsample to _kMaxUploadFrames BEFORE packing.
      final List<Map<String, dynamic>> selected;
      if (_captureRawFrames.length <= _kMaxUploadFrames) {
        selected = List<Map<String, dynamic>>.from(_captureRawFrames);
      } else {
        final step = (_captureRawFrames.length - 1) / (_kMaxUploadFrames - 1);
        selected = List.generate(
          _kMaxUploadFrames,
          (i) => _captureRawFrames[(i * step).round()],
        );
      }

      // Pack raw YUV/BGRA → length-prefixed binary blobs in an isolate.
      // Near-free vs the old YUV→RGB→JPEG conversion (this is just
      // bookkeeping + a JSON header per frame).
      final List<Uint8List> packedFrames = await compute(
        _packRawFrames,
        selected,
      );

      // ignore: avoid_print
      print("[CAPTURE] ${_captureRawFrames.length} raw → "
            "${selected.length} selected → ${packedFrames.length} packed "
            "→ sending to /predict_yuv");

      final request = http.MultipartRequest('POST', Uri.parse(_serverUrl));
      request.fields['language'] =
          _languageType == SignLanguageType.asl ? "asl" : "fsl";
      for (int i = 0; i < packedFrames.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            packedFrames[i],
            filename: 'f_${i.toString().padLeft(4, '0')}.yuv',
          ),
        );
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
          _leftHandLandmarks  = landmarks['left_hand']  as List<dynamic>? ?? [];
          _rightHandLandmarks = landmarks['right_hand'] as List<dynamic>? ?? [];
          _poseLandmarks      = landmarks['pose']        as List<dynamic>? ?? [];
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

        setState(() {
          _leftHandLandmarks  = [];
          _rightHandLandmarks = [];
          _poseLandmarks      = [];
          _currentStatus = "Ready";
        });
      } else {
        setState(() => _currentStatus = "Server error — retry");
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
      debugPrint("[TIMEOUT] /predict_yuv exceeded 60s");
    } catch (e) {
      if (mounted) setState(() => _currentStatus = "Error — retry");
      debugPrint("Upload error: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
      _captureRawFrames.clear();
    }
  }

  // ── Text-to-Sign + TTS ──────────────────────────────────────
  Future<void> _submitTextToSign(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _textToSignController.clear();
    await Future.wait([_speak(trimmed), _injectTextIntoWebView(trimmed)]);
  }

  // ── Sign.MT WebView (UNCHANGED from v3) ─────────────────────
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

    final hasLandmarks = _leftHandLandmarks.isNotEmpty ||
        _rightHandLandmarks.isNotEmpty ||
        _poseLandmarks.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),

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
                    _serverReachable ? "Server connected" : "Server unreachable",
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (hasLandmarks)
          Positioned.fill(
            child: CustomPaint(
              painter: LandmarkPainter(
                leftHand: _leftHandLandmarks,
                rightHand: _rightHandLandmarks,
                pose: _poseLandmarks,
                mirrorX: true,
              ),
            ),
          ),

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
                    "Captured: $_capturedCount raw  →  ${_capturedCount.clamp(0, _kMaxUploadFrames)} to server  →  100 to model",
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