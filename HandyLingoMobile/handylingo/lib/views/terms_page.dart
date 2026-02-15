import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms of Use',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Use',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: February 10, 2026',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to HandyLingo (the "App"), an application designed to convert sign language to text and/or audio speech, and to convert text and/or audio speech into sign language representations. These Terms of Use ("Terms") govern your access to and use of the App. By accessing or using the App, you agree to be bound by these Terms.',
              style: GoogleFonts.inter(height: 1.6),
            ),
            const SizedBox(height: 16),
            Text(
              'If you do not agree to these Terms, please do not use the App.',
              style: GoogleFonts.inter(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Eligibility',
              'You must be at least 13 years old (or the minimum age required in your country) to use the App. By using the App, you represent and warrant that you meet this requirement.',
            ),
            _buildSection(
              '2. Purpose of the App',
              'The App is intended to assist with communication by translating between sign language and text and/or audio speech.\n\nImportant Disclaimer:\n• The App is provided for assistive and informational purposes only.\n• Translations may not always be accurate, complete, or appropriate for all contexts.\n• The App is not a substitute for professional human interpreters, especially in legal, medical, educational, or emergency situations.',
            ),
            _buildSection(
              '3. User Responsibilities',
              'You agree to:\n• Use the App in a lawful and respectful manner.\n• Not misuse the App for illegal, harmful, or abusive activities.\n• Not rely on the App for critical communications where errors could result in harm.\n• Ensure that you have permission to record, upload, or process any audio, video, or image content involving other individuals.\n\nYou are solely responsible for how you use the App and for any consequences resulting from its use.',
            ),
            _buildSection(
              '4. Content and Data Processing',
              'The App may process video/image data of sign language gestures, audio recordings, and text input. You retain ownership of your content.\n\nYour use of the App is also governed by our Privacy Policy, which explains how we collect, use, and protect your data.',
            ),
            _buildSection(
              '5. Accuracy and Limitations',
              'You acknowledge that:\n• Sign language varies by region, culture, and individual usage.\n• Machine-based translations may contain errors or misinterpretations.\n• Background noise, lighting, camera angle, and clarity of gestures may affect accuracy.\n\nWe do not guarantee the accuracy, reliability, or availability of any translation produced by the App.',
            ),
            _buildSection(
              '6. Prohibited Uses',
              'You may not:\n• Use the App to harass, discriminate, or harm others.\n• Attempt to reverse engineer, copy, or resell the App or its technology.\n• Interfere with the App\'s security, servers, or networks.\n• Use the App in emergencies or high-risk scenarios where accurate communication is essential.',
            ),
            _buildSection(
              '7. Intellectual Property',
              'All intellectual property rights in the App, including software, models, designs, logos, and trademarks, are owned by or licensed to HandyLingo. You are granted a limited, non-transferable, revocable license to use the App in accordance with these Terms.',
            ),
            _buildSection(
              '8. Third-Party Services',
              'The App may integrate with third-party services (such as speech recognition, text-to-speech, or cloud processing providers). We are not responsible for the availability or accuracy of these third-party services.',
            ),
            _buildSection(
              '9. Termination',
              'We may suspend or terminate your access to the App at any time if you violate these Terms or misuse the App.\n\nYou may stop using the App at any time.',
            ),
            _buildSection(
              '10. Disclaimer of Warranties',
              'The App is provided "AS IS" and "AS AVAILABLE", without warranties of any kind, express or implied, including but not limited to warranties of accuracy, fitness for a particular purpose, or non-infringement.',
            ),
            _buildSection(
              '11. Limitation of Liability',
              'To the maximum extent permitted by law, HandyLingo shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of data, miscommunication, or personal or business harm resulting from use of the App.',
            ),
            _buildSection(
              '12. Accessibility Statement',
              'We are committed to improving accessibility and inclusivity. While the App aims to support accessible communication, we acknowledge that no automated system is perfect and welcome feedback for improvement.',
            ),
            _buildSection(
              '13. Changes to These Terms',
              'We may update these Terms from time to time. Continued use of the App after changes are posted constitutes acceptance of the updated Terms.',
            ),
            _buildSection(
              '14. Governing Law',
              'These Terms shall be governed by and construed in accordance with applicable laws, without regard to conflict of law principles.',
            ),
            _buildSection(
              '15. Contact Information',
              'If you have questions about these Terms, please contact us at:\n\nEmail: support@handylingo.com',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This Terms of Use is provided for general informational purposes and does not constitute legal advice.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.inter(height: 1.6, color: Colors.black87),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
