import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

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
  Object? uploadError;
  Object? downloadError;
  String? contentType;
  final deletedPaths = <String>[];
  Future<void> Function()? beforeList;
  @override
  Reference ref([String? path]) {
    paths.add(path);
    return TestReference(this, path ?? '');
  }
}

class TestReference extends Fake implements Reference {
  @override
  final TestStorage storage;
  final String path;
  TestReference(this.storage, this.path);
  @override
  Future<ListResult> listAll() async {
    await storage.beforeList?.call();
    return TestListResult();
  }

  @override
  Future<void> delete() async {
    storage.deletedPaths.add(path);
  }

  @override
  Future<String> getDownloadURL() async {
    if (storage.downloadError != null) throw storage.downloadError!;
    return 'https://example.com/profile.jpg';
  }

  @override
  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) {
    if (storage.uploadError != null) throw storage.uploadError!;
    storage.contentType = metadata?.contentType;
    return TestUpload();
  }
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
  Future<XFile?> Function()? onPick;
  @override
  Future<XFile?> pickImage(
          {required ImageSource source,
          double? maxWidth,
          double? maxHeight,
          int? imageQuality,
          CameraDevice preferredCameraDevice = CameraDevice.rear,
          bool requestFullMetadata = true}) async =>
      onPick != null
          ? await onPick!()
          : XFile.fromData(await File('assets/icon/icon.png').readAsBytes(),
              name: 'test.png');
}

class TestListResult extends Fake implements ListResult {
  @override
  List<Reference> get items => [];
}
