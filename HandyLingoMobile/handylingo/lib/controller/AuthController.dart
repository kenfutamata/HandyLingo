import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> signUp({
    required String userName,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Auth first
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      // 2. Insert into your table immediately after
      await _supabase.from('users').insert({
        'id': res.user!.id,
        'user_name': userName,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      });

      if (res.user == null) {
        throw Exception('Sign up failed');
      }
    } catch (e) {
      throw Exception('Error during sign up: $e');
    }
  }
}

final authRepositoryProvider = Provider<AuthController>((ref) {
  return AuthController();
});
