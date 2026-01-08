import 'package:flutter/material.dart';
import 'user_guide.dart';
import 'start_using.dart';

class WelcomeDashboard extends StatelessWidget {
  const WelcomeDashboard({Key? key}) : super(key: key);

  static const Color _bg = Color(0xFFEAF8FB); // light cyan background
  static const Color _primary = Color(0xFF33C7E6); // main cyan color
  static const Color _accentText = Color(0xFF104E54); // darker accent for text

  Widget _featureTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // logo circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pan_tool, // hand-like icon
                  color: Colors.white,
                  size: 64,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Welcome to Handylingo!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _accentText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Breaking communication barriers with sign language',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _accentText.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Features
              _featureTile(
                Icons.videocam,
                'Sign Language to Text/Audio',
                'Convert sign language gestures into text or speech',
              ),
              _featureTile(
                Icons.chat_bubble,
                'Text to Sign Language',
                'Type messages and see them translated to sign language',
              ),
              _featureTile(
                Icons.mic,
                'Speech to Sign Language',
                'Speak and watch it converted to sign language animations',
              ),

              const Spacer(),

              // User Guide (outlined)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: _accentText.withOpacity(0.12)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UserGuidePage()),
                    );
                  },
                  child: Text(
                    'User Guide',
                    style: TextStyle(color: _accentText, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Start Using Handylingo (filled)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StartUsingPage()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Start Using Handylingo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}
