class AuthSession {
  final String uid;
  final String? email;
  const AuthSession(this.uid, this.email);
}

abstract class AuthRepository {
  Stream<AuthSession?> get sessionChanges;
  Future<AuthSession> login(String email, String password);
  Future<AuthSession> register(String email, String password);
  Future<void> logout();
  Future<void> resetPassword(String email);
}
