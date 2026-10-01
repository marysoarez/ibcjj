import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../viewmodels/firebase_auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cadastrar"),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Sign UP"),
              SizedBox(
                height: 30,
              ),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "UserName",
                ),
                obscureText: false,
              ),
              SizedBox(
                height: 30,
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                ),
                obscureText: false,
              ),
              SizedBox(
                height: 30,
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "PassWord",
                ),
                obscureText: true,
              ),
              SizedBox(
                height: 30,
              ),
              ElevatedButton(
                onPressed: _signUp,
                child: Text("Criar"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _signUp() async {
    String username = _usernameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;

    User? user = await _auth.signUpWithEmailAndPassword(email, password);
    if (user != null) {
      print("Usuario Criado");
      Navigator.pushNamed(context, "/home");
    } else {
      print("fail");
    }
  }
}
