import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presentation and repository contracts do not import Firebase SDKs', () {
    final forbidden = RegExp(
        r'package:(firebase_auth|firebase_core|firebase_storage|cloud_firestore)/');
    final files = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      final path = file.path.replaceAll('\\', '/');
      if (path.contains('/presentation/') ||
          path.contains('/models/') ||
          (path.contains('/data/') &&
              !path.split('/').last.startsWith('firebase_'))) {
        expect(forbidden.hasMatch(file.readAsStringSync()), isFalse,
            reason: path);
      }
    }
  });
}
