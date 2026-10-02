import '../errors/app_failure.dart';

/// Uses the live session, not the UID captured when a screen was opened.
class SessionGuard {
  final String? Function() currentUid;
  const SessionGuard(this.currentUid);

  void requireUser(String uid) {
    if (uid.isEmpty ||
        uid.contains('/') ||
        uid.contains('\\') ||
        currentUid() != uid) {
      throw const AppFailure('session-expired',
          'Sua sessão mudou ou expirou. Entre novamente para continuar.');
    }
  }
}
