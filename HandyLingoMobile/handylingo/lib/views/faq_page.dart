import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Frequently Asked Questions',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    Text(
                      'Last Updated: February 10, 2026',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFaqItem(
                      1,
                      'What does this app do?',
                      'The app translates sign language into text and/or audio speech, and text and/or audio speech into sign language representations to support communication between deaf, hard-of-hearing, and hearing users.',
                    ),
                    _buildFaqItem(
                      2,
                      'Which sign languages are supported?',
                      'Supported sign languages may vary depending on region and development stage (for example: ASL, BSL, ISL, etc.). Availability may expand over time.\n\nBecause sign languages differ by country, region, and culture, translations may not always be exact.',
                    ),
                    _buildFaqItem(
                      3,
                      'How accurate are the translations?',
                      'While we strive for high accuracy, no automated system is perfect.\n\nAccuracy may be affected by:\n• Lighting and camera angle\n• Clarity and speed of signing\n• Background noise (for audio input)\n• Regional or personal variations in sign language\n\nFor critical situations (medical, legal, emergency), we strongly recommend using a qualified human interpreter.',
                    ),
                    _buildFaqItem(
                      4,
                      'Is this app a replacement for a human sign language interpreter?',
                      'No. The app is designed as an assistive communication tool, not a replacement for professional interpreters.',
                    ),
                    _buildFaqItem(
                      5,
                      'Does the app record or store my video and audio?',
                      'This depends on how the app is configured:\n\n• Some data may be processed temporarily to provide translations\n• Data handling practices are fully explained in our Privacy Policy\n\nWe encourage you to review the Privacy Policy to understand how your data is used and protected.',
                    ),
                    _buildFaqItem(
                      6,
                      'Who can use the app?',
                      'Anyone who meets the minimum age requirement and agrees to the Terms of Use can use the app, including:\n\n• Deaf and hard-of-hearing users\n• Hearing users communicating with sign language users\n• Students, educators, and families',
                    ),
                    _buildFaqItem(
                      7,
                      'Is the app free to use?',
                      'The app may offer free features and additional premium options. Check the app store or pricing section for current details.',
                    ),
                    _buildFaqItem(
                      8,
                      'Can I use the app offline?',
                      'Some features may require an internet connection, especially those involving real-time translation or cloud processing.\n\nOffline functionality, if available, will be clearly indicated in the app.',
                    ),
                    _buildFaqItem(
                      9,
                      'How do I report errors or suggest improvements?',
                      'We welcome feedback!\n\nYou can:\n• Use the in-app feedback option\n• Contact our support team via email: support@handylingo.com\n\nYour feedback helps improve accuracy, accessibility, and user experience.',
                    ),
                    _buildFaqItem(
                      10,
                      'Is the app accessible?',
                      'Accessibility is a core goal of the app. We aim to support:\n\n• Clear visual design\n• Readable text and captions\n• Assistive communication needs\n\nWe continue to improve accessibility and appreciate user feedback.',
                    ),
                    _buildFaqItem(
                      11,
                      'Can children use the app?',
                      'Children may use the app with parental or guardian consent, subject to local laws and age requirements.',
                    ),
                    _buildFaqItem(
                      12,
                      'What devices are supported?',
                      'The app is available on supported smartphones or tablets. Device compatibility may vary based on hardware capabilities such as camera and microphone quality.',
                    ),
                    _buildFaqItem(
                      13,
                      'What should I do if the app is not working correctly?',
                      'Try the following steps:\n\n• Check your internet connection\n• Ensure camera and microphone permissions are enabled\n• Update the app to the latest version\n\nIf issues persist, contact support.',
                    ),
                    _buildFaqItem(
                      14,
                      'Can the Terms of Use change?',
                      'Yes. The Terms of Use may be updated from time to time. When changes are made, users will be notified as required, and continued use of the app indicates acceptance of the updated terms.',
                    ),
                    _buildFaqItem(
                      15,
                      'How can I contact you?',
                      'If you have questions or concerns:\n\nEmail: support@handylingo.com',
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(int number, String question, String answer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          '$number. $question',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              answer,
              style: GoogleFonts.inter(height: 1.6, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
