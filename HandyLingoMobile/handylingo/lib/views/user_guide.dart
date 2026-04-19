import 'package:flutter/material.dart';

class UserGuidePage extends StatelessWidget {
  const UserGuidePage({super.key});

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String label, String assetName) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              assetName,
              fit: BoxFit.fitWidth,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionSection(String title, List<String> instructions, String imageAsset) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        _buildImageCard('Screenshot showing $title', imageAsset),
        const SizedBox(height: 12),
        ...instructions.map((instruction) => _buildBullet(instruction)),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('User Guide'),
        backgroundColor: const Color(0xFF33C7E6),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Using Translation Modes'),
              const Text(
                'HandyLingo features two primary modes of communication which can be toggled using the "SL/3D Switch" located on the bottom navigation bar.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              _buildImageCard('Main screen showing translation mode options', 'assets/images/SL3D_mode.png'),
              const SizedBox(height: 20),

              _buildInstructionSection(
                'Sign Language to Text/Audio',
                [
                  'In this mode, position your phone camera to face the person signing.',
                  'Ensure the mode is set to "ASL/FSL - Ready."',
                  'Click "CAPTURE SIGN" to begin the real-time translation into text or audio output.',
                ],
                'assets/images/SL_mode.png',
              ),

              _buildInstructionSection(
                'Text/Speech to Sign Language',
                [
                  'Switch to the 3D mode to translate spoken or written language into signs.',
                  'Type your message into the text bar or click the Microphone icon in your keyboard to use voice input.',
                  'A Skeletal 3D Model will appear on the screen to perform the sign language gestures corresponding to your input.',
                  'There is a microphone button that you can use to enter words/phrases through speech.',
                  'To repeat the 3D skeletal sign language, click the play button after the first sign language action is performed.',
                ],
                'assets/images/3D_mode.jpg',
              ),

              _buildInstructionSection(
                'Replay Button Usage',
                [
                  'After entering text or speech input, the 3D skeletal model will perform the sign language.',
                  'To replay the sign language animation, click the replay button that appears.',
                  'The replay button allows you to watch the sign language gestures again.',
                ],
                'assets/images/3D_mode_replay_button.jpg',
              ),

              _buildInstructionSection(
                'Account and Settings',
                [
                  'Tap the "Account" icon in the bottom navigation bar to open your profile and settings.',
                  'Edit Profile: update your personal information and profile picture.',
                  'Preferences: toggle Email Notifications, adjust Text Size (Small, Medium, Large), and switch between White Mode and Dark Mode.',
                  'Audio: enable or disable the "Voice" feature for audio translations.',
                  'Help: access Frequently Asked Questions, send feedback, or reopen the User Guide from the Help section.',
                  'Logout: securely sign out of your account at the bottom of the settings page.',
                ],
                'assets/images/account_settings1.jpg',
              ),
              _buildImageCard(
                'Help and Preferences screen in account settings.',
                'assets/images/account_settings2.jpg',
              ),

              const SizedBox(height: 24),
              const Text(
                'Tip: Use the bottom navigation bar to switch quickly between sign capture, 3D translation, and account settings.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
