import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Page that embeds the sign.mt translator web application
/// This provides access to the full sign.mt UI and features
class SignMtTranslatorPage extends StatefulWidget {
  final String? initialText;

  const SignMtTranslatorPage({super.key, this.initialText});

  @override
  State<SignMtTranslatorPage> createState() => _SignMtTranslatorPageState();
}

class _SignMtTranslatorPageState extends State<SignMtTranslatorPage> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            debugPrint('[SignMT] Page started loading: $url');
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _errorMessage = null;
            });
            debugPrint('[SignMT] Page finished loading: $url');

            // Inject initial text if provided
            if (widget.initialText != null) {
              _injectInitialText(widget.initialText!);
            }
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = error.description;
            });
            debugPrint('[SignMT] Web resource error: ${error.description}');
          },
          onHttpError: (HttpResponseError error) {
            debugPrint('[SignMT] HTTP error: ${error.response?.statusCode}');
          },
        ),
      )
      // Load from remote (sign.mt) or local server
      // For local development, replace with: http://localhost:4200
      ..loadRequest(Uri.parse('https://sign.mt'));
  }

  /// Inject initial text into the translator
  /// Adjust the JavaScript based on sign.mt's actual DOM structure
  Future<void> _injectInitialText(String text) async {
    try {
      await _webViewController.runJavaScript('''
        (function() {
          // Adjust selectors based on actual sign.mt DOM
          const inputSelector = 'input[placeholder*="text"], textarea, [contenteditable="true"]';
          const inputElement = document.querySelector(inputSelector);
          if (inputElement) {
            inputElement.value = "$text";
            inputElement.textContent = "$text";
            // Trigger input event to notify the app
            inputElement.dispatchEvent(new Event('input', { bubbles: true }));
            inputElement.dispatchEvent(new Event('change', { bubbles: true }));
          }
        })();
      ''');
    } catch (e) {
      debugPrint('[SignMT] Error injecting text: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign.MT Translator'),
        backgroundColor: const Color(0xFF1E88E5),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),

          // Loading indicator
          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // Error message
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load translator',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _errorMessage ?? 'Unknown error',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _webViewController.reload(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
