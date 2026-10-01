import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/errors/app_failure.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  FirebaseAuthRepository(this._auth);

  AuthSession _session(User user) => AuthSession(user.uid, user.email);

  @override
  Stream<AuthSession?> get sessionChanges => _auth
      .authStateChanges()
      .map((user) => user == null ? null : _session(user));

  Future<T> _run<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseAuthException catch (error, stack) {
      final message = switch (error.code) {
        'email-already-in-use' => 'Este e-mail já está em uso.',
        'invalid-email' => 'Informe um e-mail válido.',
        'weak-password' => 'A senha deve ter pelo menos 6 caracteres.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'E-mail ou senha inválidos.',
        'network-request-failed' => 'Confira sua conexão e tente novamente.',
        'too-many-requests' => 'Muitas tentativas. Aguarde e tente novamente.',
        _ => 'Não foi possível concluir a autenticação. Tente novamente.',
      };
      Error.throwWithStackTrace(AppFailure(error.code, message), stack);
    }
  }

  @override
  Future<AuthSession> login(String email, String password) => _run(() async {
        final result = await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        if (result.user == null) {
          throw const AppFailure('missing-user', 'Sessão indisponível.');
        }
        return _session(result.user!);
      });

  @override
  Future<AuthSession> register(String email, String password) => _run(() async {
        final result = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        if (result.user == null) {
          throw const AppFailure('missing-user', 'Conta indisponível.');
        }
        return _session(result.user!);
      });

  @override
  Future<void> logout() => _run(_auth.signOut);

  @override
  Future<void> resetPassword(String email) =>
      _run(() => _auth.sendPasswordResetEmail(email: email));
}
