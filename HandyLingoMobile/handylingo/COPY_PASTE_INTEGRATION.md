# Copy-Paste Integration Guide for start_using.dart

This guide shows exactly what code to add to your existing `start_using.dart` file to integrate the Sign.MT translator.

---

## Step 1: Add Imports (At the top of start_using.dart)

**Find this section:**
```dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'about_page.dart';
import 'account_page.dart';
```

**Add these imports:**
```dart
import 'sign_mt_translator_page.dart';
import '../services/sign_translator_service.dart';
import '../config/sign_mt_config.dart';
```

So it becomes:
```dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'about_page.dart';
import 'account_page.dart';
import 'sign_mt_translator_page.dart';            // ← ADD
import '../services/sign_translator_service.dart'; // ← ADD
import '../config/sign_mt_config.dart';            // ← ADD
```

---

## Step 2: Add Method to _StartUsingPageState Class

**Find the `_StartUsingPageState` class** and add this method anywhere inside it:

```dart
void _openSignMtTranslator() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const SignMtTranslatorPage(
        // Optionally pass current text to pre-fill
        initialText: _textController.text.isNotEmpty 
            ? _textController.text 
            : null,
      ),
    ),
  );
}
```

**Good place to add it**: Right after the `_toggleMode()` method

---

## Step 3: Add UI Button to Text Mode

**Find this section in your build() method** (around line 825):
```dart
} else {
  // Text mode: show a box or text button
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
          /* Lines 825-837 omitted */
        ),
        // Speech-to-text mic button
        IconButton(
          /* Lines 841-855 omitted */
        },
        /* Lines 857-860 omitted */
        ),
      ],
    ),
  ),
}
```

**Replace with:**
```dart
} else {
  // Text mode: show a box or text button
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
              hintText: 'Type text to translate...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => _onSubmitText(),
          ),
        ),
        
        // ===== ADD TRANSLATOR BUTTON =====
        IconButton(
          icon: const Icon(Icons.language_outlined),
          onPressed: _openSignMtTranslator,
          tooltip: 'Open Sign Language Translator',
          color: Colors.blue,
        ),
        // ===== END NEW CODE =====
        
        // Speech-to-text mic button
        IconButton(
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? Colors.red : Colors.black54,
          ),
          onPressed: _isListening ? _stopListening : _startListening,
          tooltip: 'Speech to text',
        ),
        
        // Submit button
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: _onSubmitText,
          color: Colors.blue,
        ),
      ],
    ),
  );
}
```

---

## Step 4: Update pubspec.yaml

**Open `pubspec.yaml`** and add to the dependencies section:

```yaml
dependencies:
  flutter:
    sdk: flutter 
  flutter_riverpod: ^3.1.0
  google_fonts: ^6.3.3
  url_launcher: ^6.1.10
  flutter_dotenv: ^6.0.0
  supabase_flutter: ^2.12.0
  bcrypt: ^1.2.0
  flutter_svg: ^1.1.6
  speech_to_text: ^7.3.0
  permission_handler: ^12.0.1
  camera: ^0.10.0+1
  image_picker: ^0.8.7+5
  shared_preferences: ^2.1.0
  google_sign_in: ^6.2.1
  path_provider: ^2.0.15
  cupertino_icons: ^1.0.8
  change_notifier: ^0.28.0
  webview_flutter: ^4.0.0        # ← ADD THIS
  http: ^1.1.0                   # ← ADD THIS
```

---

## Step 5: Run Commands

In your terminal, navigate to the handylingo folder:

```bash
cd HandyLingoMobile\handylingo

# Get new dependencies
flutter pub get

# Clean build
flutter clean

# Run the app
flutter run
```

---

## Step 6: Test

1. Open the app
2. Switch to "Text" mode (tap "Switch" button)
3. You should see a text input field with a translator button (🌐)
4. Tap the translator button
5. The Sign.MT translator should open

---

## Optional: Add More Integration Points

### Add Translator Button in Top Menu

**Find the top row** (around line 480):
```dart
// Top Row: About (left) + Mute (right)
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: () { /* ... */ },
      ),
      IconButton(
        icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
        onPressed: _toggleMute,
      ),
    ],
  ),
),
```

**To add translator access, add this after the mute button:**
```dart
IconButton(
  icon: const Icon(Icons.language),
  onPressed: _openSignMtTranslator,
  tooltip: 'Translator',
),
```

### Add Quick Translator for Sample Collection

**In the sample collection area** (around line 685), after the collect toggle:

```dart
IconButton(
  tooltip: 'View translator',
  icon: const Icon(Icons.translate),
  onPressed: () {
    if (_collectMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stop collection mode first'),
        ),
      );
    } else {
      _openSignMtTranslator();
    }
  },
),
```

---

## Complete Modified Section (Text Mode)

Here's the complete text mode control section with translator integrated:

```dart
} else {
  // Text mode: show a box or text button
  Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.black12),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            decoration: const InputDecoration(
              hintText: 'Type text to translate...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => _onSubmitText(),
          ),
        ),
        
        // Translator button
        IconButton(
          icon: const Icon(Icons.language_outlined),
          onPressed: _openSignMtTranslator,
          tooltip: 'Sign Language Translator',
          color: Colors.blue[700],
        ),
        
        // Speech-to-text mic button
        IconButton(
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? Colors.red : Colors.black54,
          ),
          onPressed: _isListening ? _stopListening : _startListening,
          tooltip: 'Speech to Text',
          color: Colors.blue[700],
        ),
        
        // Submit button
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: _onSubmitText,
          color: Colors.blue[700],
        ),
      ],
    ),
  );
}
```

---

## Troubleshooting

### "Cannot find 'sign_mt_translator_page'"
- Make sure file exists: `lib/views/sign_mt_translator_page.dart`
- Check imports use correct relative paths

### "Unresolved import" errors
- Run `flutter pub get`
- Close and reopen your IDE
- Try `flutter clean` then `flutter pub get` again

### WebView shows blank page
- Check `lib/config/sign_mt_config.dart`
- Verify the translator URL is correct
- Open the URL in a browser to test

### Port already in use (local development)
- If using `npm start` locally, make sure only one instance runs
- Or use a different port: `npm start -- --port 3000`

---

## What Each Button Does

| Button | Icon | Action |
|--------|------|--------|
| 🌐 Translator | `language_outlined` | Opens full Sign.MT translator |
| 🎤 Microphone | `mic` / `mic_none` | Speech to text |
| ➤ Send | `send` | Submit text for translation |

---

## Next: Configure the Translator URL

Edit `lib/config/sign_mt_config.dart` and update:

```dart
// Development with local npm server:
static const String translatorWebUrl = 'http://10.0.2.2:4200';

// OR Production with Firebase:
static const String translatorWebUrl = 'https://your-project.web.app';

// OR Embedded in app assets:
static const String translatorWebUrl = 'file:///flutter_assets/sign_translator/index.html';
```

---

## Build the Web App (One-time Setup)

Before the translator will work, you need to build the web app:

```bash
# Navigate to translate-master directory
cd translate-master

# Install dependencies
npm install

# Build for production
npm run build

# This creates: dist/sign-translate/browser/
```

Then deploy it:

```bash
# Option 1: Firebase (Easiest)
firebase deploy --only hosting

# Option 2: Or embed in your app
cp -r dist/sign-translate/browser/* ../handylingo/assets/sign_translator/
```

---

## Summary

1. ✅ Add imports
2. ✅ Add method `_openSignMtTranslator()`
3. ✅ Add button to UI
4. ✅ Update `pubspec.yaml`
5. ✅ Run `flutter pub get`
6. ✅ Test
7. ✅ Deploy web app (Firebase or local)
8. ✅ Update config URL
9. ✅ Test on device
10. ✅ Done! 🎉

---

## Questions?

Refer to:
- **Quick Start**: QUICK_START.md
- **Detailed Setup**: SIGN_MT_SETUP.md
- **Integration Checklist**: INTEGRATION_CHECKLIST.md
- **Full Example**: lib/views/sign_translator_integration_example.dart
