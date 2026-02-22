/// Avatar style enum
enum AvatarStyle { skeleton, poseSequence, humanoidGan }

/// Configuration for Sign.MT translator integration
class SignMtConfig {
  /// Base URL for the translator web interface
  /// Update this based on your hosting choice:
  /// - Local: 'file:///flutter_assets/sign_translator/index.html'
  /// - Firebase Hosting: 'https://your-project.web.app'
  /// - Custom Server: 'https://your-domain.com'
  /// - Development: 'http://localhost:4200'
  static const String translatorWebUrl = 'http://10.0.2.2:4200';

  /// API base URL for REST calls
  /// Used by SignTranslatorService for backend translation requests
  static const String translatorApiUrl = 'https://sign.mt/api';

  /// Map of supported sign languages
  /// Key: code (asl, bsl, lsf, etc.)
  /// Value: display name
  static const Map<String, String> supportedSignLanguages = {
    'asl': 'American Sign Language',
    'bsl': 'British Sign Language',
    'lsf': 'French Sign Language',
    'dgs': 'German Sign Language',
    'ise': 'Italian Sign Language',
  };

  /// Map of supported spoken languages
  static const Map<String, String> supportedSpokenLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
  };

  /// Default configurations
  static const String defaultSignLanguage = 'asl';
  static const String defaultSpokenLanguage = 'en';

  /// API request timeouts
  static const Duration textTranslationTimeout = Duration(seconds: 30);
  static const Duration videoTranslationTimeout = Duration(minutes: 5);
  static const Duration healthCheckTimeout = Duration(seconds: 10);

  /// Feature flags
  static const bool enableOfflineMode =
      false; // Set to true after implementing offline caching
  static const bool enableVideoProcessing = true;
  static const bool enableAvatarGeneration = true;
  static const bool enablePoseVisualization = true;

  /// Cache settings
  static const int cacheMaxAge = 7 * 24 * 60 * 60; // 7 days in seconds
  static const int maxCachedTranslations = 500;

  /// Error handling
  static const String errorMessageNetworkError =
      'Network error. Please check your connection and try again.';
  static const String errorMessageServerError =
      'Translation service is temporarily unavailable.';
  static const String errorMessageTimeoutError =
      'Request timed out. Please try again.';

  /// Default avatar style
  static const AvatarStyle defaultAvatarStyle = AvatarStyle.skeleton;

  /// Analytics event names
  static const String analyticsTextToSignEvent = 'text_to_sign_translation';
  static const String analyticsSignToSignEvent = 'sign_to_speech_translation';
  static const String analyticsTranslatorOpenedEvent =
      'sign_mt_translator_opened';
  static const String analyticsTranslationErrorEvent = 'translation_error';

  /// Logging
  static const bool enableDetailedLogging = true;

  /// App integration
  static const String appName = 'HandyLingo';
  static const String translatorUserAgent = 'HandyLingo/$appName';
}
