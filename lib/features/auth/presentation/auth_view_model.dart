import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/models/user_model.dart';
import '../data/auth_repository.dart';

enum AuthStatus { loading, authenticated, disconnected, error }

enum AuthFailureKind {
  authentication,
  profile,
  registrationProfile,
  session,
  logout
}

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _auth;
  final ProfileRepository _profiles;
  late final StreamSubscription<AuthSession?> _subscription;
  AuthStatus status = AuthStatus.loading;
  AuthFailureKind? failureKind;
  String? error;
  bool busy = false;
  AuthSession? _session;
  AuthSession? get session => _session;
  UserModel? _user;
  UserModel? get user => _user;
  UserModel? _pendingRegistration;
  bool get hasPendingRegistration => _pendingRegistration != null;
  bool profileMissing = false;
  bool _disposed = false;
  int _revision = 0;
  bool _changingSession = false;
  bool _hasDeferredSession = false;
  AuthSession? _deferredSession;

  AuthViewModel(this._auth, this._profiles) {
    _subscription =
        _auth.sessionChanges.listen(_sessionChanged, onError: (Object failure) {
      ++_revision;
      _fail(AuthFailureKind.session, 'Não foi possível acompanhar sua sessão.');
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _current(int revision) => !_disposed && revision == _revision;
  void _fail(AuthFailureKind kind, String message) {
    if (_disposed) return;
    status = AuthStatus.error;
    failureKind = kind;
    error = message;
    _notify();
  }

  void _sessionChanged(AuthSession? value) {
    if (_disposed) return;
    if (_changingSession) {
      _hasDeferredSession = true;
      _deferredSession = value;
      return;
    }
    if (value?.uid == _session?.uid &&
        (_session != null || status == AuthStatus.disconnected)) {
      return;
    }
    _acceptSession(value);
  }

  void _acceptSession(AuthSession? value) {
    final revision = ++_revision;
    final changedAccount = value?.uid != _session?.uid;
    _session = value;
    _user = null;
    error = null;
    failureKind = null;
    profileMissing = false;
    if (changedAccount || value == null) _pendingRegistration = null;
    if (value == null) {
      status = AuthStatus.disconnected;
      _notify();
    } else {
      unawaited(_loadProfile(value, revision));
    }
  }

  Future<void> _loadProfile(AuthSession value, int revision) async {
    status = AuthStatus.loading;
    _notify();
    try {
      final profile = await _profiles.fetch(value);
      if (!_current(revision)) return;
      if (profile == null) {
        profileMissing = true;
        _fail(AuthFailureKind.profile,
            'Sua conta está conectada, mas o perfil ainda não foi cadastrado.');
      } else {
        _user = profile;
        profileMissing = false;
        error = null;
        failureKind = null;
        status = AuthStatus.authenticated;
        _notify();
      }
    } catch (_) {
      if (_current(revision)) {
        _fail(AuthFailureKind.profile,
            'Sua conta está conectada, mas não foi possível carregar o perfil.');
      }
    }
  }

  void _begin({bool changingSession = false}) {
    busy = true;
    _changingSession = changingSession;
    error = null;
    failureKind = null;
    status = AuthStatus.loading;
    _notify();
  }

  void _finish() {
    _changingSession = false;
    busy = false;
    if (_disposed) return;
    if (_hasDeferredSession) {
      final deferred = _deferredSession;
      _hasDeferredSession = false;
      _deferredSession = null;
      if (deferred?.uid != _session?.uid) _acceptSession(deferred);
    }
    _notify();
  }

  Future<void> login(String email, String password) async {
    if (busy || _disposed) return;
    final revision = ++_revision;
    _begin(changingSession: true);
    try {
      final value = await _auth.login(email, password);
      if (!_current(revision)) return;
      if (!_resolveAuthSession(value)) return;
      await _loadProfile(value, revision);
    } catch (failure) {
      if (_current(revision)) {
        _fail(
            AuthFailureKind.authentication,
            failureMessage(
                failure, 'Não foi possível entrar. Tente novamente.'));
      }
    } finally {
      _finish();
    }
  }

  Future<void> register(
      String email, String password, UserModel profile) async {
    if (busy || _disposed) return;
    final revision = ++_revision;
    _begin(changingSession: true);
    try {
      final value = await _auth.register(email, password);
      if (!_current(revision)) return;
      if (!_resolveAuthSession(value)) return;
      _pendingRegistration = profile;
      await _savePending(value, revision);
    } catch (failure) {
      if (_current(revision)) {
        _fail(AuthFailureKind.authentication,
            failureMessage(failure, 'Não foi possível criar a conta.'));
      }
    } finally {
      _finish();
    }
  }

  // Auth events during SDK sign-in are queued; after that, external sign-out
  // must invalidate in-flight profile operations immediately.
  bool _resolveAuthSession(AuthSession value) {
    _session = value;
    _user = null;
    _changingSession = false;
    if (_hasDeferredSession) {
      final deferred = _deferredSession;
      _hasDeferredSession = false;
      _deferredSession = null;
      if (deferred?.uid != value.uid) {
        _acceptSession(deferred);
        return false;
      }
    }
    return true;
  }

  Future<void> _savePending(AuthSession value, int revision) async {
    try {
      final saved =
          await _profiles.saveRegistration(value, _pendingRegistration!);
      if (!_current(revision)) return;
      _user = saved;
      _pendingRegistration = null;
      profileMissing = false;
      error = null;
      failureKind = null;
      status = AuthStatus.authenticated;
      _notify();
    } catch (_) {
      if (_current(revision)) {
        _fail(AuthFailureKind.registrationProfile,
            'Sua conta foi criada, mas o perfil não pôde ser salvo. Tente salvar novamente.');
      }
    }
  }

  Future<void> retryProfile() async {
    final value = _session;
    if (value == null || busy || _disposed) return;
    final revision = ++_revision;
    _begin();
    try {
      if (_pendingRegistration != null) {
        await _savePending(value, revision);
      } else {
        await _loadProfile(value, revision);
      }
    } finally {
      _finish();
    }
  }

  Future<void> completeProfile(UserModel profile) async {
    if (_session == null || busy || !profileMissing) return;
    _pendingRegistration = profile;
    await retryProfile();
  }

  Future<void> logout() async {
    if (busy || _disposed) return;
    ++_revision; // A late profile response must not restore a logged-out user.
    _begin(changingSession: true);
    try {
      await _auth.logout();
      if (!_disposed) _acceptSession(null);
    } catch (failure) {
      _fail(AuthFailureKind.logout,
          failureMessage(failure, 'Não foi possível sair. Tente novamente.'));
    } finally {
      _finish();
    }
  }

  Future<void> resetPassword(String email) => _auth.resetPassword(email);

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
