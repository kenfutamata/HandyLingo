import 'package:flutter/material.dart';
import '../services/sign_translator_service.dart';
import '../config/sign_mt_config.dart';
import 'sign_mt_translator_page.dart';

/// Example integration of Sign.MT translator into StartUsingPage
/// Add these snippets to your start_using.dart file

class SignTranslatorIntegrationExample extends StatefulWidget {
  const SignTranslatorIntegrationExample({super.key});

  @override
  State<SignTranslatorIntegrationExample> createState() =>
      _SignTranslatorIntegrationExampleState();
}

class _SignTranslatorIntegrationExampleState
    extends State<SignTranslatorIntegrationExample> {
  late final SignTranslatorService _translatorService;
  bool _isTranslating = false;
  String? _translationResult;

  @override
  void initState() {
    super.initState();
    _translatorService = SignTranslatorService();
    _checkTranslatorAvailability();
  }

  /// Check if translator service is available
  Future<void> _checkTranslatorAvailability() async {
    try {
      final isAvailable = await _translatorService.isAvailable();
      if (isAvailable) {
        debugPrint('✅ Sign.MT translator is available');
      } else {
        debugPrint('⚠️ Sign.MT translator is not available');
      }
    } catch (e) {
      debugPrint('❌ Error checking translator: $e');
    }
  }

  /// Translate text to sign language using the API
  /// This method sends text to the sign.mt backend for translation
  Future<void> _translateTextToSign(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _isTranslating = true;
      _translationResult = null;
    });

    try {
      final result = await _translatorService.translateTextToSign(
        text,
        sourceLanguage: 'en',
        signLanguage: SignMtConfig.defaultSignLanguage,
      );

      if (mounted) {
        setState(() {
          _translationResult = result.toString();
          _isTranslating = false;
        });

        // Show result
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Translation complete!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _translationResult = 'Translation failed: $e';
          _isTranslating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Translation error: $e');
    }
  }

  /// Open the full Sign.MT translator in a WebView
  /// This gives access to the complete translator UI
  void _openFullTranslator() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignMtTranslatorPage()));
  }

  /// Open translator with pre-filled text
  void _openTranslatorWithText(String text) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignMtTranslatorPage(initialText: text),
      ),
    );
  }

  @override
  void dispose() {
    _translatorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign.MT Integration Example')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// OPTION 1: Quick Translation Button
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Translation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _translateTextToSign('Hello, how are you?'),
                        icon: const Icon(Icons.translate),
                        label: const Text('Translate Text'),
                      ),
                    ),
                    if (_isTranslating) ...[
                      const SizedBox(height: 12),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    if (_translationResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(_translationResult!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// OPTION 2: Full Translator WebView
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Full Translator',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Opens the complete Sign.MT translator interface with all features.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openFullTranslator,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Translator'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// OPTION 3: Integration with User Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Translate Your Text',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter text to translate',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onSubmitted: (text) => _openTranslatorWithText(text),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _openTranslatorWithText('Type something'),
                        child: const Text('Translate'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// OPTION 4: Configuration Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _ConfigItem(
                      label: 'Translator URL',
                      value: SignMtConfig.translatorWebUrl,
                    ),
                    _ConfigItem(
                      label: 'Default Sign Language',
                      value: SignMtConfig.defaultSignLanguage,
                    ),
                    _ConfigItem(
                      label: 'Default Spoken Language',
                      value: SignMtConfig.defaultSpokenLanguage,
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

class _ConfigItem extends StatelessWidget {
  final String label;
  final String value;

  const _ConfigItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
