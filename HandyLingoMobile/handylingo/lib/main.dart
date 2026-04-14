import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your views
import 'views/Sign_in.dart';
import 'views/welcome_dashboard.dart';
import 'views/update_password.dart';
import 'views/start_using.dart';

final ValueNotifier<bool> themeIsLight = ValueNotifier<bool>(true);
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found.");
  }

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
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    
    // Listen for Auth changes (Sign in, Sign out, Password recovery)
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/update-password', (route) => false);
      }
      
      // Note: We don't handle INITIAL_SESSION here because the RootPage 
      // handle the first-load logic more reliably for the UI.
    });
  }

  Future<void> _loadTheme() async {
    final sp = await SharedPreferences.getInstance();
    themeIsLight.value = sp.getBool('white_mode') ?? true;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      scaffoldBackgroundColor: const Color(0xFFEAF8FB),
      useMaterial3: true,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F1720),
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
          // Change the initial route to a gatekeeper widget
          home: const AuthGate(),
          routes: {
            '/login': (context) => const Sign_in(),
            '/home': (context) => const WelcomeDashboard(),
            '/start-using': (context) => const StartUsingPage(),
            '/update-password': (context) => const UpdatePassword(),
          },
        );
      },
    );
  }
}

/// This Widget determines where the user should land when the app starts.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    // 1. If no session exists, go to Sign In page.
    if (session == null) {
      return const Sign_in();
    }

    // 2. If session exists, check the login count from SharedPreferences.
    return FutureBuilder<int>(
      future: _getLoginCount(session.user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final loginCount = snapshot.data ?? 0;

        if (loginCount > 1) {
          return const StartUsingPage();
        } else {
          return const WelcomeDashboard();
        }
      },
    );
  }

  Future<int> _getLoginCount(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('login_count_$userId') ?? 0;
  }
}