import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'about_page.dart';
import 'account_page.dart';
import 'sign_mt_translator_page.dart';
import '../config/sign_mt_config.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  // 2026-02-22: SAMPLE CAPTURE - variables for dataset collection
  // List of user-provided phrases. (2026-02-22)
  final List<String> _phrases = [
    'Hello / Hi',
    'Goodbye',
    'Please',
    'Thank you',
    'You\'re welcome',
    'Sorry',
    'Excuse me',
    'Nice to meet you',
    'How are you?',
    'Good / Bad',
    'I / Me',
    'You',
    'He / Him',
    'She / Her',
    'We / Us',
    'They / Them',
    'This',
    'That',
    'Mother',
    'Father',
    'Mom / Dad',
    'Sister',
    'Brother',
    'Grandma / Grandpa',
    'Baby',
    'Child',
    'Family',
    'Yes',
    'No',
    'Maybe',
    'Help',
    'Stop',
    'Go',
    'Come',
    'Wait',
    'Finish',
    'Start',
    'Work',
    'School',
    'Home',
    'Today',
    'Tomorrow',
    'Yesterday',
    'Now',
    'Later',
    'Morning',
    'Afternoon',
    'Night',
    'Week',
    'Month',
    'Year',
    'Happy',
    'Sad',
    'Angry',
    'Tired',
    'Sick',
    'Hungry',
    'Thirsty',
    'Love',
    'Like',
    'Don\'t like',
    'Who',
    'What',
    'Where',
    'When',
    'Why',
    'How',
    'Which',
    'Eat',
    'Drink',
    'Water',
    'Food',
    'Coffee',
    'Bathroom',
    'Sleep',
    'Understand',
    'Don\'t understand',
    'Again',
    'Slow',
    'Fast',
    'Name',
    'Spell',
    'Sign (as in sign language)',
  ];

  // selected phrase for collecting samples (2026-02-22)
  String _selectedPhrase = 'Hello / Hi';

  // enable/disable sample collection mode (2026-02-22)
  bool _collectMode = false;

  // timer for periodic frame captures (2026-02-22)
  Timer? _captureTimer;
  int _captureCount = 0;

  // simple animation for the 3D placeholder
  late final AnimationController _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  // Sign.MT webview controller (embedded in 3D/Text mode)
  late final WebViewController _signWebController;
  bool _signWebLoading = true;
  String? _signWebError;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    // initialize camera if permission available
    _initCamera();
    // initialize embedded Sign.MT webview
    _initializeSignWeb();
  }

  void _initializeSignWeb() {
    try {
      _signWebController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              setState(() => _signWebLoading = true);
              debugPrint('[SignMT embedded] started: $url');
            },
            onPageFinished: (url) {
              setState(() {
                _signWebLoading = false;
                _signWebError = null;
              });
              debugPrint('[SignMT embedded] finished: $url');
              // Inject current text into translator
              if (_textController.text.isNotEmpty) {
                _injectTextToSignMt(_textController.text);
              }
            },
            onWebResourceError: (err) {
              setState(() {
                _signWebLoading = false;
                _signWebError = err.description;
              });
              debugPrint('[SignMT embedded] web error: ${err.description}');
            },
            onHttpError: (err) {
              debugPrint(
                '[SignMT embedded] http error: ${err.response?.statusCode}',
              );
            },
          ),
        )
        ..loadRequest(Uri.parse('https://sign.mt'));
    } catch (e) {
      debugPrint('[SignMT embedded] init error: $e');
      _signWebError = e.toString();
      _signWebLoading = false;
    }
  }

  Future<void> _injectTextToSignMt(String text) async {
    try {
      await _signWebController.runJavaScript('''
        (function() {
          const inputSelector = 'input[placeholder*="text"], textarea, [contenteditable="true"]';
          const inputElement = document.querySelector(inputSelector);
          if (inputElement) {
            inputElement.value = "$text";
            inputElement.textContent = "$text";
            inputElement.dispatchEvent(new Event('input', { bubbles: true }));
            inputElement.dispatchEvent(new Event('change', { bubbles: true }));
          }
        })();
      ''');
    } catch (e) {
      debugPrint('[SignMT embedded] inject error: $e');
    }
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

      // Dispose any existing controller and wait for it to finish disposing
      if (_cameraController != null) {
        try {
          await _cameraController!.dispose();
        } catch (e) {
          debugPrint('[Camera] dispose error: $e');
        }
        _cameraController = null;
      }

      _cameraController = CameraController(
        desc,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      try {
        await _cameraController!.initialize();
        if (!mounted) return;
        setState(() {
          _cameraInitializing = false;
        });
      } catch (e) {
        // If initialize failed, dispose the controller and clear it so the UI
        // doesn't reference a partially-initialized controller.
        debugPrint('[Camera] initialize error: $e');
        try {
          await _cameraController?.dispose();
        } catch (_) {}
        _cameraController = null;
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Camera init error: $e')));
        }
        setState(() {
          _cameraInitializing = false;
        });
        return;
      }
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

  // 2026-02-22: SAMPLE CAPTURE helpers
  Future<Directory> _getSamplesRoot() async {
    // 2026-02-22: Store samples persistently in application documents directory
    try {
      final appDoc = await getApplicationDocumentsDirectory();
      final root = Directory('${appDoc.path}/handylingo_samples');
      if (!await root.exists()) await root.create(recursive: true);
      return root;
    } catch (e) {
      // fallback to system temp if documents dir is unavailable
      debugPrint('[Samples] could not get documents directory: $e');
      final root = Directory('${Directory.systemTemp.path}/handylingo_samples');
      if (!await root.exists()) await root.create(recursive: true);
      return root;
    }
  }

  Future<Directory> _getPhraseDir(String phrase) async {
    final root = await _getSamplesRoot();
    final slug = phrase.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final dir = Directory('${root.path}/$slug');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  void _startSampleCapture() {
    // 2026-02-22: Start periodic capture while recording
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    _captureCount = 0;
    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(const Duration(milliseconds: 350), (
      t,
    ) async {
      try {
        final xfile = await _cameraController!.takePicture();
        final dir = await _getPhraseDir(_selectedPhrase);
        final name = DateTime.now().toIso8601String().replaceAll(':', '-');
        final outPath = '${dir.path}/$name.jpg';
        await File(xfile.path).copy(outPath);
        _captureCount++;
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('[Camera] sample capture error: $e');
      }
    });
  }

  void _stopSampleCapture() async {
    // 2026-02-22: Stop periodic capture and notify user
    _captureTimer?.cancel();
    _captureTimer = null;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved $_captureCount samples for "$_selectedPhrase"'),
        ),
      );
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
    _captureTimer?.cancel();
    _cameraController?.dispose();
    // WebViewController does not require explicit dispose, but clear state
    // (no-op) kept for clarity
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
    // Dispose current controller first to avoid SurfaceTexture being abandoned
    if (_cameraController != null) {
      try {
        await _cameraController!.dispose();
      } catch (e) {
        debugPrint('[Camera] dispose error during switch: $e');
      }
      _cameraController = null;
    }

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

    if (_collectMode) {
      // 2026-02-22: quick capture session for taps (save ~1 second of frames)
      _startSampleCapture();
      Future.delayed(const Duration(seconds: 1), () {
        _stopSampleCapture();
        setState(() => _isRecording = false);
      });
    } else {
      _startProcessing();
      // turn off recording indicator quickly
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() => _isRecording = false);
      });
    }
  }

  void _onLongPressStart() {
    setState(() => _isRecording = true);
    if (_collectMode) {
      // 2026-02-22: begin continuous sample capture while holding
      _startSampleCapture();
    }
  }

  void _onLongPressEnd() {
    setState(() => _isRecording = false);
    if (_collectMode) {
      // 2026-02-22: stop collecting samples
      _stopSampleCapture();
    } else {
      _startProcessing(withText: 'Spoken text recognized and converted.');
    }
  }

  void _onSubmitText() {
    final t = _textController.text.trim();
    if (t.isEmpty) return;
    FocusScope.of(context).unfocus();
    _startProcessing(withText: t);
  }

  void _openSignMtTranslator() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignMtTranslatorPage(
          initialText: _textController.text.isNotEmpty
              ? _textController.text
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF8FB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Row: About (left) + Mute (right) — hidden in 3D mode
            if (_mode == InputMode.signLanguage)
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
                                    // 3D / Text mode: embed Sign.MT web app in place
                                    if (_signWebError != null) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: Colors.red,
                                              size: 64,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Failed to load translator',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(_signWebError ?? ''),
                                            const SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  _signWebController.reload(),
                                              child: const Text('Retry'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return Stack(
                                      children: [
                                        WebViewWidget(
                                          controller: _signWebController,
                                        ),
                                        if (_signWebLoading)
                                          const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      ],
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

                    // 2026-02-22: Phrase selector + collect toggle (only in SL mode)
                    if (_mode == InputMode.signLanguage)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _selectedPhrase,
                                    items: _phrases
                                        .map(
                                          (p) => DropdownMenuItem(
                                            value: p,
                                            child: Text(
                                              p,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() => _selectedPhrase = v);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                IconButton(
                                  tooltip: _collectMode
                                      ? 'Collecting: ON'
                                      : 'Collect samples',
                                  icon: Icon(
                                    _collectMode
                                        ? Icons.save
                                        : Icons.play_circle_fill,
                                    color: _collectMode
                                        ? Colors.green
                                        : Colors.black54,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => _collectMode = !_collectMode,
                                    );
                                    if (!_collectMode) {
                                      // if turning off while capturing, stop
                                      _stopSampleCapture();
                                    }
                                  },
                                ),
                                Text(
                                  'Collect',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Thinking / result box — hidden in 3D mode
                    if (_mode == InputMode.signLanguage)
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

                    if (_mode == InputMode.signLanguage)
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

                          // Center action — text input only in Sign Language mode
                          if (_mode == InputMode.signLanguage)
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: GestureDetector(
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
                                ),
                              ),
                            )
                          else
                            // Text mode: show text input below the 3D area (this won't show in expanded camera area)
                            const SizedBox.shrink(),

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
