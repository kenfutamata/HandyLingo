import 'package:flutter/material.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: const Color(0xFF33C7E6),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'This is a placeholder for the account page. You can add profile, settings, and logout here.',
            ),
          ],
        ),
      ),
    );
  }
}
