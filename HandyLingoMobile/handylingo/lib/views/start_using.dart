import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_v2/tflite_v2.dart'; // AI Model Import
import 'package:webview_flutter/webview_flutter.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:video_player/video_player.dart';
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
  bool _frontCamera = true;
  final TextEditingController _textController = TextEditingController();

  // --- AI TRANSLATION STATE ---
  bool _isModelLoaded = false;
  bool _isRecording = false;
  bool _isProcessing = false; 
  String _videoPath = '';
  String _accumulatedSentence = ""; 

  // Speech to text
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;

  // Camera
  List<CameraDescription> _cameras =[];
  CameraController? _cameraController;
  bool _cameraInitializing = false;

  // WebView Controller
  late final WebViewController _signWebController;
  bool _signWebLoading = true;
  String? _signWebError;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _initCamera();
    _loadModel(); 
    _initializeSignWeb();
  }

  // --- 1. UPDATED AI TRANSLATION LOGIC ---
  Future<void> _loadModel() async {
    try {
      String? result = await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt",
      );
      
      if (result != null && result.toLowerCase().contains("success")) {
        if (mounted) setState(() => _isModelLoaded = true);
      } else {
        if (mounted) setState(() => _accumulatedSentence = "[Error: Model Load Failed - $result]");
      }
    } catch (e) {
      if (mounted) setState(() => _accumulatedSentence = "[Error: Model Exception - $e]");
    }
  }

  Future<void> _processVideo() async {
    if (!_isModelLoaded) {
      setState(() {
        _accumulatedSentence = "[Error: Model not loaded]";
        _isProcessing = false;
      });
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      
      // FIX 2: Use JPEG instead of PNG. TFLite handles JPEG much better.
      // FIX 3: Set a maxWidth to prevent Out-Of-Memory (OOM) native crashes.
      final thumbnailPath = await vt.VideoThumbnail.thumbnailFile(
        video: _videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: vt.ImageFormat.JPEG, 
        maxWidth: 400, // Safe size to prevent memory crashes
        quality: 80,
        timeMs: 500, // 500ms guarantees the frame exists even if video is short
      );
      
      if (thumbnailPath != null) {
        var recognitions = await Tflite.runModelOnImage(
          path: thumbnailPath,
          imageMean: 127.5,
          imageStd: 127.5,
          numResults: 2,
          threshold: 0.1, 
        );
        
        if (recognitions != null && recognitions.isNotEmpty) {
          String rawLabel = recognitions[0]['label'].toString();
          String cleanLabel = rawLabel.replaceAll(RegExp(r'^[0-9]+\s'), '').toUpperCase();
          
          setState(() {
            if (_accumulatedSentence.isEmpty || _accumulatedSentence.startsWith("[")) {
              _accumulatedSentence = cleanLabel;
            } else {
              _accumulatedSentence += " $cleanLabel";
            }
          });
        } else {
          setState(() => _accumulatedSentence = "[No sign recognized]");
        }
        
        await File(thumbnailPath).delete();
      } else {
        setState(() => _accumulatedSentence = "[Error: Failed to extract frame]");
      }
    } catch (e) {
      setState(() => _accumulatedSentence = "[Error running model: $e]");
    } finally {
      // Cleanup video securely
      if (_videoPath.isNotEmpty) {
        try { await File(_videoPath).delete(); } catch (_) {}
      }
      setState(() => _isProcessing = false);
    }
  }

  void _startVideoRecording() async {
    if (_isRecording || _isProcessing) return; 

    try {
      setState(() => _isRecording = true);
      await _cameraController!.startVideoRecording();
      
      Timer(const Duration(seconds: 5), () async {
        if (!_cameraController!.value.isRecordingVideo) return;
        
        XFile videoFile = await _cameraController!.stopVideoRecording();
        _videoPath = videoFile.path;
        
        setState(() {
          _isRecording = false;
          _isProcessing = true;
        });
        
        // FIX 1: Wait 500 milliseconds for the OS to completely release the MP4 file!
        // Without this, video_thumbnail crashes natively trying to read a locked file.
        await Future.delayed(const Duration(milliseconds: 500));
        
        await _processVideo();
      });
    } catch (e) {
      setState(() {
        _accumulatedSentence = "[Camera Error: $e]";
        _isRecording = false;
        _isProcessing = false;
      });
    }
  }

  void _clearSentence() {
    setState(() {
      _accumulatedSentence = "";
    });
  }

  // --- 2. CAMERA & WEBVIEW LOGIC ---
  void _initializeSignWeb() {
    try {
      _signWebController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) => setState(() => _signWebLoading = true),
            onPageFinished: (url) {
              setState(() => _signWebLoading = false);
              _signWebController.runJavaScript(r"""
                (() => {
                  const shouldHide = (el) => {
                    const txt = (el.innerText || '').trim();
                    if (!txt) return;
                    if (/English.*American/i.test(txt)) {
                      el.style.display = 'none';
                    }
                  };
                  document.querySelectorAll('header,nav,div,span').forEach(shouldHide);
                })();
              """);
            },
            onWebResourceError: (err) =>
                setState(() => _signWebError = err.description),
          ),
        )
        ..loadRequest(Uri.parse('https://sign.mt'));
    } catch (e) {
      debugPrint('[SignMT] init error: $e');
    }
  }

  Future<void> _initCamera() async {
    setState(() => _cameraInitializing = true);

    final oldController = _cameraController;
    if (oldController != null) {
      _cameraController = null;
      await oldController.dispose();
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      if (mounted) setState(() => _cameraInitializing = false);
      return;
    }

    CameraDescription desc = _cameras.firstWhere(
      (c) =>
          c.lensDirection ==
          (_frontCamera ? CameraLensDirection.front : CameraLensDirection.back),
      orElse: () => _cameras.first,
    );
    
    _cameraController = CameraController(
      desc,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
    } catch (e) {
      print("Camera initialization error: $e");
    }
    
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
          children:[
            if (_mode == InputMode.signLanguage) _buildTopBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children:[
                    _buildMainMediaArea(),
                    const SizedBox(height: 10),
                    if (_mode == InputMode.signLanguage)
                      _buildSignToTextControls(),
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
        children:[
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
          IconButton(
            icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: () => setState(() => _isMuted = !_isMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMediaArea() {
    return Expanded(
      child: Stack(
        children:[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: _mode == InputMode.signLanguage
                ? (_cameraController?.value.isInitialized ?? false
                      ? Stack(
                          children:[
                            CameraPreview(_cameraController!),
                            if (_isRecording)
                              Positioned(
                                top: 15,
                                right: 15,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "RECORDING...",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            if (_isProcessing)
                              Positioned(
                                top: 15,
                                right: 15,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "TRANSLATING...",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : const Center(child: CircularProgressIndicator()))
                : WebViewWidget(controller: _signWebController),
          ),
          if (_mode == InputMode.signLanguage)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: ActionChip(
                  backgroundColor: Colors.white70,
                  label: Text(
                    _frontCamera ? 'Switch to Rear' : 'Switch to Front',
                  ),
                  onPressed: _switchCamera,
                ),
              ),
            ),
          if (_mode == InputMode.text && _signWebLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildSignToTextControls() {
    return Column(
      children:[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:[
                  const Text(
                    "YOUR SENTENCE:",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearSentence,
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _isProcessing 
                  ? "Translating..." 
                  : _accumulatedSentence.isEmpty
                    ? "Translation will appear here..."
                    : _accumulatedSentence,
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: _isProcessing || _accumulatedSentence.isEmpty 
                      ? FontStyle.italic 
                      : FontStyle.normal,
                  color: _isProcessing 
                      ? Colors.orange 
                      : _accumulatedSentence.startsWith("[")
                          ? Colors.red
                          : _accumulatedSentence.isEmpty
                              ? Colors.grey
                              : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children:[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_isRecording || _isProcessing) ? null : _startVideoRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.videocam),
                label: Text(_isRecording ? "RECORDING..." : "RECORD VIDEO"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
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
        children:[
          TextButton(
            onPressed: () {
              if (_isRecording) {
                setState(() => _isRecording = false);
              }
              setState(
                () => _mode = _mode == InputMode.signLanguage
                    ? InputMode.text
                    : InputMode.signLanguage,
              );
            },
            child: Column(
              children:[
                Text(
                  _mode == InputMode.signLanguage ? 'SL' : '3D',
                  style: theme.textTheme.labelLarge,
                ),
                const Text('Switch'),
              ],
            ),
          ),
          Text(
            'HANDYLINGO',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),

          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountPage()),
            ),
          ),
        ],
      ),
    );
  }
}