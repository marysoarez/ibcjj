import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ibcjj_flutter/core/data/validated_image.dart';
import 'package:ibcjj_flutter/core/data/session_guard.dart';
import 'package:ibcjj_flutter/core/errors/app_failure.dart';
import 'package:ibcjj_flutter/core/validation/form_validators.dart';
import 'package:ibcjj_flutter/features/certificates/data/activation_contact.dart';

class OversizedImage extends Fake implements XFile {
  bool readCalled = false;
  @override
  Future<int> length() async => ValidatedImage.maxBytes + 1;
  @override
  Stream<Uint8List> openRead([int? start, int? end]) {
    readCalled = true;
    return const Stream.empty();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('email, phone, weight and graduation reject malformed input', () {
    for (final value in ['', 'ana', 'a@b', 'a b@c.com']) {
      expect(FormValidators.email(value), isNotNull);
    }
    expect(FormValidators.email(' ana@example.com '), isNull);
    expect(FormValidators.phone('(21) 99999-9999'), isNull);
    expect(FormValidators.phone('123'), isNotNull);
    expect(FormValidators.phone('abc21999999999'), isNotNull);
    expect(FormValidators.weight('70,5'), isNull);
    for (final value in ['', '0', '-1', 'NaN', 'Infinity', '501']) {
      expect(FormValidators.weight(value), isNotNull);
    }
    expect(FormValidators.grade('2'), isNull);
    expect(FormValidators.grade('2.5'), isNotNull);
    expect(FormValidators.grade('-1'), isNotNull);
    expect(FormValidators.grade('11'), isNotNull);
  });

  test('password validation uses the untrimmed value', () {
    expect(FormValidators.loginPassword(' '), isNull);
    expect(FormValidators.newPassword(' abcd '), isNull);
    expect(FormValidators.newPassword('abc'), isNotNull);
  });

  test('oversized images are rejected before reading bytes', () async {
    final image = OversizedImage();
    await expectLater(ValidatedImage.read(image),
        throwsA(isA<AppFailure>().having((e) => e.code, 'code', 'image-size')));
    expect(image.readCalled, isFalse);
  });

  test('renaming non-image bytes to jpg does not bypass format validation',
      () async {
    await expectLater(
        ValidatedImage.read(XFile.fromData(
            Uint8List.fromList([60, 104, 116, 109, 108, 62]),
            name: 'photo.jpg')),
        throwsA(
            isA<AppFailure>().having((e) => e.code, 'code', 'image-format')));
  });

  test('corrupted supported header is rejected by decoder', () async {
    await expectLater(
        ValidatedImage.read(XFile.fromData(
            Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]))),
        throwsA(
            isA<AppFailure>().having((e) => e.code, 'code', 'image-invalid')));
  });

  test('valid PNG is identified from content rather than its extension',
      () async {
    final image = await ValidatedImage.read(XFile.fromData(
        await File('assets/icon/icon.png').readAsBytes(),
        name: 'photo.jpg'));
    expect(image.contentType, 'image/png');
  });

  test('session guard rejects missing, mismatched and unsafe UIDs', () {
    String? current = 'uid';
    final guard = SessionGuard(() => current);
    guard.requireUser('uid');
    for (final uid in ['', 'other', 'uid/child', 'uid\\child']) {
      expect(() => guard.requireUser(uid), throwsA(isA<AppFailure>()));
    }
    current = null;
    expect(() => guard.requireUser('uid'), throwsA(isA<AppFailure>()));
  });

  test('WhatsApp opens an encoded conversation without sending credentials',
      () async {
    Uri? received;
    final contact = WhatsAppActivationContact(launcher: (uri) async {
      received = uri;
      return true;
    });
    await contact.openConversation();
    expect(received!.host, 'wa.me');
    expect(received!.path, '/5521990466071');
    expect(received!.queryParameters.keys, ['text']);
    expect(received!.queryParameters['text'], contains('ativação'));
  });

  test('WhatsApp launch failure is actionable', () async {
    final contact = WhatsAppActivationContact(launcher: (_) async => false);
    await expectLater(
        contact.openConversation(),
        throwsA(isA<AppFailure>()
            .having((e) => e.code, 'code', 'whatsapp-unavailable')));
  });
}
