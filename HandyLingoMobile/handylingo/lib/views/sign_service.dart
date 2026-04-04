// sign_service.dart
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

class SignLanguageService {
  bool _isCapturing = false;
  List<Uint8List> _frameBuffer = [];
  final String _serverUrl = "http://192.168.17.138:8000/predict";

  Future<void> startCapture(CameraController controller, Function(String) onResult) async {
    if (_isCapturing) return;
    _isCapturing = true;
    _frameBuffer.clear();

    // 1. Start Camera Stream
    await controller.startImageStream((CameraImage image) async {
      if (_frameBuffer.length < 30) {
        // Convert YUV to JPEG bytes (simplified logic)
        Uint8List jpeg = await _convertImageToJpeg(image); 
        _frameBuffer.add(jpeg);
      } else {
        // 2. We have 30 images, stop and send to Python
        await controller.stopImageStream();
        _isCapturing = false;
        String result = await _uploadToPython(_frameBuffer);
        onResult(result);
      }
    });
  }

  Future<String> _uploadToPython(List<Uint8List> images) async {
    var request = http.MultipartRequest('POST', Uri.parse(_serverUrl));
    
    for (int i = 0; i < images.length; i++) {
      request.files.add(http.MultipartFile.fromBytes(
        'files', 
        images[i], 
        filename: 'frame_$i.jpg'
      ));
    }

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    // Parse JSON and return word
    return responseData; 
  }
}