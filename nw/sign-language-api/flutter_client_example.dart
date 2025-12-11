// Flutter Client for Sign Language API
// Add to your pubspec.yaml:
// dependencies:
//   http: ^1.1.0
//   image_picker: ^0.8.7
//   camera: ^0.10.0

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignLanguageApiClient {
  final String baseUrl;

  SignLanguageApiClient({
    this.baseUrl = 'http://192.168.1.100:8000', // Change to your server
  });

  /// Recognize sign language from an image
  Future<SignRecognitionResult> recognizeSign(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/recognize-sign'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        return SignRecognitionResult.fromJson(json);
      } else {
        throw Exception('Failed to recognize sign: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error recognizing sign: $e');
    }
  }

  /// Convert text to sign language animation
  Future<TextToAnimationResult> textToAnimation(String text) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/api/v1/text-to-animation?text=${Uri.encodeComponent(text)}',
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return TextToAnimationResult.fromJson(json);
      } else {
        throw Exception('Failed to convert text: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error converting text: $e');
    }
  }

  /// Get available sign language classes
  Future<List<String>> getAvailableClasses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/classes'));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final classes = json['classes'] as Map;
        return classes.values.cast<String>().toList();
      } else {
        throw Exception('Failed to fetch classes');
      }
    } catch (e) {
      throw Exception('Error fetching classes: $e');
    }
  }

  /// Check if API is healthy
  Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// Data models
class SignRecognitionResult {
  final String recognizedText;
  final double confidence;
  final int classIndex;
  final Map<String, dynamic> animationData;
  final DateTime timestamp;

  SignRecognitionResult({
    required this.recognizedText,
    required this.confidence,
    required this.classIndex,
    required this.animationData,
    required this.timestamp,
  });

  factory SignRecognitionResult.fromJson(Map<String, dynamic> json) {
    return SignRecognitionResult(
      recognizedText: json['recognized_text'],
      confidence: json['confidence'],
      classIndex: json['class_index'],
      animationData: json['animation_data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class TextToAnimationResult {
  final String inputText;
  final List<Map<String, dynamic>> animationFrames;
  final String audioUrl;

  TextToAnimationResult({
    required this.inputText,
    required this.animationFrames,
    required this.audioUrl,
  });

  factory TextToAnimationResult.fromJson(Map<String, dynamic> json) {
    return TextToAnimationResult(
      inputText: json['input_text'],
      animationFrames: List<Map<String, dynamic>>.from(
        json['animation_frames'],
      ),
      audioUrl: json['audio_url'],
    );
  }
}

// Example usage in your Flutter app:
/*
class SignRecognitionScreen extends StatefulWidget {
  @override
  _SignRecognitionScreenState createState() => _SignRecognitionScreenState();
}

class _SignRecognitionScreenState extends State<SignRecognitionScreen> {
  final client = SignLanguageApiClient();
  String? recognizedText;
  double? confidence;
  bool isLoading = false;
  
  void recognizeFromCamera() async {
    setState(() => isLoading = true);
    
    try {
      final result = await client.recognizeSign(imageFile);
      setState(() {
        recognizedText = result.recognizedText;
        confidence = result.confidence;
      });
      
      // Show animation
      showAnimationDialog(result.animationData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
*/
