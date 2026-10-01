import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ibcjj_flutter/viewmodels/auth_viewmodel.dart';
import 'package:ibcjj_flutter/views/login_page.dart';
import 'package:ibcjj_flutter/views/user_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthViewModel()),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Login',
              home: Consumer<AuthViewModel>(
                builder: (context, viewModel, child) {
                  return viewModel.user == null ? LoginPage() : UserProfilePage();
                },
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text("Erro ao inicializar o Firebase: ${snapshot.error}"),
              ),
            ),
          );
        }

        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}