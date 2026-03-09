import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your views
import 'views/Sign_in.dart';
import 'views/welcome_dashboard.dart';

// Global notifier for theme state
final ValueNotifier<bool> themeIsLight = ValueNotifier<bool>(true);

// Global navigator key for redirection from Auth listener
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // 1. Crucial for Camera, WebView, and SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found. Ensure it exists in project root.");
  }

  // 3. Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();

    // 4. Load stored theme preference
    _loadTheme();

    // 5. Listen for Auth State Changes (Handles Magic Links/Email Verification)
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;

      if (_redirecting) return;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _redirecting = true;
        
        // Use a small delay to ensure the Navigator is mounted
        Future.delayed(Duration.zero, () {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        });
      }
    });
  }

  Future<void> _loadTheme() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final val = sp.getBool('white_mode') ?? true;
      themeIsLight.value = val;
    } catch (e) {
      debugPrint("Theme load error: $e");
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define Themes
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      scaffoldBackgroundColor: const Color(0xFFEAF8FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFEAF8FB),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      useMaterial3: true,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F1720),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F1720),
        elevation: 0,
      ),
      useMaterial3: true,
    );

    return ValueListenableBuilder<bool>(
      valueListenable: themeIsLight,
      builder: (context, isLight, _) {
        return MaterialApp(
          title: 'HandyLingo',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
          initialRoute: '/',
          routes: {
            '/': (context) => const Sign_in(),
            '/home': (context) => const WelcomeDashboard(),
          },
        );
      },
    );
  }
}