import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'package:tflite_v2/tflite_v2.dart'; 
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'about_page.dart';
import 'account_page.dart';

enum AppMode { signToText, textToSign }

class StartUsingPage extends StatefulWidget {
  const StartUsingPage({super.key});

  @override
  State<StartUsingPage> createState() => _StartUsingPageState();
}

class _StartUsingPageState extends State<StartUsingPage> {
  AppMode _currentMode = AppMode.signToText;
  
  // Camera & AI State
  CameraController? _cameraController;
  bool _isModelLoaded = false;
  bool _isTranslating = false;
  bool _isProcessing = false; // Prevents AI from overloading/getting stuck
  bool _frontCamera = true;

  // Translation State
  String _currentSign = "..."; 
  String _accumulatedSentence = ""; 

  // WebView State
  late final WebViewController _webController;
  final TextEditingController _textInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModel();
    _initWebView();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    Tflite.close();
    _textInputController.dispose();
    super.dispose();
  }

  // --- 1. AI LOGIC (FIXED FOR ASK/YOU/BAD) ---
  Future<void> _loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt",
      );
      if (mounted) setState(() => _isModelLoaded = true);
      debugPrint("AI Model Loaded Successfully");
    } catch (e) {
      debugPrint("Model failed to load: $e");
    }
  }

  void _processCameraImage(CameraImage image) async {
    // If not translating, model not ready, or already busy with a frame, skip.
    if (!_isTranslating || !_isModelLoaded || _isProcessing) return;

    _isProcessing = true; // Lock

    try {
      var recognitions = await Tflite.runModelOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        
        // CRITICAL FIX: Normalization values (127.5) help the AI see ASK/YOU/BAD correctly
        imageMean: 127.5, 
        imageStd: 127.5,
        
        rotation: 90, 
        numResults: 1,
        threshold: 0.4, // Lowered to help YOU and BAD get through
        asynch: true,
      );

      if (recognitions != null && recognitions.isNotEmpty) {
        String label = recognitions[0]['label'].toString().toUpperCase();
        double conf = (recognitions[0]['confidence'] as double) * 100;

        if (mounted) {
          setState(() {
            _currentSign = "$label (${conf.toStringAsFixed(0)}%)";
          });
        }
      } else {
        if (mounted) setState(() => _currentSign = "...");
      }
    } catch (e) {
      debugPrint("Inference Error: $e");
    } finally {
      _isProcessing = false; // Unlock for next frame
    }
  }

  // --- 2. SENTENCE BUILDER ---
  void _addCurrentSignToSentence() {
    if (_currentSign == "..." || _currentSign.isEmpty) return;
    
    // Clean "ASK (90%)" into just "ASK"
    String cleanWord = _currentSign.split(" ")[0];

    setState(() {
      _accumulatedSentence += "$cleanWord ";
    });
  }

  void _clearSentence() {
    setState(() {
      _accumulatedSentence = "";
      _currentSign = "...";
    });
  }

  // --- 3. INFRASTRUCTURE ---
  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    final cameras = await availableCameras();
    CameraDescription desc = cameras.firstWhere(
      (c) => c.lensDirection == (_frontCamera ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => cameras.first,
    );

    if (_cameraController != null) await _cameraController!.dispose();

    _cameraController = CameraController(
      desc, 
      ResolutionPreset.medium, 
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  void _toggleTranslation() {
    if (_isTranslating) {
      _cameraController?.stopImageStream();
      setState(() => _currentSign = "...");
    } else {
      _cameraController?.startImageStream(_processCameraImage);
    }
    setState(() => _isTranslating = !_isTranslating);
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://sign.mt'));
  }

  // --- 4. UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("HandyLingo", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFEAF8FB),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage())), 
            icon: const Icon(Icons.person, color: Colors.black54)
          )
        ],
      ),
      backgroundColor: const Color(0xFFEAF8FB),
      body: Column(
        children: [
          _buildModeSwitcher(),
          Expanded(
            child: _currentMode == AppMode.signToText 
              ? _buildSignToTextUI() 
              : _buildTextToSignUI(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        children: [
          _modeButton("Sign → Text", AppMode.signToText),
          _modeButton("Text → Sign", AppMode.textToSign),
        ],
      ),
    );
  }

  Widget _modeButton(String title, AppMode mode) {
    bool isSel = _currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_isTranslating) _toggleTranslation(); // Stop AI when switching modes
          setState(() => _currentMode = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSel ? Colors.blue : Colors.transparent, borderRadius: BorderRadius.circular(30)),
          child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: isSel ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSignToTextUI() {
    return Column(
      children: [
        // Camera Preview Box
        Expanded(
          flex: 4,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue, width: 2)),
            clipBehavior: Clip.antiAlias,
            child: (_cameraController?.value.isInitialized ?? false)
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_cameraController!),
                      Positioned(
                        top: 15, right: 15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                          child: Text("AI SEEING: $_currentSign", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
        
        // Results Area
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("YOUR SENTENCE:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                    IconButton(onPressed: _clearSentence, icon: const Icon(Icons.delete_outline, color: Colors.red)),
                  ],
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.withOpacity(0.1))),
                    child: SingleChildScrollView(
                      child: Text(
                        _accumulatedSentence.isEmpty ? "Signs you add will appear here..." : _accumulatedSentence,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: _accumulatedSentence.isEmpty ? Colors.grey : Colors.black87),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleTranslation,
                        icon: Icon(_isTranslating ? Icons.pause : Icons.play_arrow),
                        label: Text(_isTranslating ? "PAUSE AI" : "START AI"),
                        style: ElevatedButton.styleFrom(backgroundColor: _isTranslating ? Colors.orange : Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _addCurrentSignToSentence,
                        icon: const Icon(Icons.check),
                        label: const Text("ADD WORD"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTextToSignUI() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue.withOpacity(0.2))),
            clipBehavior: Clip.antiAlias,
            child: WebViewWidget(controller: _webController),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: TextField(
            controller: _textInputController,
            decoration: InputDecoration(
              hintText: "Enter text to see signs...",
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.blue),
                onPressed: () {
                   _webController.loadRequest(Uri.parse('https://sign.mt/search?q=${_textInputController.text}'));
                },
              ),
            ),
            onSubmitted: (val) => _webController.loadRequest(Uri.parse('https://sign.mt/search?q=$val')),
          ),
        )
      ],
    );
  }
}