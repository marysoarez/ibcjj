import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../firebase_options.dart';
import '../features/auth/data/firebase_auth_repository.dart';
import '../features/profile/data/firebase_profile_repository.dart';
import '../features/certificates/data/firebase_certificates_repository.dart';
import 'app.dart';
import '../core/data/session_guard.dart';

/// Kept separate from widget builds so rebuilds never reinitialize Firebase.
Future<Widget> bootstrap({
  Future<void> Function()? initialize,
  Widget Function()? createApp,
}) async {
  try {
    await (initialize ?? _initializeFirebase)();
    return (createApp ?? _createApp)();
  } catch (_) {
    return const BootstrapErrorApp();
  }
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Widget _createApp() {
  final storage = FirebaseStorage.instance;
  final picker = ImagePicker();
  final auth = FirebaseAuth.instance;
  final sessionGuard = SessionGuard(() => auth.currentUser?.uid);
  return IbcjjApp(
    authRepository: FirebaseAuthRepository(auth),
    profileRepository: FirebaseProfileRepository(
        FirebaseFirestore.instance, storage, picker,
        sessionGuard: sessionGuard),
    certificatesRepository: FirebaseCertificatesRepository(storage, picker,
        sessionGuard: sessionGuard),
  );
}

class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: Scaffold(
            body: Center(
                child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Não foi possível iniciar o aplicativo. Confira sua conexão e abra o aplicativo novamente.'),
        ))),
      );
}
