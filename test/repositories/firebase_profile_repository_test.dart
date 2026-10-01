import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ibcjj_flutter/features/auth/data/auth_repository.dart';
import 'package:ibcjj_flutter/features/profile/models/user_model.dart';
import 'package:ibcjj_flutter/features/profile/data/firebase_profile_repository.dart';

// SDK doubles used only to verify paths, payloads and merge behavior.
class MemoryFirestore extends Fake implements FirebaseFirestore {
  final documents = <String, Map<String, dynamic>>{};
  final paths = <String>[];
  bool failWrites = false;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    paths.add(path);
    return MemoryCollection(this, path);
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) =>
      handler(MemoryTransaction(this));
}

// ignore: subtype_of_sealed_class
class MemoryCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final MemoryFirestore store;
  @override
  final String path;
  MemoryCollection(this.store, this.path);
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      MemoryDocument(store, '${this.path}/$path');
}

// ignore: subtype_of_sealed_class
class MemoryDocument extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final MemoryFirestore store;
  @override
  final String path;
  MemoryDocument(this.store, this.path);
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
          [GetOptions? options]) async =>
      MemorySnapshot(store.documents[path]);
  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (store.failWrites) throw StateError('Write failed');
    store.documents[path] = {
      if (options?.merge == true) ...?store.documents[path],
      ...data
    };
  }
}

// ignore: subtype_of_sealed_class
class MemorySnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? value;
  MemorySnapshot(this.value);
  @override
  Map<String, dynamic>? data() => value;
}

class MemoryTransaction extends Fake implements Transaction {
  final MemoryFirestore store;
  MemoryTransaction(this.store);
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
          DocumentReference<T> reference) =>
      reference.get();
  @override
  Transaction set<T>(DocumentReference<T> reference, T data,
      [SetOptions? options]) {
    if (store.failWrites) throw StateError('Write failed');
    store.documents[reference.path] = Map<String, dynamic>.from(data as Map);
    return this;
  }
}

class TestStorage extends Fake implements FirebaseStorage {
  final paths = <String?>[];
  @override
  Reference ref([String? path]) {
    paths.add(path);
    return TestReference();
  }
}

class TestReference extends Fake implements Reference {
  @override
  Future<String> getDownloadURL() async => 'https://example.com/profile.jpg';
  @override
  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) =>
      TestUpload();
}

class TestSnapshot extends Fake implements TaskSnapshot {}

class TestUpload extends Fake implements UploadTask {
  @override
  Future<T> then<T>(FutureOr<T> Function(TaskSnapshot) onValue,
          {Function? onError}) =>
      Future<TaskSnapshot>.value(TestSnapshot())
          .then(onValue, onError: onError);
}

class TestPicker extends Fake implements ImagePicker {
  @override
  Future<XFile?> pickImage(
          {required ImageSource source,
          double? maxWidth,
          double? maxHeight,
          int? imageQuality,
          CameraDevice preferredCameraDevice = CameraDevice.rear,
          bool requestFullMetadata = true}) async =>
      XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'test.jpg');
}

void main() {
  const session = AuthSession('auth-uid', 'auth@example.com');
  late MemoryFirestore store;
  late TestStorage storage;
  late FirebaseProfileRepository repository;
  setUp(() {
    store = MemoryFirestore();
    storage = TestStorage();
    repository = FirebaseProfileRepository(store, storage, TestPicker());
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
    await expectLater(repository.updatePhoto(session.uid), throwsStateError);
    await expectLater(
        repository.saveRegistration(session, UserModel()), throwsStateError);
    expect(store.documents, isEmpty);
  });
}
