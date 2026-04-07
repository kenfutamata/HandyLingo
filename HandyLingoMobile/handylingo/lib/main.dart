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
import 'views/start_using.dart'; // NEW IMPORT

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
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final event = data.event;

      if (_redirecting) return;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _redirecting = true;
        
        // --- LOGIN COUNT LOGIC ---
        final prefs = await SharedPreferences.getInstance();
        final userId = session.user.id;
        int loginCount = prefs.getInt('login_count_$userId') ?? 0;
        
        // Increment and save
        loginCount++;
        await prefs.setInt('login_count_$userId', loginCount);

        Future.delayed(Duration.zero, () {
          if (loginCount > 1) {
            // Returning user
            navigatorKey.currentState?.pushNamedAndRemoveUntil('/start-using', (route) => false);
          } else {
            // First time user
            navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
          }
        });
      }

      if (event == AuthChangeEvent.passwordRecovery) {
        _redirecting = true;
        Future.delayed(Duration.zero, () {
          navigatorKey.currentState?.pushNamedAndRemoveUntil('/update-password', (route) => false);
        });
      }
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
          initialRoute: '/',
          routes: {
            '/': (context) => const Sign_in(),
            '/home': (context) => const WelcomeDashboard(),
            '/start-using': (context) => const StartUsingPage(), // REGISTERED ROUTE
            '/update-password': (context) => const UpdatePassword(),
          },
        );
      },
    );
  }
}