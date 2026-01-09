import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'about_page.dart';
import 'account_page.dart';

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
  bool _isRecording = false;
  bool _frontCamera = true;
  String? _resultText;
  final TextEditingController _textController = TextEditingController();

  // Speech to text
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;
  bool _isListening = false;

  // Camera
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _cameraInitializing = false;

  // simple animation for the 3D placeholder
  late final AnimationController _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    // initialize camera if permission available
    _initCamera();
  }

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    final res = await Permission.camera.request();
    return res.isGranted;
  }

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final res = await Permission.microphone.request();
    return res.isGranted;
  }

  Future<void> _initCamera() async {
    try {
      setState(() => _cameraInitializing = true);
      final ok = await _ensureCameraPermission();
      if (!ok) {
        debugPrint('[Camera] permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission denied')),
          );
        }
        setState(() => _cameraInitializing = false);
        return;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('[Camera] no cameras available');
        setState(() => _cameraInitializing = false);
        return;
      }

      // pick camera based on front/rear flag; if desired direction isn't available,
      // pick a fallback camera and update the _frontCamera flag so the UI matches the
      // actual camera being used.
      CameraDescription desc;
      final desired = _frontCamera
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      try {
        desc = _cameras.firstWhere((c) => c.lensDirection == desired);
      } catch (_) {
        // fallback to the first available camera
        desc = _cameras.first;
        if (desc.lensDirection != desired) {
          // Sync UI flag to the camera we actually selected
          setState(
            () =>
                _frontCamera = desc.lensDirection == CameraLensDirection.front,
          );
        }
      }

      _cameraController?.dispose();
      _cameraController = CameraController(
        desc,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      setState(() {
        _cameraInitializing = false;
      });
    } catch (e) {
      debugPrint('[Camera] init error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Camera init error: $e')));
      }
      setState(() {
        _cameraInitializing = false;
      });
    }
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) => debugPrint('[Speech] status: $status'),
        onError: (err) => debugPrint('[Speech] error: $err'),
      );
      setState(() {});
    } catch (e) {
      debugPrint('[Speech] init failed: $e');
    }
  }

  void _startListening() async {
    // ensure microphone permission first
    final micOk = await _ensureMicPermission();
    if (!micOk) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for speech input.'),
        ),
      );
      return;
    }

    if (!_speechEnabled) {
      await _initSpeech();
    }
    if (_speechEnabled) {
      if (!mounted) return;
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _textController.text = result.recognizedWords;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          });
        },
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 3),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
      }
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _textController.dispose();
    _speech.stop();
    _cameraController?.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == InputMode.signLanguage
          ? InputMode.text
          : InputMode.signLanguage;
      _resultText = null;
    });
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
  }

  Future<void> _switchCamera() async {
    setState(() => _frontCamera = !_frontCamera);
    await _initCamera();
  }

  Future<void> _startProcessing({String? withText}) async {
    setState(() {
      _isProcessing = true;
      _resultText = null;
    });

    // simulate processing time
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
      _resultText = withText ?? 'Translated text result appears here.';
    });
  }

  void _onTapRecord() {
    // short tap -> quick conversion
    setState(() => _isRecording = true);
    _startProcessing();
    // turn off recording indicator quickly
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() => _isRecording = false);
    });
  }

  void _onLongPressStart() {
    setState(() => _isRecording = true);
  }

  void _onLongPressEnd() {
    setState(() => _isRecording = false);
    _startProcessing(withText: 'Spoken text recognized and converted.');
  }

  void _onSubmitText() {
    final t = _textController.text.trim();
    if (t.isEmpty) return;
    FocusScope.of(context).unfocus();
    _startProcessing(withText: t);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF8FB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Row: About (left) + Mute (right)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutPage()),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
                    onPressed: _toggleMute,
                  ),
                ],
              ),
            ),

            // Camera / 3D area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children: [
                    // black rectangle camera placeholder
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Center(
                              child: Builder(
                                builder: (ctx) {
                                  if (_mode == InputMode.signLanguage) {
                                    if (_cameraController != null &&
                                        _cameraController!
                                            .value
                                            .isInitialized) {
                                      final previewSize =
                                          _cameraController!.value.previewSize;
                                      if (previewSize != null) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.cover,
                                            child: SizedBox(
                                              width: previewSize.height,
                                              height: previewSize.width,
                                              child: CameraPreview(
                                                _cameraController!,
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: AspectRatio(
                                          aspectRatio: _cameraController!
                                              .value
                                              .aspectRatio,
                                          child: CameraPreview(
                                            _cameraController!,
                                          ),
                                        ),
                                      );
                                    } else if (_cameraInitializing) {
                                      return const CircularProgressIndicator();
                                    } else {
                                      return Icon(
                                        Icons.videocam,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 84,
                                      );
                                    }
                                  } else {
                                    return ScaleTransition(
                                      scale: Tween(
                                        begin: 0.98,
                                        end: 1.02,
                                      ).animate(_animCtrl),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons
                                                .person, // simple 3D placeholder
                                            size: 140,
                                            color: Colors.black54,
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),

                          // camera switch button at bottom center of the rectangle (only in SL mode)
                          if (_mode == InputMode.signLanguage)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Align(
                                alignment: Alignment.center,
                                child: ElevatedButton.icon(
                                  onPressed: _cameraInitializing
                                      ? null
                                      : _switchCamera,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white70,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  icon: _cameraInitializing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          _frontCamera
                                              ? Icons.camera_front
                                              : Icons.camera_rear,
                                          color: Colors.black87,
                                        ),
                                  label: Text(
                                    _frontCamera ? 'Front' : 'Rear',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Thinking / result box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(
                        _isProcessing
                            ? 'Thinking . . .'
                            : (_resultText ?? 'Tap or Hold to Translate'),
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Bottom controls: mode switch (left), main action (center), account (right)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          // Switch tab (left)
                          Expanded(
                            child: TextButton(
                              onPressed: _toggleMode,
                              child: Column(
                                children: [
                                  Text(
                                    _mode == InputMode.signLanguage
                                        ? 'SL'
                                        : '3D',
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Switch',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Center action
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: _mode == InputMode.signLanguage
                                  ? GestureDetector(
                                      onTap: _onTapRecord,
                                      onLongPress: _onLongPressStart,
                                      onLongPressUp: _onLongPressEnd,
                                      child: Container(
                                        width: 86,
                                        height: 86,
                                        decoration: BoxDecoration(
                                          color: _isRecording
                                              ? Colors.redAccent
                                              : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.black54,
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.fiber_manual_record,
                                            color: _isRecording
                                                ? Colors.white
                                                : Colors.black87,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    )
                                  : // Text mode: show a box or text button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: Colors.black12,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _textController,
                                              decoration: const InputDecoration(
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                border: InputBorder.none,
                                                hintText: 'Type here...',
                                              ),
                                              onSubmitted: (_) =>
                                                  _onSubmitText(),
                                            ),
                                          ),
                                          // Speech-to-text mic button
                                          IconButton(
                                            icon: Icon(
                                              _isListening
                                                  ? Icons.mic
                                                  : Icons.mic_none,
                                              color: _isListening
                                                  ? Colors.red
                                                  : Colors.black54,
                                            ),
                                            onPressed: () {
                                              if (_isListening) {
                                                _stopListening();
                                              } else {
                                                _startListening();
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.send),
                                            onPressed: _onSubmitText,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),

                          // Account button (right)
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AccountPage(),
                                  ),
                                );
                              },
                              child: Column(
                                children: const [
                                  Icon(Icons.person, color: Colors.black87),
                                  SizedBox(height: 4),
                                  Text('Account'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Notes:
// - `CameraPreview` is used when permissions are granted and a camera is available.
//   Runtime permission requests are handled with `permission_handler` and platform
//   entries should be present in AndroidManifest.xml and Info.plist.
// - The 3D animation is simulated with a simple `Icon` and scale animation. Replace with
//   real 3D rendering when the model is available.
