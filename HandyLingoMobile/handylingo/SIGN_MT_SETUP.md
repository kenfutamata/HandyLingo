# Sign.MT Integration Setup Guide

## Overview
This guide explains how to integrate the **sign.mt translator** into your HandyLingo Flutter mobile app.

## What is Sign.MT?
Sign.MT is a state-of-the-art sign language translation platform that converts:
- ✅ Text → Sign Language (with pose sequences or 3D avatars)
- ✅ Sign Language Video → Text

Located in: `translate-master/` folder

---

## Integration Methods

### **Method 1: WebView Integration (Quickest)**
Embed the sign.mt web app directly in your Flutter app.

**Pros:**
- Access to full sign.mt features
- No backend setup needed initially
- Works offline with local build

**Cons:**
- Larger app size
- Requires building web assets
- Limited data exchange with Flutter

---

### **Method 2: REST API Integration (Recommended)**
Deploy sign.mt as a backend service and call it via HTTP.

**Pros:**
- Better performance
- Easy to call from Flutter
- Scalable for many users
- Can use Firebase Cloud Functions

**Cons:**
- Requires backend hosting
- Needs internet connectivity

---

## Step-by-Step Setup

### **Step 1: Build the sign.mt Web App**

Navigate to the translate-master folder:
```bash
cd HandyLingoMobile\translate-master
npm install
npm run build
```

This creates: `dist/sign-translate/browser/` (your web app files)

---

### **Step 2: Choose Integration Method**

#### **Option A: Local WebView (For Testing)**

Copy built files to Flutter assets:
```
handylingo/
  assets/
    sign_translator/
      ... (web app files from dist/)
```

Update `pubspec.yaml`:
```yaml
assets:
  - assets/sign_translator/
```

Then use local path in WebView:
```dart
_webViewController..loadRequest(Uri.parse('file:///flutter_assets/sign_translator/index.html'));
```

#### **Option B: Host Online (Recommended)**

1. **Firebase Hosting** (Free tier available):
   ```bash
   firebase login
   firebase init hosting
   # Point to dist/sign-translate/browser/ as public directory
   firebase deploy
   ```

2. **Your Own Server**:
   - Upload the `dist/sign-translate/browser/` contents to any web server
   - Update the URL in `sign_mt_translator_page.dart`

#### **Option C: Backend API**

Deploy the backend functions:
```bash
cd functions
npm install
firebase deploy --only functions
```

Then call using `SignTranslatorService` class (already created)

---

## Step 3: Add Dependencies to pubspec.yaml

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  webview_flutter: ^4.0.0
  http: ^1.1.0
```

Then run:
```bash
flutter pub get
```

---

## Step 4: Update start_using.dart

Add buttons to access the translator:

```dart
// In your _StartUsingPageState class, add:

void _openSignMtTranslator() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SignMtTranslatorPage(
        initialText: _textController.text,
      ),
    ),
  );
}

// In your text input section, add a button:
GestureDetector(
  onTap: _openSignMtTranslator,
  child: Icon(Icons.language_outlined),
),
```

---

## Step 5: Platform-Specific Configuration

### **Android (android/app/build.gradle)**
No additional changes needed for webview_flutter

### **iOS (ios/Runner/Info.plist)**
Add:
```xml
<key>NSBonjourServices</key>
<array>
  <string>_http._tcp</string>
  <string>_https._tcp</string>
</array>
```

### **Web Permissions**
If using camera in the webview:
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

---

## Testing

1. **Local Web Server (for development)**:
   ```bash
   # In translate-master folder:
   npm start
   # Runs on http://localhost:4200
   ```

2. **Update the WebView URL**:
   ```dart
   ..loadRequest(Uri.parse('http://10.0.2.2:4200')) // Android emulator
   // or
   ..loadRequest(Uri.parse('http://localhost:4200')) // Physical device (same network)
   ```

3. **Test TranslatorService**:
   ```dart
   // In your code:
   final service = SignTranslatorService();
   final result = await service.translateTextToSign('Hello');
   ```

---

## Directory Structure After Setup

```
handylingo/
├── lib/
│   ├── services/
│   │   └── sign_translator_service.dart  (NEW)
│   └── views/
│       ├── start_using.dart              (MODIFIED)
│       └── sign_mt_translator_page.dart  (NEW)
├── assets/
│   └── sign_translator/                  (OPTIONAL - for local hosting)
│       └── ... (web dist files)
└── pubspec.yaml                          (MODIFIED)
```

---

## Environment Variables

Create `lib/config/translator_config.dart`:

```dart
class TranslatorConfig {
  // Change based on deployment
  static const String translatorUrl = String.fromEnvironment(
    'TRANSLATOR_URL',
    defaultValue: 'https://sign.mt', // Change to your hosted URL
  );
  
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://sign.mt/api',
  );
}
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| WebView blank page | Check internet connection, verify URL, check CORS headers |
| Camera not working | Ensure permissions granted, check browser console for errors |
| API timeout | Increase timeout duration, check backend service status |
| Large app size | Use remote hosted version instead of embedding locally |
| CORS errors | Backend needs to allow Flutter app domain |

---

## Next Steps

1. ✅ Build the sign.mt web app
2. ✅ Choose hosting method
3. ✅ Add dependencies
4. ✅ Update Flutter UI
5. ✅ Test thoroughly
6. ✅ Deploy to production

---

## Resources

- [sign.mt Repository](https://github.com/sign/translate)
- [WebView Flutter Docs](https://pub.dev/packages/webview_flutter)
- [Firebase Hosting Docs](https://firebase.google.com/docs/hosting)

---

## Questions?

Check the logs with: `flutter logs`
