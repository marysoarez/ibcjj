import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/auth_view_model.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/presentation/profile_view_model.dart';
import '../features/profile/presentation/user_profile_page.dart';
import '../features/certificates/data/certificates_repository.dart';

class IbcjjApp extends StatelessWidget {
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final CertificatesRepository certificatesRepository;
  const IbcjjApp(
      {super.key,
      required this.authRepository,
      required this.profileRepository,
      required this.certificatesRepository});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          Provider<ProfileRepository>.value(value: profileRepository),
          Provider<CertificatesRepository>.value(value: certificatesRepository),
          ChangeNotifierProvider(
              create: (_) => AuthViewModel(authRepository, profileRepository)),
        ],
        child: Consumer<AuthViewModel>(
            builder: (context, auth, _) => MaterialApp(
                  // Changing accounts/signing out disposes protected routes and their models.
                  key: ValueKey(auth.session?.uid ?? 'guest'),
                  debugShowCheckedModeBanner: false,
                  title: 'IBCJJ',
                  home: auth.session == null
                      ? (auth.status == AuthStatus.loading && !auth.busy
                          ? const Scaffold(
                              body: Center(child: CircularProgressIndicator()))
                          : const LoginPage())
                      : const _SessionHome(),
                )),
      );
}

class _SessionHome extends StatelessWidget {
  const _SessionHome();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (auth.status == AuthStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.status == AuthStatus.authenticated && auth.user != null) {
      return ChangeNotifierProvider(
        create: (_) =>
            ProfileViewModel(context.read<ProfileRepository>(), auth.user!),
        child: const UserProfilePage(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar perfil')),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(auth.error ?? 'Não foi possível carregar o perfil.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: auth.busy ? null : auth.retryProfile,
            child: Text(auth.hasPendingRegistration
                ? 'Salvar perfil novamente'
                : 'Tentar novamente'),
          ),
          if (auth.profileMissing && !auth.hasPendingRegistration)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) =>
                          const RegisterPage(completingProfile: true))),
              child: const Text('Completar cadastro'),
            ),
          TextButton(
              onPressed: auth.busy ? null : auth.logout,
              child: const Text('Sair')),
        ]),
      )),
    );
  }
}
