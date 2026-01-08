import 'package:flutter/material.dart';

class StartUsingPage extends StatelessWidget {
  const StartUsingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Handylingo'),
        backgroundColor: const Color(0xFF33C7E6),
        elevation: 0,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Start Using Handylingo placeholder. This page will be replaced by the main app landing page later.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
