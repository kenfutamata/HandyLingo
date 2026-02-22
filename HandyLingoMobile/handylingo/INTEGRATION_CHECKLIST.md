# Integration Checklist: Sign.MT Translator

## Phase 1: Build the Web App ✅
- [ ] Navigate to `HandyLingoMobile/translate-master/`
- [ ] Run `npm install` (if node_modules doesn't exist)
- [ ] Run `npm run build` 
  - Creates: `dist/sign-translate/browser/` folder
  - This folder contains the entire web application
- [ ] Verify build output exists and contains `index.html`

---

## Phase 2: Choose Hosting Method

### **Option A: Remote Hosting (Recommended)**

#### Firebase Hosting (Best for Quick Start)
- [ ] In `translate-master/` directory:
  - [ ] Run `firebase login`
  - [ ] Run `firebase init hosting`
  - [ ] Select your Firebase project
  - [ ] Set public directory to: `dist/sign-translate/browser`
  - [ ] Do NOT rewrite URLs to index.html (say "N" when asked)
- [ ] Deploy: `firebase deploy --only hosting`
- [ ] Copy your Firebase Hosting URL (e.g., `https://your-project.web.app`)
- [ ] Update in `lib/config/sign_mt_config.dart`:
  ```dart
  static const String translatorWebUrl = 'https://your-project.web.app';
  ```

#### Alternative: Custom Web Server
- [ ] Upload `dist/sign-translate/browser/` contents to your web server
- [ ] Update `translatorWebUrl` in config with your server URL
- [ ] Ensure CORS headers allow your Flutter app's domain

### **Option B: Local/Embedded (For Development)** 
- [ ] Copy `dist/sign-translate/browser/` folder to:
  ```
  HandyLingoMobile/handylingo/assets/sign_translator/
  ```
- [ ] Update `pubspec.yaml`:
  ```yaml
  assets:
    - assets/sign_translator/
  ```
- [ ] In `sign_mt_config.dart`, set:
  ```dart
  static const String translatorWebUrl = 'file:///flutter_assets/sign_translator/index.html';
  ```

---

## Phase 3: Update Flutter Project

### 3.1 Add Dependencies
- [ ] Open `HandyLingoMobile/handylingo/pubspec.yaml`
- [ ] Add to dependencies:
  ```yaml
  webview_flutter: ^4.0.0
  http: ^1.1.0
  ```
- [ ] Run: `flutter pub get`

### 3.2 Verify New Files Created
- [ ] `lib/services/sign_translator_service.dart` ✅ (Already created)
- [ ] `lib/views/sign_mt_translator_page.dart` ✅ (Already created)
- [ ] `lib/config/sign_mt_config.dart` ✅ (Already created)
- [ ] `lib/views/sign_translator_integration_example.dart` ✅ (Already created)
- [ ] `SIGN_MT_SETUP.md` ✅ (Already created)

---

## Phase 4: Integrate into Your UI

### 4.1 Update start_using.dart
- [ ] Import the translator page at the top:
  ```dart
  import 'sign_mt_translator_page.dart';
  ```

- [ ] Add this method to `_StartUsingPageState`:
  ```dart
  void _openTranslator() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SignMtTranslatorPage(),
      ),
    );
  }
  ```

- [ ] Add button to your UI (in the text mode section):
  ```dart
  IconButton(
    icon: const Icon(Icons.language_outlined),
    onPressed: _openTranslator,
    tooltip: 'Open Translator',
  ),
  ```

### 4.2 Test the Integration
- [ ] Run: `flutter pub get`
- [ ] Build: `flutter build apk` or `flutter run`
- [ ] Tap the translator button
- [ ] Verify web page loads

---

## Phase 5: Platform Configuration

### Android
- [ ] No additional configuration needed for webview_flutter

### iOS
- [ ] Update `ios/Runner/Info.plist`:
  ```xml
  <key>NSLocalNetworkUsageDescription</key>
  <string>Allow access to local network for translator</string>
  <key>NSBonjourServices</key>
  <array>
    <string>_http._tcp</string>
    <string>_https._tcp</string>
  </array>
  ```

### Web (if publishing as web app)
- [ ] Already supports web

---

## Phase 6: Testing

### Local Development Testing
- [ ] In `translate-master/` folder, run: `npm start`
- [ ] This starts local server at `http://localhost:4200`
- [ ] Update `sign_mt_config.dart`:
  ```dart
  static const String translatorWebUrl = 'http://10.0.2.2:4200'; // Android emulator
  // OR
  static const String translatorWebUrl = 'http://192.168.x.x:4200'; // Physical device (use your IP)
  ```
- [ ] Test on emulator/device
- [ ] Switch back to production URL when done

### Production Testing
- [ ] Test with actual Firebase/hosted URL
- [ ] Test on multiple devices
- [ ] Test camera/microphone permissions
- [ ] Test with slow internet connection

---

## Phase 7: Advanced Setup (Optional)

### Enable Backend API Integration
- [ ] Build Firebase functions (in `translate-master/functions/`):
  ```bash
  cd translate-master/functions
  npm install
  firebase deploy --only functions
  ```
- [ ] Use `SignTranslatorService` to call backend APIs instead of just WebView

### Implement Caching
- [ ] Add local caching of translations
- [ ] See `SignTranslatorService` for cache configuration

### Analytics Integration
- [ ] Track when users open translator
- [ ] Track translation success/failures
- [ ] See `SignMtConfig` for analytics event names

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| WebView shows blank page | Check URLs in config, verify Firebase deployment |
| Camera doesn't work | Grant camera permissions, check browser console |
| App is too large | Use remote hosting instead of embedding locally |
| CORS errors | Backend needs proper headers, or use CORS proxy |
| Slow loading | Use Firebase CDN, optimize images, minify assets |
| App crashes on Android | Update webview_flutter, check API level |

---

## Environment Setup Commands

### Quick Start (For Impatient Devs)
```bash
# Build web app
cd HandyLingoMobile\translate-master
npm install && npm run build

# Deploy to Firebase
firebase deploy --only hosting

# Update Flutter config
# Edit lib/config/sign_mt_config.dart with your Firebase URL
# Add dependencies and build

cd ..\handylingo
flutter pub get
flutter run
```

---

## What Each File Does

| File | Purpose |
|------|---------|
| `sign_translator_service.dart` | HTTP client for API calls to translator backend |
| `sign_mt_translator_page.dart` | Flutter page that displays translator in WebView |
| `sign_mt_config.dart` | Centralized configuration for translator settings |
| `sign_translator_integration_example.dart` | Complete example of how to use the translator |
| `SIGN_MT_SETUP.md` | Detailed setup documentation |

---

## Next Steps After Integration

1. ✅ **Immediate**: Get the web app building and deployed
2. ✅ **Then**: Test WebView integration
3. 🔄 **Later**: Implement backend API calls for better performance
4. 🔄 **Later**: Add caching and offline support
5. 🔄 **Later**: Implement analytics
6. 🔄 **Later**: Fine-tune UI/UX in start_using.dart

---

## Support Resources

- [sign.mt GitHub](https://github.com/sign/translate)
- [WebView Flutter Docs](https://pub.dev/packages/webview_flutter)
- [Firebase Hosting Guide](https://firebase.google.com/docs/hosting)
- [Flutter Web Docs](https://flutter.dev/web)

---

## Notes

- Keep the `translate-master` folder separate from the mobile app
- Update URLs in config when moving between development/production
- Test on both Android and iOS (if available)
- Monitor app size - may need to use remote hosting instead of local assets

---

**Last Updated**: 2026-02-22
**Tested With**: Flutter 3.10+, sign.mt v0.0.4
