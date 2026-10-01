import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibcjj_flutter/core/errors/app_failure.dart';
import 'package:ibcjj_flutter/features/auth/data/auth_repository.dart';
import 'package:ibcjj_flutter/features/auth/presentation/auth_view_model.dart';
import 'package:ibcjj_flutter/features/profile/models/user_model.dart';
import '../support/repository_fakes.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late AuthViewModel model;
  setUp(() {
    auth = FakeAuthRepository();
    profiles = FakeProfileRepository();
    model = AuthViewModel(auth, profiles);
  });
  tearDown(() async {
    model.dispose();
    await auth.controller.close();
  });

  test('starts loading, then accepts a disconnected session', () {
    expect(model.status, AuthStatus.loading);
    auth.controller.add(null);
    expect(model.status, AuthStatus.disconnected);
    expect(model.session, isNull);
  });

  test('restores a session and profile from the stream', () async {
    auth.controller.add(testSession);
    expect(model.status, AuthStatus.loading);
    await flush();
    expect(model.status, AuthStatus.authenticated);
    expect(model.user!.nome, 'Ana');
    expect(auth.loginCalls, 0);
  });

  test('login success loads profile and preserves password exactly', () async {
    auth.controller.add(null);
    await model.login('ana@example.com', ' password ');
    expect(model.status, AuthStatus.authenticated);
    expect(auth.passwordReceived, ' password ');
    expect(profiles.fetches, 1);
  });

  test('login rejection is an authentication error without a session',
      () async {
    auth.loginError =
        const AppFailure('invalid-credential', 'Credenciais inválidas');
    await model.login('ana@example.com', 'wrong');
    expect(model.status, AuthStatus.error);
    expect(model.failureKind, AuthFailureKind.authentication);
    expect(model.session, isNull);
    expect(model.error, 'Credenciais inválidas');
  });

  test('profile failure preserves successful authentication and can retry',
      () async {
    profiles.fetchError = StateError('offline');
    await model.login('ana@example.com', 'password');
    expect(model.session!.uid, testSession.uid);
    expect(model.failureKind, AuthFailureKind.profile);
    profiles.fetchError = null;
    await model.retryProfile();
    expect(model.status, AuthStatus.authenticated);
    expect(auth.loginCalls, 1);
  });

  test('missing profile can be completed without creating another account',
      () async {
    profiles.profile = null;
    auth.controller.add(testSession);
    await flush();
    expect(model.profileMissing, isTrue);
    expect(model.failureKind, AuthFailureKind.profile);
    await model.completeProfile(UserModel(nome: 'Ana'));
    expect(model.status, AuthStatus.authenticated);
    expect(model.user!.ativacao, 'pendente');
    expect(auth.registerCalls, 0);
  });

  test('registration succeeds without a redundant login or raced profile fetch',
      () async {
    await model.register('ana@example.com', 'password', UserModel(nome: 'Ana'));
    expect(model.status, AuthStatus.authenticated);
    expect(auth.registerCalls, 1);
    expect(auth.loginCalls, 0);
    expect(profiles.fetches, 0);
    expect(model.user!.ativacao, 'pendente');
  });

  test('account creation failure never attempts to save a profile', () async {
    auth.registerError = StateError('email already exists');
    await model.register('ana@example.com', 'password', UserModel(nome: 'Ana'));
    expect(model.failureKind, AuthFailureKind.authentication);
    expect(profiles.saves, 0);
    expect(model.session, isNull);
  });

  test('partial registration retries only profile persistence', () async {
    profiles.saveError = StateError('write denied');
    await model.register('ana@example.com', 'password', UserModel(nome: 'Ana'));
    expect(model.session, isNotNull);
    expect(model.failureKind, AuthFailureKind.registrationProfile);
    expect(model.hasPendingRegistration, isTrue);
    profiles.saveError = null;
    await model.retryProfile();
    expect(auth.registerCalls, 1);
    expect(auth.loginCalls, 0);
    expect(profiles.saves, 2);
    expect(model.status, AuthStatus.authenticated);
    expect(model.hasPendingRegistration, isFalse);
  });

  test('logout clears session, profile and pending registration', () async {
    await model.login('ana@example.com', 'password');
    await model.logout();
    expect(model.status, AuthStatus.disconnected);
    expect(model.session, isNull);
    expect(model.user, isNull);
  });

  test('failed logout preserves session and reports a distinct error',
      () async {
    await model.login('ana@example.com', 'password');
    auth.logoutError = StateError('offline');
    await model.logout();
    expect(model.session, isNotNull);
    expect(model.failureKind, AuthFailureKind.logout);
  });

  test('late restoration result cannot restore a signed-out account', () async {
    profiles.fetchCompleter = Completer<UserModel?>();
    auth.controller.add(testSession);
    await model.logout();
    profiles.fetchCompleter!.complete(testProfile());
    await flush();
    expect(model.status, AuthStatus.disconnected);
    expect(model.user, isNull);
  });

  test('switching account invalidates a late profile response', () async {
    final old = Completer<UserModel?>();
    profiles.fetchCompleter = old;
    auth.controller.add(testSession);
    profiles.fetchCompleter = null;
    profiles.profile = testProfile('uid-2');
    auth.controller.add(const AuthSession('uid-2', 'other@example.com'));
    await flush();
    old.complete(testProfile());
    await flush();
    expect(model.session!.uid, 'uid-2');
    expect(model.user!.uid, 'uid-2');
  });

  test('stream failure becomes an explicit session error', () {
    auth.controller.addError(StateError('stream failed'));
    expect(model.status, AuthStatus.error);
    expect(model.failureKind, AuthFailureKind.session);
  });

  test('duplicate clicks do not submit concurrent logins', () async {
    profiles.fetchCompleter = Completer<UserModel?>();
    final first = model.login('ana@example.com', 'password');
    await flush();
    await model.login('ana@example.com', 'password');
    expect(auth.loginCalls, 1);
    profiles.fetchCompleter!.complete(testProfile());
    await first;
  });

  test('external sign-out immediately invalidates profile loading after login',
      () async {
    profiles.fetchCompleter = Completer<UserModel?>();
    final login = model.login('ana@example.com', 'password');
    await flush();
    auth.controller.add(null);
    expect(model.session, isNull);
    expect(model.status, AuthStatus.disconnected);
    profiles.fetchCompleter!.complete(testProfile());
    await login;
    expect(model.user, isNull);
    expect(model.status, AuthStatus.disconnected);
  });

  test('repeated session event does not replace a partial registration error',
      () async {
    profiles.saveError = StateError('write failed');
    await model.register('ana@example.com', 'password', UserModel(nome: 'Ana'));
    auth.controller.add(testSession);
    await flush();
    expect(model.failureKind, AuthFailureKind.registrationProfile);
    expect(model.hasPendingRegistration, isTrue);
    expect(profiles.fetches, 0);
  });

  test('password reset failure propagates without changing session state',
      () async {
    auth.controller.add(null);
    auth.resetError = const AppFailure('offline', 'Sem conexão');
    await expectLater(
        model.resetPassword('ana@example.com'), throwsA(isA<AppFailure>()));
    expect(model.status, AuthStatus.disconnected);
  });

  test('disposed model ignores outstanding profile results', () async {
    final localAuth = FakeAuthRepository();
    final localProfiles = FakeProfileRepository()
      ..fetchCompleter = Completer<UserModel?>();
    final local = AuthViewModel(localAuth, localProfiles);
    localAuth.controller.add(testSession);
    local.dispose();
    localProfiles.fetchCompleter!.complete(testProfile());
    await flush();
    await localAuth.controller.close();
  });
}
