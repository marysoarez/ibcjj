import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ibcjj_flutter/core/data/session_guard.dart';
import 'package:ibcjj_flutter/core/errors/app_failure.dart';
import 'package:ibcjj_flutter/features/certificates/data/firebase_certificates_repository.dart';
import '../support/firebase_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestStorage storage;
  late TestPicker picker;
  late FirebaseCertificatesRepository repository;
  String? currentUid;
  setUp(() {
    currentUid = 'uid';
    storage = TestStorage();
    picker = TestPicker();
    repository = FirebaseCertificatesRepository(storage, picker,
        sessionGuard: SessionGuard(() => currentUid));
  });

  test('missing or mismatched session prevents all certificate operations',
      () async {
    for (final session in [null, 'other-user']) {
      currentUid = session;
      await expectLater(repository.list('uid'), throwsA(isA<AppFailure>()));
      await expectLater(repository.add('uid'), throwsA(isA<AppFailure>()));
      await expectLater(
          repository.delete('uid', 'file'), throwsA(isA<AppFailure>()));
    }
    expect(storage.paths, isEmpty);
  });

  test('changed session invalidates a listing result', () async {
    storage.beforeList = () async {
      currentUid = null;
    };
    await expectLater(repository.list('uid'), throwsA(isA<AppFailure>()));
  });

  test('logout while gallery is open prevents certificate upload', () async {
    picker.onPick = () async {
      currentUid = null;
      return XFile.fromData(await File('assets/icon/icon.png').readAsBytes());
    };
    await expectLater(repository.add('uid'), throwsA(isA<AppFailure>()));
    expect(storage.paths, isEmpty);
  });

  test('valid upload belongs to current user and uses content MIME', () async {
    expect(await repository.add('uid'), isTrue);
    expect(storage.paths.single, startsWith('certificados/uid/'));
    expect(storage.contentType, 'image/png');
  });

  test('cancelled image selection does not upload', () async {
    picker.onPick = () async => null;
    expect(await repository.add('uid'), isFalse);
    expect(storage.paths, isEmpty);
  });

  test('deletion stays inside user folder and rejects nested names', () async {
    await expectLater(
        repository.delete('uid', '../other/file'), throwsA(isA<AppFailure>()));
    expect(storage.paths, isEmpty);
    await repository.delete('uid', 'certificate');
    expect(storage.deletedPaths, ['certificados/uid/certificate']);
  });
}
