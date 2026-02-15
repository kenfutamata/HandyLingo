import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:handylingo/controller/FeedbackController.dart';

class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key});

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  int _rating = 3;
  final TextEditingController _controller = TextEditingController();

  Future<void> _handleSubmit() async {
    final comment = _controller.text.trim();
    if (comment.isEmpty) return;

    // Use the notifier to submit
    final success = await ref
        .read(feedbackNotifierProvider.notifier)
        .submitFeedback(rating: _rating, comment: comment);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted!')),
      );
      _controller.clear();
      setState(() => _rating = 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the state (AsyncValue)
    final feedbackState = ref.watch(feedbackNotifierProvider);
    final isLoading = feedbackState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFDFF3F6),
      appBar: AppBar(title: const Text('Feedback'), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Rate your experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: isLoading ? null : () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: index < _rating ? Colors.amber : Colors.grey,
                    size: 35,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 5,
              enabled: !isLoading,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Tell us more...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                onPressed: isLoading ? null : _handleSubmit,
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Submit', style: TextStyle(color: Colors.white)),
              ),
            ),
            if (feedbackState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('${feedbackState.error}', style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}