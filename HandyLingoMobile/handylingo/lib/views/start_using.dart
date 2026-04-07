import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_page.dart'; 

enum InputMode { signLanguage, text }
enum SignLanguageType { asl, fsl }

class StartUsingPage extends StatefulWidget {
  const StartUsingPage({super.key});
  @override
  State<StartUsingPage> createState() => _StartUsingPageState();
}

class _StartUsingPageState extends State<StartUsingPage> with WidgetsBindingObserver {
  // URLs
  final String _predictUrl = "http://192.168.1.6:8001/predict"; // Python AI
  final String _laravelUrl = "https://handylingo.vercel.app/save-log"; // Laravel Backend

  // We still use Supabase for Auth (to get the userId)
  final _supabase = Supabase.instance.client;

  InputMode _mode = InputMode.signLanguage;
  SignLanguageType _languageType = SignLanguageType.asl;
  
  CameraController? _cameraController;
  bool _isFrontCamera = true;
  bool _isCapturing = false;
  bool _isSending = false;
  int _capturedCount = 0;
  final int _targetFrames = 10; 

  String _accumulatedSentence = "";
  String _currentStatus = "Ready";
  late final WebViewController _signWebController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSignWeb();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    if (_cameraController != null) await _cameraController!.dispose();

    final selectedCamera = cameras.firstWhere(
      (c) => c.lensDirection == (_isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(selectedCamera, ResolutionPreset.low, enableAudio: false);
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) { debugPrint("Camera Error: $e"); }
  }

  void _toggleCamera() {
    if (_isCapturing || _isSending) return;
    setState(() => _isFrontCamera = !_isFrontCamera);
    _initCamera();
  }

  Future<void> _startCaptureSequence() async {
    if (_isCapturing || _cameraController == null) return;
    setState(() { _isCapturing = true; _capturedCount = 0; _currentStatus = "Capturing..."; });
    
    List<XFile> frames = [];
    try {
      for (int i = 0; i < _targetFrames; i++) {
        if (!mounted) return;
        final XFile file = await _cameraController!.takePicture();
        frames.add(file);
        setState(() => _capturedCount = i + 1);
        await Future.delayed(const Duration(milliseconds: 10)); 
      }
      _uploadFrames(frames); 
    } catch (e) { 
      setState(() { _isCapturing = false; _currentStatus = "Error"; });
    }
  }

  Future<void> _uploadFrames(List<XFile> frames) async {
    setState(() { _isCapturing = false; _isSending = true; _currentStatus = "Analyzing..."; });
    try {
      // 1. Send to Python AI
      var request = http.MultipartRequest('POST', Uri.parse(_predictUrl));
      request.fields['language'] = _languageType == SignLanguageType.asl ? "asl" : "fsl";

      for (var frame in frames) {
        request.files.add(await http.MultipartFile.fromPath('files', frame.path));
      }

      var response = await request.send().timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        
        String word = json['prediction_label'] ?? "";
        double confidence = (json['confidence'] ?? 0.0) * 100;

        if (word.toUpperCase() != "(NONE)" && word.isNotEmpty) {
          setState(() {
            _accumulatedSentence += (_accumulatedSentence.isEmpty ? "" : " ") + word;
            _currentStatus = "Detected: $word";
          });
          
          // 2. Send to Laravel Backend (Asynchronously)
          _saveLogToLaravel(word, confidence);
        } else {
          setState(() => _currentStatus = "No sign detected");
        }
      }
    } catch (e) { 
      setState(() => _currentStatus = "Retry..."); 
    } finally {
      setState(() => _isSending = false);
      for (var f in frames) { try { File(f.path).delete(); } catch (_) {} }
    }
  }

  // --- NEW: CALL LARAVEL INSTEAD OF SUPABASE DIRECTLY ---
 Future<void> _saveLogToLaravel(String word, double accuracy) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) {
    debugPrint("Laravel Log: No User ID found");
    return;
  }

  try {
    final response = await http.post(
      Uri.parse(_laravelUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json', // Tells Laravel to talk in JSON
      },
      body: jsonEncode({
        'user_id': userId,
        'translated_output': word,
        'accuracy': accuracy,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      debugPrint("Laravel Vercel: Log Saved Successfully");
    } else {
      // This will now print the actual Laravel error message
      debugPrint("Laravel Vercel Error (${response.statusCode}): ${response.body}");
    }
  } catch (e) {
    debugPrint("Failed to connect to Vercel: $e");
  }
}

  void _initializeSignWeb() {
    _signWebController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://sign.mt'));
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton(
            onPressed: () => setState(() => _mode = _mode == InputMode.signLanguage ? InputMode.text : InputMode.signLanguage),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(_mode == InputMode.signLanguage ? Icons.view_in_ar : Icons.camera_alt, color: Colors.blue),
              Text(_mode == InputMode.signLanguage ? '3D View' : 'Sign Cam', style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ]),
          ),
          Text('HANDYLINGO', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
          IconButton(
            icon: const Icon(Icons.person, size: 24), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage()))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8FB),
      appBar: AppBar(
        title: Text("HandyLingo", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)), 
        centerTitle: true, elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            flex: _mode == InputMode.signLanguage ? 3 : 5, 
            child: Container(
              margin: _mode == InputMode.signLanguage ? const EdgeInsets.all(12) : EdgeInsets.zero, 
              decoration: BoxDecoration(
                color: Colors.black, 
                borderRadius: _mode == InputMode.signLanguage ? BorderRadius.circular(20) : BorderRadius.zero
              ),
              clipBehavior: Clip.antiAlias,
              child: _mode == InputMode.signLanguage
                  ? (_cameraController?.value.isInitialized ?? false 
                      ? Stack(fit: StackFit.expand, children: [
                          CameraPreview(_cameraController!),
                          Positioned(top: 10, right: 10, child: CircleAvatar(backgroundColor: Colors.black45, child: IconButton(icon: const Icon(Icons.flip_camera_ios, color: Colors.white), onPressed: _toggleCamera))),
                          Positioned(
                            top: 10, left: 10,
                            child: ChoiceChip(
                              label: Text(_languageType == SignLanguageType.asl ? "ASL Mode" : "FSL Mode"),
                              selected: true,
                              onSelected: (val) => setState(() => _languageType = _languageType == SignLanguageType.asl ? SignLanguageType.fsl : SignLanguageType.asl),
                            ),
                          ),
                          if (_isCapturing) Center(child: Text("$_capturedCount/$_targetFrames", style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold))),
                        ])
                      : const Center(child: CircularProgressIndicator()))
                  : WebViewWidget(controller: _signWebController),
            ),
          ),
          Expanded(
            flex: _mode == InputMode.signLanguage ? 2 : 1, 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_mode == InputMode.signLanguage) ...[
                    const SizedBox(height: 15),
                    Text("STATUS: $_currentStatus", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 11, letterSpacing: 1.1)),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _accumulatedSentence.isEmpty ? "Ready to translate..." : _accumulatedSentence, 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), 
                          textAlign: TextAlign.center
                        )
                      )
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      ElevatedButton.icon(
                        onPressed: (_isCapturing || _isSending) ? null : _startCaptureSequence,
                        icon: Icon(_isCapturing ? Icons.stop : Icons.videocam, size: 20),
                        label: Text(_isCapturing ? "RECORDING" : "CAPTURE SIGN", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCapturing ? Colors.red : Colors.green, 
                          foregroundColor: Colors.white, 
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                      ),
                      IconButton(onPressed: () => setState(() => _accumulatedSentence = ""), icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 28)),
                    ]),
                    const SizedBox(height: 10),
                  ] else const Spacer(),
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
    _cameraController?.dispose();
    super.dispose();
  }
}