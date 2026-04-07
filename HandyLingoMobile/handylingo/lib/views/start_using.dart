import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'account_page.dart';

enum InputMode { signLanguage, text }

enum SignLanguageType { asl, fsl } // NEW: Language context

class StartUsingPage extends StatefulWidget {
  const StartUsingPage({super.key});
  @override
  State<StartUsingPage> createState() => _StartUsingPageState();
}

class _StartUsingPageState extends State<StartUsingPage>
    with WidgetsBindingObserver {
  final String _serverUrl = "http://192.168.254.156:8000/predict";

  InputMode _mode = InputMode.signLanguage;
  SignLanguageType _languageType = SignLanguageType.asl; // Default to ASL

  CameraController? _cameraController;
  bool _isFrontCamera = true;
  bool _isCapturing = false;
  bool _isSending = false;
  int _capturedCount = 0;
  final int _targetFrames = 10;

  String _accumulatedSentence = "";
  String _currentStatus = "Ready";
  String _textSize = 'Small';
  late final WebViewController _signWebController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSignWeb();
    _loadTextSizePreference();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    if (_cameraController != null) await _cameraController!.dispose();

    final selectedCamera = cameras.firstWhere(
      (c) =>
          c.lensDirection ==
          (_isFrontCamera
              ? CameraLensDirection.front
              : CameraLensDirection.back),
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.low,
      enableAudio: false,
    );
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  void _toggleCamera() {
    if (_isCapturing || _isSending) return;
    setState(() => _isFrontCamera = !_isFrontCamera);
    _initCamera();
  }

  Future<void> _startCaptureSequence() async {
    if (_isCapturing || _cameraController == null) return;
    setState(() {
      _isCapturing = true;
      _capturedCount = 0;
      _currentStatus = "Capturing...";
    });
    List<XFile> frames = [];
    try {
      for (int i = 0; i < _targetFrames; i++) {
        if (!mounted) return;
        final XFile file = await _cameraController!.takePicture();
        frames.add(file);
        setState(() => _capturedCount = i + 1);
        await Future.delayed(const Duration(milliseconds: 30));
      }
      await _uploadFrames(frames);
    } catch (e) {
      setState(() => _currentStatus = "Error");
    }
  }

  Future<void> _uploadFrames(List<XFile> frames) async {
    setState(() {
      _isCapturing = false;
      _isSending = true;
      _currentStatus = "Analyzing...";
    });
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_serverUrl));

      // NEW: Send the selected language to Python
      request.fields['language'] = _languageType == SignLanguageType.asl
          ? "asl"
          : "fsl";

      for (var frame in frames) {
        request.files.add(
          await http.MultipartFile.fromPath('files', frame.path),
        );
      }

      var response = await request.send().timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        setState(() {
          String word = json['prediction_label'] ?? "";
          if (word != "(NONE)" && word != "") {
            _accumulatedSentence +=
                (_accumulatedSentence.isEmpty ? "" : " ") + word;
          }
          _currentStatus = "Ready";
        });
      }
    } catch (e) {
      setState(() => _currentStatus = "Retry...");
    } finally {
      setState(() => _isSending = false);
      for (var f in frames) {
        try {
          File(f.path).delete();
        } catch (_) {}
      }
    }
  }

  void _initializeSignWeb() {
    _signWebController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://sign.mt'));
  }

  Future<void> _loadTextSizePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('text_size') ?? 'Small';
    if (!mounted) return;
    setState(() => _textSize = value);
  }

  double get _sentenceTextSize {
    switch (_textSize) {
      case 'Large':
        return 24;
      case 'Medium':
        return 20;
      default:
        return 16;
    }
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () => setState(
              () => _mode = _mode == InputMode.signLanguage
                  ? InputMode.text
                  : InputMode.signLanguage,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _mode == InputMode.signLanguage ? '3D' : 'SL',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
                const Text(
                  'Switch',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            'HANDYLINGO',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountPage()),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 22, color: Colors.blue),
                const SizedBox(height: 4),
                Text(
                  'Account',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
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
        title: Text(
          "HandyLingo",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            flex: _mode == InputMode.signLanguage ? 3 : 5,
            child: Container(
              margin: _mode == InputMode.signLanguage
                  ? const EdgeInsets.all(12)
                  : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: _mode == InputMode.signLanguage
                    ? BorderRadius.circular(20)
                    : BorderRadius.zero,
              ),
              clipBehavior: Clip.antiAlias,
              child: _mode == InputMode.signLanguage
                  ? (_cameraController?.value.isInitialized ?? false
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              CameraPreview(_cameraController!),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black45,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.flip_camera_ios,
                                      color: Colors.white,
                                    ),
                                    onPressed: _toggleCamera,
                                  ),
                                ),
                              ),

                              // NEW: LANGUAGE TOGGLE CHIP (ASL vs FSL)
                              Positioned(
                                top: 10,
                                left: 10,
                                child: ChoiceChip(
                                  label: Text(
                                    _languageType == SignLanguageType.asl
                                        ? "ASL"
                                        : "FSL",
                                  ),
                                  selected: true,
                                  onSelected: (val) => setState(
                                    () => _languageType =
                                        _languageType == SignLanguageType.asl
                                        ? SignLanguageType.fsl
                                        : SignLanguageType.asl,
                                  ),
                                ),
                              ),

                              if (_isCapturing)
                                Center(
                                  child: Text(
                                    "$_capturedCount/10",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : const Center(child: CircularProgressIndicator()))
                  : WebViewWidget(controller: _signWebController),
            ),
          ),
          Expanded(
            flex: _mode == InputMode.signLanguage ? 2 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_mode == InputMode.signLanguage) ...[
                    const SizedBox(height: 10),
                    Text(
                      "MODE: ${_languageType.name.toUpperCase()} - $_currentStatus",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 10,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _accumulatedSentence.isEmpty
                              ? "Perform your sign..."
                              : _accumulatedSentence,
                          style: TextStyle(
                            fontSize: _sentenceTextSize,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: (_isCapturing || _isSending)
                              ? null
                              : _startCaptureSequence,
                          icon: const Icon(Icons.videocam, size: 20),
                          label: Text(
                            _isCapturing ? "RECORDING" : "CAPTURE SIGN",
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCapturing
                                ? Colors.red
                                : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _accumulatedSentence = ""),
                          icon: const Icon(Icons.refresh, color: Colors.blue),
                        ),
                      ],
                    ),
                  ] else
                    const Spacer(),
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
