import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ibcjj_flutter/app/app.dart';
import 'package:ibcjj_flutter/features/auth/presentation/auth_view_model.dart';
import 'package:ibcjj_flutter/features/auth/presentation/reset_password_page.dart';
import 'package:ibcjj_flutter/features/certificates/presentation/certificates_page.dart';
import 'package:ibcjj_flutter/features/certificates/presentation/certificates_view_model.dart';
import 'package:ibcjj_flutter/features/profile/presentation/profile_view_model.dart';
import 'support/repository_fakes.dart';

void main() {
  testWidgets(
      'closing password reset during a request causes no setState after dispose',
      (tester) async {
    final auth = FakeAuthRepository()..resetCompleter = Completer<void>();
    final model = AuthViewModel(auth, FakeProfileRepository());
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: model, child: const MaterialApp(home: ResetPasswordPage())));
    await tester.enterText(find.byType(TextFormField), 'ana@example.com');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull);
    expect(auth.resetCalls, 1);
    await tester.pumpWidget(const SizedBox());
    auth.resetCompleter!.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
    model.dispose();
    await auth.controller.close();
  });

  testWidgets(
      'small login viewport with open keyboard scrolls without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final auth = FakeAuthRepository()..loginError = StateError('invalid');
    await tester.pumpWidget(IbcjjApp(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
        certificatesRepository: FakeCertificatesRepository()));
    auth.controller.add(null);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'ana@example.com');
    await tester.enterText(find.byType(TextFormField).last, ' password ');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(auth.passwordReceived, ' password ');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await auth.controller.close();
  });

  testWidgets('certificate deletion requires confirmation and reports success',
      (tester) async {
    final repository = FakeCertificatesRepository();
    await repository.add('uid');
    final model = CertificatesViewModel(repository, 'uid');
    await model.load();
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: model, child: const MaterialApp(home: CertificatesPage())));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir certificado'));
    await tester.pumpAndSettle();
    expect(model.items, hasLength(1));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(model.items, hasLength(1));
    await tester.tap(find.byTooltip('Excluir certificado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(model.items, isEmpty);
    expect(find.text('Certificado excluído.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });

  test('profile ignores duplicate actions and results after disposal',
      () async {
    final repository = FakeProfileRepository()
      ..photoCompleter = Completer<String?>();
    final model = ProfileViewModel(repository, testProfile());
    final first = model.editProfileImage();
    await model.editProfileImage();
    expect(repository.photoCalls, 1);
    model.dispose();
    repository.photoCompleter!.complete('https://example.com/photo.jpg');
    await first;
    await model.editProfileImage();
    expect(repository.photoCalls, 1);
  });

  test('certificates ignore duplicate uploads and do not reload after disposal',
      () async {
    final repository = FakeCertificatesRepository()
      ..addCompleter = Completer<bool>();
    final model = CertificatesViewModel(repository, 'uid');
    final first = model.add();
    await model.add();
    expect(repository.addCalls, 1);
    model.dispose();
    repository.addCompleter!.complete(true);
    await first;
    await model.add();
    expect(repository.addCalls, 1);
  });
}
