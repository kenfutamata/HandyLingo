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
  /// Returns a map containing at least `role`, `id`, and `email` on success.
  Future<Map<String, String?>> signIn({
    required String credential,
    required String password,
  }) async {
    try {
      // Determine if credential is an email or username
      String? email;
      String? role;
      String? id;

      final isEmail = credential.contains('@');

      // First attempt: if credential looks like an email, try signing in directly
      if (isEmail) {
        email = credential;
        try {
          final res = await _supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );

          if (res.session == null) {
            throw Exception('Invalid credentials');
          }

          // Fetch role and id from users table using auth user id
          final userId = res.user?.id;
          if (userId != null) {
            final userRow = await _supabase
                .from('users')
                .select('id, email, role')
                .eq('id', userId)
                .maybeSingle();
            if (userRow != null) {
              role = userRow['role'] as String?;
              id = userRow['id']?.toString();
            }
          }

          return {'role': role ?? 'user', 'id': id, 'email': email};
        } on AuthException catch (e) {
          throw Exception(e.message);
        }
      }

      // If credential is not an email, first try signing in using it as an email (rare but possible)
      try {
        final res = await _supabase.auth.signInWithPassword(
          email: credential,
          password: password,
        );

        if (res.session != null) {
          // fetched by treating credential as email
          final userId = res.user?.id;
          String? foundEmail = credential;
          if (userId != null) {
            final userRow = await _supabase
                .from('users')
                .select('id, email, role')
                .eq('id', userId)
                .maybeSingle();
            if (userRow != null) {
              role = userRow['role'] as String?;
              id = userRow['id']?.toString();
              foundEmail = userRow['email'] as String? ?? foundEmail;
            }
          }
          return {'role': role ?? 'user', 'id': id, 'email': foundEmail};
        }
      } on AuthException {
        // ignore; proceed to lookup by username and try again
      }

      // credential is a username: try to resolve username -> email
      print('[Auth] Looking up username: $credential');

      var userRow = await _supabase
          .from('users')
          .select('id, email, role')
          .eq('user_name', credential)
          .maybeSingle();

      userRow ??= await _supabase
            .from('users')
            .select('id, email, role')
            .ilike('user_name', credential)
            .maybeSingle();

      userRow ??= await _supabase
            .from('users')
            .select('id, email, role')
            .ilike('user_name', '%$credential%')
            .maybeSingle();

      if (userRow == null) {
        // No matching user found by username. This could also indicate RLS (row-level security) prevents anonymous reads.
        throw Exception(
          'No user found with that username. This may be because the database prevents anonymous lookups; try signing in with your email instead.',
        );
      }

      // Debug: print basic found user info in dev (do NOT log sensitive fields in production)
      print(
        '[Auth] Found user row for username: id=${userRow['id']}, email=${userRow['email']}, role=${userRow['role']}',
      );

      email = userRow['email'] as String?;
      role = userRow['role'] as String?;
      // normalize id to string (UUID or numeric id becomes its String repr)
      id = userRow['id']?.toString();

      if (email == null) {
        throw Exception('No email associated with provided username.');
      }

      // Now try signing in using the resolved email
      try {
        final res = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (res.session == null) {
          throw Exception('Invalid credentials');
        }

        // Ensure role/id are up-to-date from the DB (if missing)
        if (role == null || id == null) {
          final userId = res.user?.id;
          if (userId != null) {
            final userRow2 = await _supabase
                .from('users')
                .select('id, email, role')
                .eq('id', userId)
                .maybeSingle();
            if (userRow2 != null) {
              role = userRow2['role'] as String?;
              id = userRow2['id']?.toString();
            }
          }
        }

        return {'role': role ?? 'user', 'id': id, 'email': email};
      } on AuthException catch (e) {
        throw Exception(e.message);
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error during sign in: $e');
    }
  }
}

final authRepositoryProvider = Provider<AuthController>((ref) {
  return AuthController();
});
