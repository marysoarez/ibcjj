import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ibcjj_flutter/features/auth/data/auth_repository.dart';
import 'package:ibcjj_flutter/features/profile/models/user_model.dart';
import 'package:ibcjj_flutter/features/profile/data/firebase_profile_repository.dart';
import 'package:ibcjj_flutter/core/data/session_guard.dart';
import 'package:ibcjj_flutter/core/errors/app_failure.dart';
import '../support/firebase_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const session = AuthSession('auth-uid', 'auth@example.com');
  late MemoryFirestore store;
  late TestStorage storage;
  late FirebaseProfileRepository repository;
  late TestPicker picker;
  String? currentUid;
  setUp(() {
    store = MemoryFirestore();
    storage = TestStorage();
    currentUid = session.uid;
    picker = TestPicker();
    repository = FirebaseProfileRepository(store, storage, picker,
        sessionGuard: SessionGuard(() => currentUid));
  });

  test('missing profile is explicit and does not write to Firestore', () async {
    expect(await repository.fetch(session), isNull);
    expect(store.documents, isEmpty);
    expect(store.paths, ['Usuarios']);
  });

  test(
      'legacy incomplete profile trusts identity and resolves old Storage photo',
      () async {
    store.documents['Usuarios/auth-uid'] = {
      'uid': 'wrong',
      'gênero': 'feminino',
      'nome': 'Ana',
      'ativacao': 'vitalício'
    };
    final profile = (await repository.fetch(session))!;
    expect(profile.uid, 'auth-uid');
    expect(profile.email, 'auth@example.com');
    expect(profile.genero, 'feminino');
    expect(profile.telefone, '');
    expect(profile.ativacao, 'vitalício');
    expect(storage.paths, ['usuarios/auth-uid/profile.jpg']);
  });

  test('registration writes the canonical contract with pending activation',
      () async {
    final saved = await repository.saveRegistration(session,
        UserModel(nome: 'Ana', genero: 'feminino', ativacao: 'vitalício'));
    final data = store.documents['Usuarios/auth-uid']!;
    expect(data, saved.toMap());
    expect(data['ativacao'], 'pendente');
    expect(data['genero'], 'feminino');
    expect(data, isNot(contains('gênero')));
    expect(data['email'], 'auth@example.com');
  });

  test(
      'retry after a successful write does not reset activation or other fields',
      () async {
    store.documents['Usuarios/auth-uid'] = {
      'nome': 'Ana',
      'ativacao': 'vitalício',
      'adminField': 'preserve'
    };
    final saved =
        await repository.saveRegistration(session, UserModel(nome: 'Retry'));
    expect(saved.nome, 'Ana');
    expect(saved.ativacao, 'vitalício');
    expect(store.documents['Usuarios/auth-uid']!['adminField'], 'preserve');
  });

  test('photo merges into Usuarios without erasing existing fields', () async {
    store.documents['Usuarios/auth-uid'] = {
      'nome': 'Ana',
      'ativacao': 'vitalício',
      'adminField': 'preserve'
    };
    final url = await repository.updatePhoto(session.uid);
    final data = store.documents['Usuarios/auth-uid']!;
    expect(data['nome'], 'Ana');
    expect(data['ativacao'], 'vitalício');
    expect(data['adminField'], 'preserve');
    expect(data['profileImageUrl'], url);
    expect(store.documents.keys, ['Usuarios/auth-uid']);
    expect(storage.paths, ['usuarios/auth-uid/profile.jpg']);
  });

  test('photo update tolerates a missing document', () async {
    await repository.updatePhoto(session.uid);
    final profile = (await repository.fetch(session))!;
    expect(profile.uid, 'auth-uid');
    expect(profile.ativacao, 'pendente');
    expect(profile.email, 'auth@example.com');
  });

  test('failed persistence is propagated instead of reporting success',
      () async {
    store.failWrites = true;
    await expectLater(
        repository.updatePhoto(session.uid),
        throwsA(isA<AppFailure>()
            .having((e) => e.code, 'stage', 'photo-document')));
    await expectLater(repository.saveRegistration(session, UserModel()),
        throwsA(isA<AppFailure>()));
    expect(store.documents, isEmpty);
  });

  test('missing photo is normal, but permission failure is visible', () async {
    store.documents['Usuarios/auth-uid'] = {'nome': 'Ana'};
    storage.downloadError =
        FirebaseException(plugin: 'storage', code: 'object-not-found');
    expect((await repository.fetch(session))!.profileImageUrl, isNull);
    storage.downloadError =
        FirebaseException(plugin: 'storage', code: 'unauthorized');
    await expectLater(repository.fetch(session), throwsA(isA<AppFailure>()));
  });

  test('upload failure is distinct from document failure and saves no URL',
      () async {
    storage.uploadError = StateError('offline');
    await expectLater(
        repository.updatePhoto(session.uid),
        throwsA(
            isA<AppFailure>().having((e) => e.code, 'stage', 'photo-upload')));
    expect(store.documents, isEmpty);
  });

  test('session required before any read or upload', () async {
    currentUid = null;
    await expectLater(repository.fetch(session), throwsA(isA<AppFailure>()));
    await expectLater(
        repository.updatePhoto(session.uid), throwsA(isA<AppFailure>()));
    expect(store.paths, isEmpty);
    expect(storage.paths, isEmpty);
  });

  test('session change during selection prevents upload', () async {
    picker.onPick = () async {
      currentUid = 'other-user';
      return XFile.fromData(await File('assets/icon/icon.png').readAsBytes());
    };
    await expectLater(
        repository.updatePhoto(session.uid),
        throwsA(isA<AppFailure>()
            .having((e) => e.code, 'code', 'session-expired')));
    expect(storage.paths, isEmpty);
  });

  test('real content type is sent to Storage', () async {
    await repository.updatePhoto(session.uid);
    expect(storage.contentType, 'image/png');
  });
}
