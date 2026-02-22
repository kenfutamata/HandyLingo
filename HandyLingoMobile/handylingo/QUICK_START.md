# Quick Reference: Sign.MT Integration for Start Using Page

## 🎯 Goal
Integrate sign.mt translator into your `start_using.dart` page to enable text-to-sign and sign-to-text translation.

---

## 📋 What's Been Created For You

### New Files
1. **`lib/services/sign_translator_service.dart`**
   - HTTP client for translator API calls
   - Methods: `translateTextToSign()`, `translateSignToText()`, `isAvailable()`

2. **`lib/views/sign_mt_translator_page.dart`**
   - Full-screen WebView of sign.mt translator
   - Can embed the entire translator UI in your app

3. **`lib/config/sign_mt_config.dart`**
   - Centralized configuration
   - Supported languages, API URLs, settings

4. **`lib/views/sign_translator_integration_example.dart`**
   - Complete working example
   - Shows 4 different ways to use the translator

5. **Documentation**
   - `SIGN_MT_SETUP.md` - Detailed setup guide
   - `INTEGRATION_CHECKLIST.md` - Step-by-step checklist

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Add Dependencies
```yaml
# In pubspec.yaml dependencies section:
webview_flutter: ^4.0.0
http: ^1.1.0
```

### Step 2: Run Flutter Pub
```bash
cd HandyLingoMobile\handylingo
flutter pub get
```

### Step 3: Update start_using.dart
Add this at the top with other imports:
```dart
import 'sign_mt_translator_page.dart';
import 'services/sign_translator_service.dart';
import 'config/sign_mt_config.dart';
```

Add this method to `_StartUsingPageState` class:
```dart
void _openSignTranslator() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const SignMtTranslatorPage(),
    ),
  );
}
```

### Step 4: Add UI Button
In your text mode section (around line 825 in start_using.dart), add:
```dart
// After the text input field
IconButton(
  icon: const Icon(Icons.language_outlined),
  onPressed: _openSignTranslator,
  tooltip: 'Open Sign Language Translator',
),
```

### Step 5: Test
```bash
flutter run
```

---

## 📡 Hosting the Web App

### Option A: Firebase (Easiest)
```bash
# In translate-master folder
firebase login
firebase init hosting
firebase deploy --only hosting
```

Then update `lib/config/sign_mt_config.dart`:
```dart
static const String translatorWebUrl = 'https://YOUR-PROJECT.web.app';
```

### Option B: Local Testing
```bash
# In translate-master folder
npm start
```

Update config:
```dart
static const String translatorWebUrl = 'http://10.0.2.2:4200'; // Android emulator
```

### Option C: Embed in App (Larger App Size)
```yaml
# In pubspec.yaml
assets:
  - assets/sign_translator/
```

Update config:
```dart
static const String translatorWebUrl = 'file:///flutter_assets/sign_translator/index.html';
```

---

## 💡 Integration Patterns

### Pattern 1: Full Translator Page (Easiest)
```dart
// Open full translator
void _openTranslator() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const SignMtTranslatorPage(),
    ),
  );
}
```

### Pattern 2: API-Based Translation (Best For Performance)
```dart
final service = SignTranslatorService();

// Translate text to sign
final result = await service.translateTextToSign(
  'Hello, how are you?',
  sourceLanguage: 'en',
  signLanguage: 'asl',
);
```

### Pattern 3: Quick Translation Button
```dart
ElevatedButton(
  onPressed: () async {
    final service = SignTranslatorService();
    try {
      final result = await service.translateTextToSign(
        _textController.text,
      );
      // Show result to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Translation ready!')),
      );
    } catch (e) {
      // Handle error
    }
  },
  child: const Text('Translate'),
)
```

### Pattern 4: Pre-Fill Text
```dart
// Open translator with text already filled in
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => SignMtTranslatorPage(
      initialText: _textController.text,
    ),
  ),
);
```

---

## 🔧 Configuration Options

Located in `lib/config/sign_mt_config.dart`:

```dart
// Change the translator URL
static const String translatorWebUrl = 'https://sign.mt'; // Default

// Change default sign language
static const String defaultSignLanguage = 'asl'; // or 'bsl', 'lsf', etc.

// Change spoken language
static const String defaultSpokenLanguage = 'en';

// API timeouts
static const Duration textTranslationTimeout = Duration(seconds: 30);
static const Duration videoTranslationTimeout = Duration(minutes: 5);
```

---

## 🧪 Testing Checklist

- [ ] Dependencies added and `flutter pub get` run
- [ ] WebView page opens without errors
- [ ] Translator loads and displays
- [ ] Can input text in translator
- [ ] Camera/mic permissions work (if needed)
- [ ] Translations complete successfully
- [ ] No CORS errors in browser console

---

## 🛠️ Troubleshooting

### WebView shows blank page
1. Check URL in `sign_mt_config.dart`
2. Verify Firebase deployment (if using Firebase)
3. Test URL in browser first

### "No such file or directory" errors
1. Run `flutter pub get`
2. Make sure all imports use correct file paths

### CORS errors
1. If using remote API, ensure backend allows your domain
2. Use Firebase CORS headers automatically handled

### App crashes on cold start
1. Update `webview_flutter: ^4.0.0` to latest version
2. Run `flutter clean && flutter pub get`

---

## 📊 Recommended Architecture

```
start_using.dart
    ↓
    └─→ Text/Speech Input Mode
         ├─→ [Translate Button]
         └─→ Opens SignMtTranslatorPage (WebView)
               ↓
               └─→ sign.mt Web App (Firebase Hosted)
```

---

## 🎬 Live Example

See `lib/views/sign_translator_integration_example.dart` for a complete working example you can test immediately:

```bash
# Add to main.dart routes or test by navigating to it
```

---

## 📞 Next Steps

1. **Today**: Add dependencies and deploy web app
2. **Tomorrow**: Test WebView integration on device
3. **Next**: Implement API calls for better performance
4. **Later**: Add caching and offline support

---

## 🔗 Resources

- Main Setup Guide: [SIGN_MT_SETUP.md](./SIGN_MT_SETUP.md)
- Implementation Checklist: [INTEGRATION_CHECKLIST.md](./INTEGRATION_CHECKLIST.md)
- Example Implementation: [sign_translator_integration_example.dart](./lib/views/sign_translator_integration_example.dart)
- Configuration: [sign_mt_config.dart](./lib/config/sign_mt_config.dart)

---

## 💾 File Structure After Integration

```
lib/
├── config/
│   └── sign_mt_config.dart          (Configuration)
├── services/
│   └── sign_translator_service.dart (API Client)
└── views/
    ├── start_using.dart             (Updated)
    ├── sign_mt_translator_page.dart (WebView Page)
    └── sign_translator_integration_example.dart (Example)
```

---

**Ready to integrate? Start with the INTEGRATION_CHECKLIST.md file!**
