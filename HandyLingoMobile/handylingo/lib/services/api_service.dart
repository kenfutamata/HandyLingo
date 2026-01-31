import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/landmark_model.dart';

class ApiService {
  // If running Python on the same PC as Edge, use localhost
  final String baseUrl = "http://localhost:8001"; 

  Future<List<LandmarkFrame>> translateTextToSign(String englishText) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/translate?query=${Uri.encodeComponent(englishText)}'),
        headers: {
          "Accept": "application/json",
          "Access-Control-Allow-Origin": "*", // Additional hint for web
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // This line is the fix for "Null is not a subtype of List"
        // It ensures frames is NEVER null.
        final List<dynamic> framesJson = data['frames'] ?? [];

        return framesJson.map((f) => LandmarkFrame.fromJson(f)).toList();
      } else {
        throw "Server Error: ${response.statusCode}";
      }
    } catch (e) {
      print("API ERROR: $e");
      throw "Make sure Python is running on port 8001: $e";
    }
  }
}