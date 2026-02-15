import 'package:flutter/material.dart';

class AppVersionEditPage extends StatelessWidget {
  const AppVersionEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit App Version')),
      body: const Center(child: Text('Admin-only: change app version here')),
    );
  }
}
