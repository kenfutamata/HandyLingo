import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'AuthController.dart';

class SignUpController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        userName: username,
      );
    });
  }
}

final signUpControllerProvider =
    AsyncNotifierProvider.autoDispose<SignUpController, void>(
  () => SignUpController(),
);
