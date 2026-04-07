// ============================================================
//  lib/services/sign_language_service.dart
//  Handles: frame capture → pose landmarks → TFLite LSTM → prediction
// ============================================================

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class SignPrediction {
  final String word;
  final double confidence;
  final bool accepted;

  const SignPrediction({
    required this.word,
    required this.confidence,
    required this.accepted,
  });
}

class SignLanguageService {
  // ── Constants (must match config.py) ──────────────────────
  static const int framesPerSample = 30;
  static const int featuresPerFrame = 258; // 126 hand + 132 pose
  static const double threshold = 0.90;

  // ── Internal state ─────────────────────────────────────────
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;
  bool _isProcessing = false;

  final List<List<double>> _frameBuffer = [];

  // ── MediaPipe pose detector ────────────────────────────────
  late final PoseDetector _poseDetector;

  // ── Initialise ─────────────────────────────────────────────
  Future<void> init() async {
    // Pose detector in stream mode for real-time performance
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      ),
    );

    // Load TFLite model
    _interpreter = await Interpreter.fromAsset(
      'assets/sign_language_model.tflite',
      options: InterpreterOptions()..threads = 4,
    );

    // Load label list
    final raw = await rootBundle.loadString('assets/sign_labels.txt');
    _labels = raw.trim().split('\n').map((l) => l.trim()).toList();

    _isLoaded = true;
  }

  bool get isReady => _isLoaded;
  bool get bufferFull => _frameBuffer.length >= framesPerSample;
  double get bufferProgress => _frameBuffer.length / framesPerSample;

  // ── Process one camera frame ───────────────────────────────
  /// Call this for every frame during recording.
  /// ✅ Always adds a frame (zeros if no pose detected) so the
  /// buffer fills up reliably within the 3-second window.
  Future<bool> processFrame(CameraImage image, CameraDescription camera) async {
    if (!_isLoaded || _isProcessing) return false;

    List<double> keypoints;

    try {
      final inputImage = _cameraImageToInputImage(image, camera);
      if (inputImage != null) {
        final poses = await _poseDetector.processImage(inputImage);
        // Use detected pose if available, otherwise zero-pad the frame
        keypoints = poses.isNotEmpty
            ? _extractKeypoints(poses.first)
            : List.filled(featuresPerFrame, 0.0);
      } else {
        keypoints = List.filled(featuresPerFrame, 0.0);
      }
    } catch (_) {
      keypoints = List.filled(featuresPerFrame, 0.0);
    }

    _frameBuffer.add(keypoints);

    if (_frameBuffer.length > framesPerSample) {
      _frameBuffer.removeAt(0);
    }

    return bufferFull;
  }

  // ── Run LSTM prediction ────────────────────────────────────
  Future<SignPrediction?> predict() async {
    if (_interpreter == null || _labels.isEmpty) return null;

    // ✅ FIX: Pad with zero frames if buffer didn't fill completely
    // (happens when recording window ends before 30 frames collected)
    while (_frameBuffer.length < framesPerSample) {
      _frameBuffer.add(List.filled(featuresPerFrame, 0.0));
    }

    _isProcessing = true;

    try {
      // Build input tensor: [1, 30, 258]
      final input = List.generate(
        1,
        (_) => List.generate(framesPerSample, (i) {
          final frame = _frameBuffer[i];
          return List.generate(
            featuresPerFrame,
            (j) => j < frame.length ? frame[j] : 0.0,
          );
        }),
      );

      // Output tensor: [1, num_classes]
      final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

      _interpreter!.run(input, output);

      final probs = output[0];
      final maxIdx = probs.indexOf(probs.reduce(math.max));
      final conf = probs[maxIdx].toDouble();

      return SignPrediction(
        word: _labels[maxIdx],
        confidence: conf,
        accepted: conf >= threshold,
      );
    } finally {
      _isProcessing = false;
    }
  }

  void clearBuffer() => _frameBuffer.clear();

  void dispose() {
    _interpreter?.close();
    _poseDetector.close();
  }

  // ── Keypoint extraction ────────────────────────────────────
  /// Layout mirrors the Python extract_keypoints():
  ///   [0  : 63 ]  left  hand  (21 landmarks × x,y,z)
  ///   [63 :126 ]  right hand  (21 landmarks × x,y,z)
  ///   [126:258 ]  pose        (33 landmarks × x,y,z,visibility)
  List<double> _extractKeypoints(Pose pose) {
    final lh = _handKeypoints(pose, isLeft: true);
    final rh = _handKeypoints(pose, isLeft: false);
    final p = _poseKeypoints(pose);
    return [...lh, ...rh, ...p];
  }

  List<double> _poseKeypoints(Pose pose) {
    // 33 pose landmarks in ML Kit order
    final order = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftEyeInner,
      PoseLandmarkType.leftEye,
      PoseLandmarkType.leftEyeOuter,
      PoseLandmarkType.rightEyeInner,
      PoseLandmarkType.rightEye,
      PoseLandmarkType.rightEyeOuter,
      PoseLandmarkType.leftEar,
      PoseLandmarkType.rightEar,
      PoseLandmarkType.leftMouth,
      PoseLandmarkType.rightMouth,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftPinky,
      PoseLandmarkType.rightPinky,
      PoseLandmarkType.leftIndex,
      PoseLandmarkType.rightIndex,
      PoseLandmarkType.leftThumb,
      PoseLandmarkType.rightThumb,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
      PoseLandmarkType.leftHeel,
      PoseLandmarkType.rightHeel,
      PoseLandmarkType.leftFootIndex,
      PoseLandmarkType.rightFootIndex,
    ];

    final features = <double>[];
    for (final type in order) {
      final lm = pose.landmarks[type];
      if (lm != null) {
        features.addAll([lm.x, lm.y, lm.z, lm.likelihood]);
      } else {
        features.addAll([0.0, 0.0, 0.0, 0.0]);
      }
    }
    return features; // 33 × 4 = 132
  }

  /// Approximate 21 hand landmarks from the 4 hand-related
  /// pose landmarks (wrist, thumb, index, pinky) + elbow for scale.
  /// ✅ IMPROVED: Better geometric hand model
  List<double> _handKeypoints(Pose pose, {required bool isLeft}) {
    final wristT = isLeft
        ? PoseLandmarkType.leftWrist
        : PoseLandmarkType.rightWrist;
    final thumbT = isLeft
        ? PoseLandmarkType.leftThumb
        : PoseLandmarkType.rightThumb;
    final indexT = isLeft
        ? PoseLandmarkType.leftIndex
        : PoseLandmarkType.rightIndex;
    final pinkyT = isLeft
        ? PoseLandmarkType.leftPinky
        : PoseLandmarkType.rightPinky;
    final elbowT = isLeft
        ? PoseLandmarkType.leftElbow
        : PoseLandmarkType.rightElbow;

    final wrist = pose.landmarks[wristT];
    if (wrist == null) return List.filled(63, 0.0);

    final thumb = pose.landmarks[thumbT];
    final index = pose.landmarks[indexT];
    final pinky = pose.landmarks[pinkyT];
    final elbow = pose.landmarks[elbowT];

    // Use elbow distance as hand size reference
    double handScale = 1.0;
    if (elbow != null) {
      final dx = wrist.x - elbow.x;
      final dy = wrist.y - elbow.y;
      final dz = wrist.z - elbow.z;
      handScale = math
          .sqrt(dx * dx + dy * dy + dz * dz)
          .clamp(0.01, double.infinity);
    }

    // MediaPipe Hand layout:
    //  0 = wrist
    //  1-4   = thumb (base → tip)
    //  5-8   = index (base → tip)
    //  9-12  = middle (base → tip)
    //  13-16 = ring (base → tip)
    //  17-20 = pinky (base → tip)
    final lm = List.generate(21, (_) => [0.0, 0.0, 0.0]);
    lm[0] = [wrist.x, wrist.y, wrist.z];

    // Determine hand orientation (left vs right)
    final isRightHand = !isLeft;
    final spread = isRightHand ? -0.15 : 0.15;

    if (thumb != null) {
      _interpolate(lm, 1, 4, wrist, thumb);
    } else {
      // Thumb at ~45° spread from palm center
      final thumbTip = _offset(
        wrist,
        wrist.x + spread * handScale * 1.2,
        wrist.y - 0.2 * handScale,
        wrist.z,
        1.0,
      );
      _interpolate(lm, 1, 4, wrist, thumbTip);
    }

    if (index != null) {
      _interpolate(lm, 5, 8, wrist, index);
    } else {
      // Index at ~15° from center palm
      final indexTip = _offset(
        wrist,
        wrist.x + spread * handScale * 0.3,
        wrist.y - 0.35 * handScale,
        wrist.z,
        1.0,
      );
      _interpolate(lm, 5, 8, wrist, indexTip);
    }

    // Middle finger (always interpolated since no direct landmark)
    final middleTip = _point(
      wrist.x + spread * handScale * 0.0,
      wrist.y - 0.4 * handScale,
      wrist.z,
    );
    _interpolate(lm, 9, 12, wrist, middleTip);

    // Ring finger (between middle and pinky)
    if (pinky != null) {
      final ringTip = _point(
        (middleTip.x + pinky.x) * 0.5,
        (middleTip.y + pinky.y) * 0.5,
        (middleTip.z + pinky.z) * 0.5,
      );
      _interpolate(lm, 13, 16, wrist, ringTip);
    } else {
      final ringTip = _offset(
        wrist,
        wrist.x + spread * handScale * -0.15,
        wrist.y - 0.38 * handScale,
        wrist.z,
        1.0,
      );
      _interpolate(lm, 13, 16, wrist, ringTip);
    }

    if (pinky != null) {
      _interpolate(lm, 17, 20, wrist, pinky);
    } else {
      // Pinky at ~-45° spread
      final pinkyTip = _offset(
        wrist,
        wrist.x + spread * handScale * -0.5,
        wrist.y - 0.3 * handScale,
        wrist.z,
        1.0,
      );
      _interpolate(lm, 17, 20, wrist, pinkyTip);
    }

    return lm.expand((p) => p).toList(); // 21 × 3 = 63
  }

  void _interpolate(
    List<List<double>> lm,
    int start,
    int end,
    PoseLandmark from,
    dynamic to,
  ) {
    final tx = to is PoseLandmark ? to.x : (to as _Point).x;
    final ty = to is PoseLandmark ? to.y : (to as _Point).y;
    final tz = to is PoseLandmark ? to.z : (to as _Point).z;

    for (int i = start; i <= end; i++) {
      final t = (i - start + 1) / (end - start + 1);
      lm[i] = [
        from.x + t * (tx - from.x),
        from.y + t * (ty - from.y),
        from.z + t * (tz - from.z),
      ];
    }
  }

  dynamic _offset(
    PoseLandmark base,
    double tx,
    double ty,
    double tz,
    double scale,
  ) => _Point(
    base.x + (tx - base.x) * scale,
    base.y + (ty - base.y) * scale,
    base.z + (tz - base.z) * scale,
  );

  _Point _point(double x, double y, double z) => _Point(x, y, z);

  // ── Camera image → ML Kit InputImage ──────────────────────
  InputImage? _cameraImageToInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    try {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final rotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
          InputImageRotation.rotation0deg;

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final bytes = _concatenatePlanes(image.planes);
      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (_) {
      return null;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }
}

// Simple point helper
class _Point {
  final double x, y, z;
  const _Point(this.x, this.y, this.z);
}
