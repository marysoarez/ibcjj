import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ibcjj_flutter/models/user_model.dart';
import 'package:ibcjj_flutter/viewmodels/auth_viewmodel.dart';

// These doubles only implement the SDK operations used by the data contract.
// They never initialize Firebase or access a device/network.
class TestUser extends Fake implements User {
  @override
  String get uid => 'auth-uid';
  @override
  String get email => 'auth@example.com';
}

class TestCredential extends Fake implements UserCredential {
  @override
  User get user => TestUser();
}

class TestAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => TestUser();

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async =>
      TestCredential();
}

class MemoryFirestore extends Fake implements FirebaseFirestore {
  final documents = <String, Map<String, dynamic>>{};
  final paths = <String>[];
  bool failWrites = false;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    paths.add(collectionPath);
    return MemoryCollection(this, collectionPath);
  }
}

// SDK annotations prohibit application subclasses; this is a test-only double.
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
      ...data,
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
  UploadTask putFile(File file, [SettableMetadata? metadata]) => TestUpload();
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
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async =>
      XFile('unused-by-test-storage.jpg');
}

void main() {
  late MemoryFirestore store;
  late TestStorage storage;
  late AuthViewModel model;

  setUp(() {
    store = MemoryFirestore();
    storage = TestStorage();
    model = AuthViewModel(
      auth: TestAuth(),
      firestore: store,
      storage: storage,
      imagePicker: TestPicker(),
      restoreSession: false,
    );
  });

  tearDown(() => model.dispose());

  test('missing document yields a pending profile without writing it',
      () async {
    await model.fetchUserData();
    expect(model.user!.uid, 'auth-uid');
    expect(model.user!.email, 'auth@example.com');
    expect(model.user!.ativacao, 'pendente');
    expect(store.documents, isEmpty);
    expect(store.paths, ['Usuarios']);
  });

  test('reads incomplete legacy profile and trusts the document identity',
      () async {
    store.documents['Usuarios/auth-uid'] = {
      'uid': 'wrong',
      'gênero': 'feminino',
      'nome': 'Ana',
      'ativacao': 'vitalício',
    };
    await model.fetchUserData();
    expect(model.user!.uid, 'auth-uid');
    expect(model.user!.email, 'auth@example.com');
    expect(model.user!.genero, 'feminino');
    expect(model.user!.telefone, '');
    expect(model.user!.ativacao, 'vitalício');
  });

  test('registration writes canonical fields and pending activation', () async {
    await model.register(
        'auth@example.com',
        'test-only',
        UserModel(
          nome: 'Ana',
          genero: 'feminino',
          ativacao: 'vitalício',
        ));
    final data = store.documents['Usuarios/auth-uid']!;
    expect(data['uid'], 'auth-uid');
    expect(data['email'], 'auth@example.com');
    expect(data['genero'], 'feminino');
    expect(data['ativacao'], 'pendente');
    expect(data['tecnico'], '');
    expect(data, isNot(contains('gênero')));
    expect(model.user!.nome, 'Ana');
    expect(store.paths, everyElement('Usuarios'));
  });

  test('photo update merges into Usuarios without erasing activation or extras',
      () async {
    store.documents['Usuarios/auth-uid'] = {
      'nome': 'Ana',
      'ativacao': 'vitalício',
      'adminField': 'preserve',
    };
    await model.fetchUserData();
    await model.editProfileImage();
    final data = store.documents['Usuarios/auth-uid']!;
    expect(data['nome'], 'Ana');
    expect(data['ativacao'], 'vitalício');
    expect(data['adminField'], 'preserve');
    expect(data['profileImageUrl'], 'https://example.com/profile.jpg');
    expect(model.user!.profileImageUrl, model.profileImageUrl);
    expect(store.documents.keys, ['Usuarios/auth-uid']);
    expect(store.paths, everyElement('Usuarios'));
    expect(storage.paths, ['usuarios/auth-uid/profile.jpg']);
  });

  test('photo update also works when the profile document is missing',
      () async {
    await model.editProfileImage();
    expect(store.documents['Usuarios/auth-uid']!['uid'], 'auth-uid');
    await model.fetchUserData();
    expect(model.user!.ativacao, 'pendente');
    expect(model.user!.email, 'auth@example.com');
    expect(model.profileImageUrl, 'https://example.com/profile.jpg');
  });

  test('failed photo persistence does not report a new local URL', () async {
    store.documents['Usuarios/auth-uid'] = {
      'profileImageUrl': 'https://example.com/old.jpg',
    };
    await model.fetchUserData();
    store.failWrites = true;
    await expectLater(model.editProfileImage(), throwsStateError);
    expect(model.profileImageUrl, 'https://example.com/old.jpg');
    expect(model.user!.profileImageUrl, 'https://example.com/old.jpg');
  });
}
