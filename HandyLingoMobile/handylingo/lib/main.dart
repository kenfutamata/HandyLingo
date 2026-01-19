import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/Sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/welcome_dashboard.dart';

// Simple global notifier used for theme state (avoids unresolved StateProvider error in some analyzer setups)
final ValueNotifier<bool> themeIsLight = ValueNotifier<bool>(true);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final StreamSubscription<AuthState> _authSubscription;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();

    // Load stored theme preference and update the global notifier
    Future.microtask(() async {
      try {
        final sp = await SharedPreferences.getInstance();
        final val = sp.getBool('white_mode') ?? true;
        themeIsLight.value = val;
      } catch (_) {}
    });

    // 2. Listen for Auth State Changes
    // This triggers automatically when the user clicks the "Verify" button in their email
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (_redirecting) return;

      final session = data.session;
      final event = data.event;

      // When the user is signed in (via deep link or login)
      if (event == AuthChangeEvent.signedIn && session != null) {
        _redirecting = true;

        // Navigate to your Home/Dashboard screen
        // Replace 'HomeView()' with your actual home widget
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    // 3. Clean up the subscription when the app is closed
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      scaffoldBackgroundColor: const Color(0xFFEAF8FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFEAF8FB),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      useMaterial3: true,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
      ),
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F1720),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F1720),
        elevation: 0,
      ),
      useMaterial3: true,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
      ),
    );

    return ValueListenableBuilder<bool>(
      valueListenable: themeIsLight,
      builder: (context, isLight, _) {
        return MaterialApp(
          title: 'HandyLingo',
          debugShowCheckedModeBanner: false,
          // 4. Attach the navigator key
          navigatorKey: navigatorKey,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
          // 5. Define your routes
          initialRoute: '/',
          routes: {
            '/': (context) => const Sign_in(),
            // Define your home route here
            '/home': (context) => const Sign_in(),
          },
        );
      },
    );
  }
}
