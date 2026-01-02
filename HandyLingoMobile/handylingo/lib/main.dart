import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/Sign_in.dart'; // Ensure this path is correct

void main() {
  runApp(
    // ProviderScope must wrap the MaterialApp
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HandyLingo',
      debugShowCheckedModeBanner: false, // Optional: removes the debug banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Set Sign_in as the starting page
      home: const Sign_in(), 
    );
  }
}