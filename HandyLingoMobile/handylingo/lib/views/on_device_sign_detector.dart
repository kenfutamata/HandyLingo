// on_device_sign_detector.dart
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';

class OnDeviceSignDetector {
  late PoseDetector _poseDetector;
  bool isInitialized = false;

  late Interpreter _interpreter;
  List<String> _labels = [];

  static const int _sequenceLength = 30;
  static const int _featureSize = 258;

 Future<void> initialize() async {
  try {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );

    // FIX: Ensure 'assets/' prefix is present if that's how it is in pubspec.yaml
    _interpreter = await Interpreter.fromAsset('sign_language_model.tflite');
    
    // Load labels
    String labelsData = await rootBundle.loadString('assets/labels.txt');
    _labels = labelsData
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    isInitialized = true;
  } catch (e) {
    debugPrint("Error during OnDeviceSignDetector init: $e");
    isInitialized = false;
  }
}
  // ... [keep detectPose and extractKeypoints as you had it] ...

  Future<Map<String, dynamic>> predict(List<List<double>> sequence) async {
    try {
      if (!isInitialized) {
        print('[CLIENT] Interpreter not initialized. Initializing...');
        await initialize();
      }

      // Flatten input sequence (30x258 → Float32List length 7740)
      final inputBuffer = Float32List(_sequenceLength * _featureSize);
      for (int i = 0; i < _sequenceLength; i++) {
        for (int j = 0; j < _featureSize; j++) {
          inputBuffer[i * _featureSize + j] = sequence[i][j].toDouble();
        }
      }

      // Prepare input tensor shape [1, 30, 258]
      var input = [inputBuffer.buffer.asFloat32List()];
      var output = List.filled(
        _labels.length,
        0.0,
      ).reshape([1, _labels.length]);

      // Run inference (input tensor shape must match model input signature)
      _interpreter.run(input, output);

      // Output is [1, numClasses]
      List<double> outputProbabilities = List<double>.from(output[0]);

      // Find max confidence and index (predicted word)
      double maxProb = outputProbabilities.reduce((a, b) => a > b ? a : b);
      int maxIndex = outputProbabilities.indexOf(maxProb);
      String predictedWord = _labels[maxIndex];

      print('[CLIENT] ▶ $predictedWord (conf: ${maxProb.toStringAsFixed(2)})');

      // Return map similar to server response format
      Map<String, double> allProbs = {};
      for (int i = 0; i < _labels.length; i++) {
        allProbs[_labels[i]] = outputProbabilities[i];
      }

      return {
        'word': predictedWord,
        'confidence': maxProb,
        'all_probs': allProbs,
        'status': 'success',
      };
    } catch (e) {
      print('[CLIENT] Error running inference: $e');
      return {'word': 'Error', 'confidence': 0.0};
    }
  }

  void dispose() {
    _poseDetector.close();
    _interpreter.close();
  }
}
