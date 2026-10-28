import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibcjj_flutter/app/app.dart';
import 'package:ibcjj_flutter/app/bootstrap.dart';
import 'package:ibcjj_flutter/features/auth/presentation/auth_view_model.dart';
import 'package:ibcjj_flutter/features/certificates/presentation/certificates_page.dart';
import 'package:provider/provider.dart';
import 'support/repository_fakes.dart';

void main() {
  testWidgets('bootstrap failure does not create the app or expose raw errors',
      (tester) async {
    var created = false;
    final widget = await bootstrap(
      initialize: () async => throw StateError('private backend detail'),
      createApp: () {
        created = true;
        return const SizedBox();
      },
    );
    await tester.pumpWidget(widget);
    expect(created, isFalse);
    expect(find.textContaining('Não foi possível iniciar'), findsOneWidget);
    expect(find.textContaining('private backend detail'), findsNothing);
  });

  testWidgets(
      'bootstrap initializes once and widget rebuilds do not initialize',
      (tester) async {
    var calls = 0;
    final widget = await bootstrap(
      initialize: () async {
        calls++;
      },
      createApp: () => const MaterialApp(home: Text('Ready')),
    );
    await tester.pumpWidget(widget);
    await tester.pumpWidget(widget);
    expect(calls, 1);
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('session gate clears protected routes after logout',
      (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(IbcjjApp(
        authRepository: auth,
        profileRepository: FakeProfileRepository(),
        certificatesRepository: FakeCertificatesRepository()));
    auth.controller.add(testSession);
    await tester.pumpAndSettle();
    expect(find.text('Carteirinha do Atleta'), findsOneWidget);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Certificados'));
    await tester.pumpAndSettle();
    expect(find.byType(CertificatesPage), findsOneWidget);
    auth.controller.add(null);
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.byType(CertificatesPage), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await auth.controller.close();
  });

  testWidgets('partial registration shows retry rather than login failure',
      (tester) async {
    final auth = FakeAuthRepository();
    final profiles = FakeProfileRepository()..saveError = StateError('offline');
    await tester.pumpWidget(IbcjjApp(
        authRepository: auth,
        profileRepository: profiles,
        certificatesRepository: FakeCertificatesRepository()));
    auth.controller.add(null);
    await tester.pumpAndSettle();
    final model = tester.element(find.text('Entrar')).read<AuthViewModel>();
    await model.register('ana@example.com', 'password', testProfile());
    await tester.pumpAndSettle();
    expect(find.textContaining('Sua conta foi criada'), findsOneWidget);
    expect(find.text('Salvar perfil novamente'), findsOneWidget);
    profiles.saveError = null;
    await tester.tap(find.text('Salvar perfil novamente'));
    await tester.pumpAndSettle();
    expect(auth.registerCalls, 1);
    expect(find.text('Carteirinha do Atleta'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.controller.close();
  });
}
