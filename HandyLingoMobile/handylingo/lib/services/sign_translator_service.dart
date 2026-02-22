import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to handle translation between text and sign language
/// Integrates with sign.mt translator
class SignTranslatorService {
  static const String _signMtBaseUrl = 'https://sign.mt/api';
  // For local development, you can use: http://localhost:4200/api

  final http.Client _httpClient;

  SignTranslatorService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// Translates text to sign language
  /// Returns the sign language representation (could be video URL, pose sequence, etc.)
  Future<Map<String, dynamic>> translateTextToSign(
    String text, {
    String sourceLanguage = 'en',
    String signLanguage = 'asl', // ASL, BSL, LSF, etc.
  }) async {
    try {
      final response = await _httpClient
          .post(
            Uri.parse('$_signMtBaseUrl/translate/text-to-sign'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'text': text,
              'sourceLanguage': sourceLanguage,
              'signLanguage': signLanguage,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw TimeoutException('Translation request timed out'),
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Translation failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[SignTranslator] Text to sign error: $e');
      rethrow;
    }
  }

  /// Translates sign language to text
  /// Requires video/image input of sign language
  Future<Map<String, dynamic>> translateSignToText(
    String videoPath, {
    String targetLanguage = 'en',
    String signLanguage = 'asl',
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_signMtBaseUrl/translate/sign-to-text'),
      );

      request.fields['targetLanguage'] = targetLanguage;
      request.fields['signLanguage'] = signLanguage;
      request.files.add(await http.MultipartFile.fromPath('video', videoPath));

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5), // Video processing takes time
        onTimeout: () => throw TimeoutException('Video processing timed out'),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Sign to text failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[SignTranslator] Sign to text error: $e');
      rethrow;
    }
  }

  /// Check service health
  Future<bool> isAvailable() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$_signMtBaseUrl/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[SignTranslator] Service check failed: $e');
      return false;
    }
  }

  /// Get list of supported sign languages
  Future<List<String>> getSupportedSignLanguages() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$_signMtBaseUrl/languages/sign'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<String>.from(data['languages'] ?? []);
      }
      return ['asl']; // fallback
    } catch (e) {
      debugPrint('[SignTranslator] Failed to get languages: $e');
      return ['asl'];
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
