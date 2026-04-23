import 'dart:convert'; // Import required for jsonEncode
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
      
      // 1. Insert the feedback into the feedbacks table
      await client.from('feedbacks').insert({
        'user_id': user.id,
        'first_name': user.userMetadata?['first_name'] ?? '',
        'last_name': user.userMetadata?['last_name'] ?? '',
        'email': user.email ?? '',
        'message': comment,
        'feedback_type': 'App Feedback',
        'rating': rating,
      });

      // 2. Insert a notification into the notifications table
      // (Assuming your table name is 'notifications')
      await client.from('notifications').insert({
        // 'id' is omitted assuming your database auto-generates the UUID (e.g. gen_random_uuid())
        'type': 'Feedback_Submitted', // varchar (NON-NULLABLE)
        
        // 'data' is a text field. Storing JSON as a string is the standard approach here
        'data': jsonEncode({
          'title': 'Feedback Received',
          'body': 'Thank you for your feedback! We appreciate your input.',
          'rating_given': rating,
        }), 
        
        // Polimorphic relations (NON-NULLABLE)
        'notifiable_type': 'User', // Indicates this notification belongs to a User
        'notifiable_id': user.id,  // The UUID of the user receiving the notification
        
        // read_at, created_at, and updated_at are NULLABLE so we let the database handle them 
        // (usually they default to NULL and now() respectively).
      });
      
    });

    return !state.hasError;
  }
}