import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About us'),
        backgroundColor: const Color(0xFF33C7E6),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Us',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'HandyLingo is an AI-powered mobile application developed as a Capstone Project with the mission of making communication more inclusive and accessible. The application translates sign language into text and audio speech, and converts text or spoken language into sign language representations, helping bridge the communication gap between deaf, hard-of-hearing, and hearing individuals.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Our project was created in response to the everyday challenges faced by persons with hearing barriers. Communication barriers can affect access to education, healthcare, employment, and social interaction. HandyLingo aims to reduce these barriers by providing a practical, portable, and user-friendly assistive tool that supports real-time communication.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'By integrating artificial intelligence, computer vision, and speech processing technologies, HandyLingo works to recognize sign gestures accurately and generate understandable text or audio output. Likewise, it transforms spoken or written language into visual sign-based output to promote two-way communication.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'As a student-led Capstone Project, HandyLingo reflects our commitment to innovation, accessibility, and social impact. We believe technology should empower communities and create equal opportunities for everyone.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'We continue to improve the system through research, user feedback, and technological advancements, striving to make HandyLingo more accurate, reliable, and inclusive for diverse sign language users.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Our Vision',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'To create a world where communication barriers no longer limit opportunities for people with hearing impairments.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Our Mission',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'To develop accessible, intelligent, and user-centered technology that promotes inclusive communication for all.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
