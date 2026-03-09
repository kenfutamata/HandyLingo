import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_v2/tflite_v2.dart'; // AI Model Import
import 'package:webview_flutter/webview_flutter.dart';

import 'about_page.dart';
import 'account_page.dart';
import 'sign_mt_translator_page.dart';
import 'package:google_fonts/google_fonts.dart';


enum InputMode { signLanguage, text }

class StartUsingPage extends StatefulWidget {
  const StartUsingPage({super.key});

  @override
  State<StartUsingPage> createState() => _StartUsingPageState();
}

class _StartUsingPageState extends State<StartUsingPage>
    with SingleTickerProviderStateMixin {
  InputMode _mode = InputMode.signLanguage;
  bool _isMuted = false;
  bool _isProcessing = false;
  bool _frontCamera = true;
  final TextEditingController _textController = TextEditingController();

  // --- AI TRANSLATION STATE ---
  bool _isModelLoaded = false;
  bool _isTranslating = false; // Live detection toggle
  String _currentSign = "..."; // Currently detected word
  String _accumulatedSentence = ""; // Sentence built by user

  // Speech to text (preserved)
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;
  bool _isListening = false;

  // Camera
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _cameraInitializing = false;

  // Phrase list & Collection (preserved)
  final List<String> _phrases = ['Hello / Hi', 'Goodbye', 'Please', 'Thank you', 'Sorry', 'You', 'Bad', 'Ask', 'Eat', 'Drink', 'Water', 'Bathroom', 'Understand'];
  String _selectedPhrase = 'Hello / Hi';
  bool _collectMode = false;
  Timer? _captureTimer;
  int _captureCount = 0;

  // WebView (Text to Sign) Controller (Preserved)
  late final WebViewController _signWebController;
  bool _signWebLoading = true;
  String? _signWebError;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _initCamera();
    _loadModel(); // Load AI model on start
    _initializeSignWeb();
  }

  // --- 1. AI TRANSLATION LOGIC ---
  Future<void> _loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt",
      );
      if (mounted) setState(() => _isModelLoaded = true);
    } catch (e) {
      debugPrint("AI Model Load Error: $e");
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (!_isTranslating || !_isModelLoaded || _isProcessing || _collectMode) return;

    _isProcessing = true;
    try {
      var recognitions = await Tflite.runModelOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 127.5, // Fixed normalization for ASK/YOU/BAD
        imageStd: 127.5,
        rotation: 90,
        numResults: 1,
        threshold: 0.4,
      );

      if (recognitions != null && recognitions.isNotEmpty) {
        String label = recognitions[0]['label'].toString().toUpperCase();
        double conf = (recognitions[0]['confidence'] as double) * 100;
        if (mounted) setState(() => _currentSign = "$label (${conf.toStringAsFixed(0)}%)");
      } else {
        if (mounted) setState(() => _currentSign = "...");
      }
    } finally {
      _isProcessing = false;
    }
  }

  void _toggleLiveAI() {
    if (_isTranslating) {
      _cameraController?.stopImageStream();
      setState(() => _currentSign = "...");
    } else {
      _cameraController?.startImageStream(_processCameraImage);
    }
    setState(() => _isTranslating = !_isTranslating);
  }

  void _addWordToSentence() {
    if (_currentSign == "..." || _currentSign.isEmpty) return;
    String word = _currentSign.split(" ")[0];
    setState(() => _accumulatedSentence += "$word ");
  }

  void _clearSentence() {
    setState(() {
      _accumulatedSentence = "";
      _currentSign = "...";
    });
  }

  // --- 2. CAMERA & WEBVIEW LOGIC (PRESERVED) ---
  void _initializeSignWeb() {
    try {
      _signWebController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
            onPageStarted: (url) => setState(() => _signWebLoading = true),
            onPageFinished: (url) => setState(() => _signWebLoading = false),
            onWebResourceError: (err) => setState(() => _signWebError = err.description),
        ))
        ..loadRequest(Uri.parse('https://sign.mt'));
    } catch (e) { debugPrint('[SignMT] init error: $e'); }
  }

  Future<void> _initCamera() async {
    setState(() => _cameraInitializing = true);
    _cameras = await availableCameras();
    CameraDescription desc = _cameras.firstWhere(
      (c) => c.lensDirection == (_frontCamera ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => _cameras.first,
    );
    if (_cameraController != null) await _cameraController!.dispose();
    _cameraController = CameraController(desc, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();
    if (mounted) setState(() => _cameraInitializing = false);
  }

  Future<void> _switchCamera() async {
    setState(() => _frontCamera = !_frontCamera);
    await _initCamera();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _textController.dispose();
    _cameraController?.dispose();
    Tflite.close();
    super.dispose();
  }

  // --- 3. UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8FB),
      body: SafeArea(
        child: Column(
          children: [
            if (_mode == InputMode.signLanguage) _buildTopBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children: [
                    _buildMainMediaArea(),
                    const SizedBox(height: 10),
                    if (_mode == InputMode.signLanguage) _buildSignToTextControls(),
                    _buildBottomNavigation(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()))),
          IconButton(icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up), onPressed: () => setState(() => _isMuted = !_isMuted)),
        ],
      ),
    );
  }

  Widget _buildMainMediaArea() {
    return Expanded(
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: _mode == InputMode.signLanguage 
              ? (_cameraController?.value.isInitialized ?? false 
                  ? Stack(children: [
                      CameraPreview(_cameraController!),
                      Positioned(top: 15, right: 15, child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: Text("AI SEEING: $_currentSign", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )),
                    ])
                  : const Center(child: CircularProgressIndicator()))
              : WebViewWidget(controller: _signWebController),
          ),
          if (_mode == InputMode.signLanguage)
            Positioned(bottom: 12, left: 0, right: 0, child: Center(
              child: ActionChip(
                backgroundColor: Colors.white70,
                label: Text(_frontCamera ? 'Switch to Rear' : 'Switch to Front'),
                onPressed: _switchCamera,
              ),
            )),
          if (_mode == InputMode.text && _signWebLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildSignToTextControls() {
    return Column(
      children: [
        // Sentence Result Area
        Container(
          width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("YOUR SENTENCE:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  GestureDetector(onTap: _clearSentence, child: const Icon(Icons.delete_outline, size: 18, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 4),
              Text(_accumulatedSentence.isEmpty ? "Translation will appear here..." : _accumulatedSentence, 
                   style: TextStyle(fontSize: 18, color: _accumulatedSentence.isEmpty ? Colors.grey : Colors.black87)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Action Buttons
        Row(
          children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: _toggleLiveAI, 
              icon: Icon(_isTranslating ? Icons.pause : Icons.play_arrow),
              label: Text(_isTranslating ? "PAUSE AI" : "START LIVE AI"),
              style: ElevatedButton.styleFrom(backgroundColor: _isTranslating ? Colors.orange : Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
            )),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton.icon(
              onPressed: _addWordToSentence, 
              icon: const Icon(Icons.add), label: const Text("ADD WORD"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton(onPressed: () {
            if (_isTranslating) _toggleLiveAI(); // Stop AI when switching
            setState(() => _mode = _mode == InputMode.signLanguage ? InputMode.text : InputMode.signLanguage);
          }, child: Column(children: [Text(_mode == InputMode.signLanguage ? 'SL' : '3D', style: theme.textTheme.labelLarge), const Text('Switch')])),
           Text(
                  'HANDYLINGO',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),

          IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountPage()))),
        ],
      ),
    );
  }
}