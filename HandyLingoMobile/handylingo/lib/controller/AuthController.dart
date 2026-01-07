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
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'user_name': userName,
          'first_name': firstName,
          'last_name': lastName,
          'role': 'user',
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      if (res.user == null) {
        throw Exception('Sign up failed');
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error during sign up: $e');
    }
  }
}

final authRepositoryProvider = Provider<AuthController>((ref) {
  return AuthController();
});
