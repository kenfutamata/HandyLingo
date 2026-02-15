import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// The new NotifierProvider syntax for Riverpod 3.x
final feedbackNotifierProvider = NotifierProvider<FeedbackNotifier, AsyncValue<void>>(() {
  return FeedbackNotifier();
});

class FeedbackNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    // Initial state: data is null (idle)
    return const AsyncValue.data(null);
  }

  Future<bool> submitFeedback({required int rating, required String comment}) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    // Set state to loading
    state = const AsyncLoading();

    // Perform operation
    state = await AsyncValue.guard(() async {
      await client.from('feedbacks').insert({
        'user_id': user.id,
        'first_name': user.userMetadata?['first_name'] ?? '',
        'last_name': user.userMetadata?['last_name'] ?? '',
        'email': user.email ?? '',
        'message': comment,
        'feedback_type': 'App Feedback',
        'rating': rating,
      });
    });

    return !state.hasError;
  }
}