import 'package:flutter_test/flutter_test.dart';
import 'package:ibcjj_flutter/features/profile/presentation/profile_view_model.dart';
import 'package:ibcjj_flutter/features/certificates/presentation/certificates_view_model.dart';
import '../support/repository_fakes.dart';

void main() {
  test('profile commits a photo locally only after persistence succeeds',
      () async {
    final repository = FakeProfileRepository();
    final model = ProfileViewModel(repository, testProfile());
    repository.photoError = StateError('offline');
    await model.editProfileImage();
    expect(model.profileImageUrl, isNull);
    expect(model.error, isNotNull);
    repository.photoError = null;
    await model.editProfileImage();
    expect(model.profileImageUrl, 'https://example.com/new.jpg');
    expect(model.error, isNull);
    model.dispose();
  });

  test('certificates list, upload, cancellation and deletion use repository',
      () async {
    final repository = FakeCertificatesRepository();
    final model = CertificatesViewModel(repository, 'uid-1');
    await model.load();
    expect(model.items, isEmpty);
    repository.cancelled = true;
    await model.add();
    expect(model.items, isEmpty);
    repository.cancelled = false;
    await model.add();
    expect(model.items, hasLength(1));
    await model.delete(model.items.single);
    expect(model.items, isEmpty);
    model.dispose();
  });

  test('failed certificate deletion preserves displayed items', () async {
    final repository = FakeCertificatesRepository();
    final model = CertificatesViewModel(repository, 'uid-1');
    await model.add();
    repository.error = StateError('denied');
    await model.delete(model.items.single);
    expect(model.items, hasLength(1));
    expect(model.error, isNotNull);
    expect(model.busy, isFalse);
    model.dispose();
  });
}
