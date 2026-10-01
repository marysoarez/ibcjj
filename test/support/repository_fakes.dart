import 'dart:async';
import 'package:ibcjj_flutter/features/auth/data/auth_repository.dart';
import 'package:ibcjj_flutter/features/profile/data/profile_repository.dart';
import 'package:ibcjj_flutter/features/profile/models/user_model.dart';
import 'package:ibcjj_flutter/features/certificates/data/certificates_repository.dart';
import 'package:ibcjj_flutter/features/certificates/models/certificate.dart';

const testSession = AuthSession('uid-1', 'ana@example.com');
UserModel testProfile([String uid = 'uid-1']) => UserModel(
    uid: uid, email: 'ana@example.com', nome: 'Ana', ativacao: 'vitalício');

class FakeAuthRepository implements AuthRepository {
  final controller = StreamController<AuthSession?>.broadcast(sync: true);
  int loginCalls = 0;
  int registerCalls = 0;
  int logoutCalls = 0;
  String? passwordReceived;
  Object? loginError;
  Object? registerError;
  Object? logoutError;
  Object? resetError;
  @override
  Stream<AuthSession?> get sessionChanges => controller.stream;
  @override
  Future<AuthSession> login(String email, String password) async {
    loginCalls++;
    passwordReceived = password;
    if (loginError != null) throw loginError!;
    controller.add(testSession);
    return testSession;
  }

  @override
  Future<AuthSession> register(String email, String password) async {
    registerCalls++;
    if (registerError != null) throw registerError!;
    controller.add(testSession);
    return testSession;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError != null) throw logoutError!;
    controller.add(null);
  }

  @override
  Future<void> resetPassword(String email) async {
    if (resetError != null) throw resetError!;
  }
}

class FakeProfileRepository implements ProfileRepository {
  UserModel? profile = testProfile();
  Object? fetchError;
  Object? saveError;
  Object? photoError;
  int saves = 0;
  int fetches = 0;
  Completer<UserModel?>? fetchCompleter;
  @override
  Future<UserModel?> fetch(AuthSession session) async {
    fetches++;
    if (fetchError != null) throw fetchError!;
    if (fetchCompleter != null) return fetchCompleter!.future;
    return profile;
  }

  @override
  Future<UserModel> saveRegistration(
      AuthSession session, UserModel value) async {
    saves++;
    if (saveError != null) throw saveError!;
    return profile = UserModel.forRegistration(
        uid: session.uid, email: session.email!, profile: value);
  }

  @override
  Future<String?> updatePhoto(String uid) async {
    if (photoError != null) throw photoError!;
    return 'https://example.com/new.jpg';
  }
}

class FakeCertificatesRepository implements CertificatesRepository {
  List<Certificate> values = [];
  Object? error;
  bool cancelled = false;
  @override
  Future<List<Certificate>> list(String uid) async {
    if (error != null) throw error!;
    return List.of(values);
  }

  @override
  Future<bool> add(String uid) async {
    if (error != null) throw error!;
    if (cancelled) return false;
    values.add(const Certificate(
        name: 'certificate', url: 'https://example.com/c.jpg'));
    return true;
  }

  @override
  Future<void> delete(String uid, String name) async {
    if (error != null) throw error!;
    values.removeWhere((item) => item.name == name);
  }
}
