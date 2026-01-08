import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/Sign_in.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  late final StreamSubscription<AuthState> _authSubscription;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();

    // 2. Listen for Auth State Changes
    // This triggers automatically when the user clicks the "Verify" button in their email
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (_redirecting) return;
      
      final session = data.session;
      final event = data.event;

      // When the user is signed in (via deep link or login)
      if (event == AuthChangeEvent.signedIn && session != null) {
        _redirecting = true;
        
        // Navigate to your Home/Dashboard screen
        // Replace 'HomeView()' with your actual home widget
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
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
    return MaterialApp(
      title: 'HandyLingo',
      debugShowCheckedModeBanner: false,
      // 4. Attach the navigator key
      navigatorKey: navigatorKey, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // 5. Define your routes
      initialRoute: '/',
      routes: {
        '/': (context) => const Sign_in(),
        // Define your home route here
        '/home': (context) => const Sign_in(),
      },
    );
  }
}