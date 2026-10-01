import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibcjj_flutter/core/errors/app_failure.dart';
import 'package:ibcjj_flutter/features/auth/data/firebase_auth_repository.dart';

class SdkUser extends Fake implements User {
  @override
  String get uid => 'uid';
  @override
  String get email => 'user@example.com';
}

class SdkCredential extends Fake implements UserCredential {
  @override
  User get user => SdkUser();
}

class SdkAuth extends Fake implements FirebaseAuth {
  FirebaseAuthException? error;
  String? passwordReceived;
  @override
  Stream<User?> authStateChanges() =>
      Stream.fromIterable([null, SdkUser(), null]);
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    passwordReceived = password;
    if (error != null) throw error!;
    return SdkCredential();
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      signInWithEmailAndPassword(email: email, password: password);
  @override
  Future<void> signOut() async {
    if (error != null) throw error!;
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    if (error != null) throw error!;
  }
}

void main() {
  test('adapter exposes domain sessions and signed-out events', () async {
    final repository = FirebaseAuthRepository(SdkAuth());
    final sessions = await repository.sessionChanges.toList();
    expect(sessions.first, isNull);
    expect(sessions[1]!.uid, 'uid');
    expect(sessions[1]!.email, 'user@example.com');
    expect(sessions.last, isNull);
  });

  test(
      'login and registration return domain identities without trimming passwords',
      () async {
    final sdk = SdkAuth();
    final repository = FirebaseAuthRepository(sdk);
    expect(
        (await repository.login('user@example.com', ' password ')).uid, 'uid');
    expect(sdk.passwordReceived, ' password ');
    expect(
        (await repository.register('user@example.com', 'password')).uid, 'uid');
  });

  test('SDK failures map to user-facing errors, not raw backend messages',
      () async {
    final sdk = SdkAuth()
      ..error = FirebaseAuthException(
          code: 'invalid-credential', message: 'private backend detail');
    final repository = FirebaseAuthRepository(sdk);
    await expectLater(
        repository.login('user@example.com', 'wrong'),
        throwsA(isA<AppFailure>().having(
            (e) => e.message, 'message', 'E-mail ou senha inválidos.')));
    await expectLater(repository.logout(), throwsA(isA<AppFailure>()));
    await expectLater(repository.resetPassword('user@example.com'),
        throwsA(isA<AppFailure>()));
  });
}
