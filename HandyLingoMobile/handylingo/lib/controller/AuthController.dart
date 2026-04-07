import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sends a password reset link to the user's email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.example.handylingo://login-callback',
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Triggers the Google OAuth sign-in flow.
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // This must match the redirect URL configured in your Supabase dashboard
        redirectTo: 'com.example.handylingo://login-callback',
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  /// Registers a new user with additional metadata.
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
        emailRedirectTo: 'com.example.handylingo://login-callback',
        data: {
          'user_name': userName,
          'first_name': firstName,
          'last_name': lastName,
          'role': 'user',
          'status': 'active',
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

  /// Signs in a user using either email or username.
  /// Returns a map containing role, id, and email on success.
  Future<Map<String, String?>> signIn({
    required String credential,
    required String password,
  }) async {
    try {
      String? email;
      String? role;
      String? id;

      final isEmail = credential.contains('@');

      // 1. Resolve Email if username was provided
      if (isEmail) {
        email = credential;
      } else {
        final userRow = await _supabase
            .from('users')
            .select('id, email, role')
            .eq('user_name', credential)
            .maybeSingle();

        if (userRow == null) {
          throw Exception('No user found with that username.');
        }
        email = userRow['email'] as String?;
        role = userRow['role'] as String?;
        id = userRow['id']?.toString();
      }

      if (email == null) {
        throw Exception('Could not identify email for login.');
      }

      // 2. Perform Sign In
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.session == null) {
        throw Exception('Invalid credentials');
      }

      // 3. Fetch Role/ID if not already fetched (for email logins)
      if (role == null || id == null) {
        final userId = res.user?.id;
        final userRow = await _supabase
            .from('users')
            .select('id, email, role')
            .eq('id', userId!)
            .maybeSingle();
        if (userRow != null) {
          role = userRow['role'] as String?;
          id = userRow['id']?.toString();
        }
      }

      return {'role': role ?? 'user', 'id': id, 'email': email};
      
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error during sign in: $e');
    }
  }
}

// Global Provider
final authRepositoryProvider = Provider<AuthController>((ref) {
  return AuthController();
});