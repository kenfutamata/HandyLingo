import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart'; // SUPABASE
import 'package:uuid/uuid.dart'; // UUID for Primary Key
import 'package:flutter_tts/flutter_tts.dart'; // AUDIO SYSTEM

import 'account_page.dart';

enum InputMode { signLanguage, text }

enum SignLanguageType { asl, fsl }

class StartUsingPage extends StatefulWidget {
  const StartUsingPage({super.key});
  @override
  State<StartUsingPage> createState() => _StartUsingPageState();
}

class _StartUsingPageState extends State<StartUsingPage>
    with WidgetsBindingObserver {
  //api call link
  final String _serverUrl = "https://handylingo-handylingo-ai.hf.space/predict";
  //localhost
  // final String _serverUrl = "http://192.168.1.8:8001/predict";

  // Initialize Supabase Client
  final _supabase = Supabase.instance.client;

  // Initialize Text-to-Speech
  final FlutterTts _flutterTts = FlutterTts();

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
  String _textSize = 'Small';
  late final WebViewController _signWebController;
  late final stt.SpeechToText _speechToText;
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _signMtReady = false;
  String _recognizedSpeech = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTts(); // Setup Audio
    _initSpeechRecognition();
    _initializeSignWeb();
    _loadTextSizePreference();
    _initCamera();
  }

  // --- AUDIO SYSTEM SETUP ---
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5); // Adjust speed
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  // --- DATABASE SYSTEM SETUP ---
  Future<void> _saveLogToSupabase(String word, double accuracy) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      debugPrint("Database Error: No user logged in.");
      return;
    }

    try {
      await _supabase.from('sign_language_logs').insert({
        'id': const Uuid().v4(), // Generate unique log ID
        'user_id': user.id, // Link to logged-in user
        'translated_output': word,
        'accuracy': accuracy,
      });
      debugPrint("Supabase: Log saved successfully!");
    } catch (e) {
      debugPrint("Supabase Save Error: $e");
    }
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
      request.fields['language'] = _languageType == SignLanguageType.asl
          ? "asl"
          : "fsl";

      for (var frame in frames) {
        request.files.add(
          await http.MultipartFile.fromPath('files', frame.path),
        );
      }

      var response = await request.send().timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);

        String word = json['prediction_label'] ?? "";
        double confidence = (json['confidence'] ?? 0.0) * 100;

        if (word.toUpperCase() != "(NONE)" && word != "") {
          setState(() {
            _accumulatedSentence +=
                (_accumulatedSentence.isEmpty ? "" : " ") + word;
          });

          // 1. Trigger Audio
          _speak(word);

          // 2. Trigger Database Save
          _saveLogToSupabase(word, confidence);
        }
        _currentStatus = "Ready";
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
      ..addJavaScriptChannel(
        'SpeechToText',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'start') {
            _startListening();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            await _injectSignMtBridge();
            if (!mounted) return;
            setState(() => _signMtReady = true);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Sign.MT WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://sign.mt'));
  }

  Future<void> _initSpeechRecognition() async {
    _speechToText = stt.SpeechToText();
    final available = await _speechToText.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => debugPrint('Speech error: $error'),
    );
    if (!mounted) return;
    setState(() => _speechAvailable = available);
  }

  Future<void> _startListening() async {
    if (_isListening || !_speechAvailable) return;
    setState(() => _isListening = true);

    await _speechToText.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        setState(() => _recognizedSpeech = text);
        if (result.finalResult) {
          _stopListening();
          _injectTextIntoWebView(text);
        }
      },
      localeId: 'en_US',
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    await _speechToText.stop();
    if (!mounted) return;
    setState(() => _isListening = false);
  }

  Future<void> _injectTextIntoWebView(String text) async {
    if (!_signMtReady) {
      await _injectSignMtBridge();
      if (!mounted) return;
      setState(() => _signMtReady = true);
    }

    try {
      final encodedText = jsonEncode(text);
      await _signWebController.runJavaScript('''
        (function(text) {
          function findInput() {
            const selectors = [
              'textarea:not([hidden]):not([disabled])',
              'input[type="text"]:not([hidden]):not([disabled])',
              'input[type="search"]:not([hidden]):not([disabled])',
              'input[type="email"]:not([hidden]):not([disabled])',
              'input[type="url"]:not([hidden]):not([disabled])',
              'input[type="tel"]:not([hidden]):not([disabled])',
              '[contenteditable="true"]:not([hidden])',
            ];
            for (const selector of selectors) {
              const el = document.querySelector(selector);
              if (el) return el;
            }
            return Array.from(document.querySelectorAll('input, textarea, [contenteditable="true"]')).find(el => {
              const label = ((el.getAttribute('placeholder') || el.getAttribute('aria-label') || el.getAttribute('name') || '') + '').toLowerCase();
              return label.includes('text') || label.includes('enter') || label.includes('sign') || label.includes('message');
            });
          }

          function clickElement(el) {
            if (!el) return false;
            el.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true }));
            el.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, cancelable: true }));
            el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }));
            return true;
          }

          function findTranslateButton() {
            return document.querySelector('button[type="submit"], input[type="submit"], button[aria-label*="translate"], button[title*="translate"], button[class*="translate"], button[data-testid*="translate"], input[aria-label*="translate"], input[title*="translate"], input[class*="translate"], input[data-testid*="translate"]') ||
              Array.from(document.querySelectorAll('button, input[type="button"], input[type="submit"], [role="button"]')).find(el => {
                const text = ((el.innerText || el.value || el.getAttribute('aria-label') || el.getAttribute('title') || '') + '').toLowerCase();
                return ['translate', 'sign', 'go', 'send', 'submit', 'show'].some(pattern => text.includes(pattern));
              });
          }

          const inputElement = findInput();
          if (!inputElement) {
            console.warn('[Flutter] Sign.MT input not found');
            return;
          }

          if ('value' in inputElement) {
            inputElement.value = text;
          } else {
            inputElement.textContent = text;
          }

          const eventOptions = { bubbles: true, composed: true };
          inputElement.dispatchEvent(new Event('input', eventOptions));
          inputElement.dispatchEvent(new Event('change', eventOptions));

          setTimeout(() => {
            const translateButton = findTranslateButton();
            if (translateButton) {
              clickElement(translateButton);
              return;
            }
            const enterEvent = new KeyboardEvent('keydown', { key: 'Enter', code: 'Enter', keyCode: 13, bubbles: true, cancelable: true });
            inputElement.dispatchEvent(enterEvent);
            const form = inputElement.closest('form');
            if (form) {
              if (typeof form.requestSubmit === 'function') {
                form.requestSubmit();
              } else {
                form.submit();
              }
            }
          }, 120);
        })($encodedText);
      ''');
    } catch (e) {
      debugPrint('Sign.MT injection failed: $e');
    }
  }

  Future<void> _injectSignMtBridge() async {
    try {
      await _signWebController.runJavaScript('''
        (function() {
          if (window._flutterSignMt) return;
          window._flutterSignMt = {};

          function findButtonByText(patterns) {
            return Array.from(document.querySelectorAll('button, [role="button"], a, input[type="submit"], input[type="button"]')).find(el => {
              const text = ((el.innerText || el.textContent || el.value || el.getAttribute('aria-label') || el.getAttribute('title') || '') + '').toLowerCase();
              return patterns.some(pattern => text.includes(pattern));
            });
          };

          function clickElement(el) {
            if (!el) return false;
            try {
              const rect = el.getBoundingClientRect();
              const x = rect.left + rect.width / 2;
              const y = rect.top + rect.height / 2;
              if (typeof el.focus === 'function') {
                el.focus({ preventScroll: true });
              }
              if (typeof el.scrollIntoView === 'function') {
                el.scrollIntoView({ block: 'center', inline: 'center', behavior: 'auto' });
              }
              const eventOptions = { bubbles: true, cancelable: true, composed: true, clientX: x, clientY: y };
              const dispatchEvent = (type, ctor) => {
                try {
                  const event = typeof ctor === 'function' ? new ctor(type, eventOptions) : new Event(type, eventOptions);
                  el.dispatchEvent(event);
                } catch (e) {
                  try {
                    el.dispatchEvent(new Event(type, eventOptions));
                  } catch (_e) {}
                }
              };
              if (typeof Touch === 'function') {
                try {
                  const touch = new Touch({ identifier: Date.now(), target: el, clientX: x, clientY: y, pageX: x, pageY: y });
                  const touchStart = new TouchEvent('touchstart', { bubbles: true, cancelable: true, composed: true, touches: [touch], targetTouches: [touch], changedTouches: [touch] });
                  const touchEnd = new TouchEvent('touchend', { bubbles: true, cancelable: true, composed: true, touches: [], targetTouches: [], changedTouches: [touch] });
                  el.dispatchEvent(touchStart);
                  el.dispatchEvent(touchEnd);
                } catch (_) {}
              }
              dispatchEvent('pointerdown', window.PointerEvent);
              dispatchEvent('mousedown', window.MouseEvent);
              dispatchEvent('pointerup', window.PointerEvent);
              dispatchEvent('mouseup', window.MouseEvent);
              dispatchEvent('click', window.MouseEvent);
              return true;
            } catch (e) {
              console.log('[Flutter] clickElement error:', e.message || e);
              return false;
            }
          };

          function findTranslateButton() {
            return document.querySelector('button[type="submit"], input[type="submit"], button[aria-label*="translate"], button[title*="translate"], button[class*="translate"], button[data-testid*="translate"], input[aria-label*="translate"], input[title*="translate"], input[class*="translate"], input[data-testid*="translate"]') ||
              findButtonByText(['translate', 'sign', 'go', 'send', 'submit', 'show']);
          };

          window._flutterSignMt.setText = function(text) {
            const inputSelector = 'textarea[placeholder*="text"], input[placeholder*="text"], input[type="search"], [contenteditable="true"]';
            const inputElement = document.querySelector(inputSelector);
            if (!inputElement) return;

            if ('value' in inputElement) {
              inputElement.value = text;
            } else {
              inputElement.textContent = text;
            }

            const inputEvent = new Event('input', { bubbles: true, composed: true });
            const changeEvent = new Event('change', { bubbles: true, composed: true });
            inputElement.dispatchEvent(inputEvent);
            inputElement.dispatchEvent(changeEvent);

            setTimeout(() => {
              const translateButton = findTranslateButton();
              if (translateButton) {
                clickElement(translateButton);
                return;
              }
              const enterEvent = new KeyboardEvent('keydown', { key: 'Enter', code: 'Enter', bubbles: true });
              inputElement.dispatchEvent(enterEvent);
              window._flutterSignMt.submit();
            }, 100);
          };

          window._flutterSignMt.submit = function() {
            const translateButton = findTranslateButton();
            if (translateButton) {
              clickElement(translateButton);
              return;
            }
            const form = document.querySelector('form');
            if (form) {
              form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
            }
          };

          function patchMicButtons() {
            document.querySelectorAll('button').forEach(button => {
              if (button.dataset.flutterMicHooked) return;
              const icon = button.querySelector('ion-icon[name*="mic"], svg[data-icon*="mic"], i[class*="mic"], span[class*="mic"]');
              if (!icon) return;
              button.dataset.flutterMicHooked = 'true';
              button.addEventListener('click', function(event) {
                event.preventDefault();
                event.stopPropagation();
                if (window.SpeechToText && window.SpeechToText.postMessage) {
                  window.SpeechToText.postMessage('start');
                }
              }, true);
            });
          }

          patchMicButtons();
          const observer = new MutationObserver(patchMicButtons);
          observer.observe(document.body, { childList: true, subtree: true });
        })();
      ''');
    } catch (e) {
      debugPrint('Failed to inject Sign.MT bridge: $e');
    }
  }

  Widget _buildSignModePreview() {
    if (_cameraController?.value.isInitialized ?? false) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                onPressed: _toggleCamera,
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: ChoiceChip(
              label: Text(
                _languageType == SignLanguageType.asl ? "ASL" : "FSL",
              ),
              selected: true,
              onSelected: (val) => setState(
                () => _languageType = _languageType == SignLanguageType.asl
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
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildSignMtWebView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _signWebController),
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'speechToTextBtn',
                mini: false,
                backgroundColor: _isListening ? Colors.red : Colors.blue,
                onPressed: !_speechAvailable && !_isListening
                    ? null
                    : (_isListening ? _stopListening : _startListening),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
        if (_isListening)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mic, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _recognizedSpeech.isEmpty
                        ? 'Listening...'
                        : _recognizedSpeech,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
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
                  ? _buildSignModePreview()
                  : _buildSignMtWebView(),
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
    _flutterTts.stop(); // Clean up audio
    super.dispose();
  }
}
