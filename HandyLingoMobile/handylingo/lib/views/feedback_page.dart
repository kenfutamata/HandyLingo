import 'package:flutter/material.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int _rating = 3;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFDFF3F6);
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FEEDBACK',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 16),
              const Text('How did we do?'),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (index) {
                  final i = index + 1;
                  final selected = i <= _rating;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _rating = i),
                      child: Icon(
                        Icons.star,
                        size: 34,
                        color: selected ? Colors.amber : Colors.black87,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              const Text('Care to share more about it?'),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(minHeight: 180),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  border: Border.all(color: Colors.black54),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  minLines: 8,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    hintText: 'Type here . . .',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 240,
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.brown.shade700, width: 1),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () {
                      final text = _controller.text.trim();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Thanks for your feedback.')),
                      );
                      // TODO: send feedback to backend
                      setState(() => _controller.clear());
                    },
                    child: const Text(
                      'Submit',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
