import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: const Color(0xFF33C7E6),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'About us placeholder. Add details about the app and the team here.',
        ),
      ),
    );
  }
}
