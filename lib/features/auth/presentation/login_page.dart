import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_view_model.dart';
import 'register_page.dart';
import 'reset_password_page.dart';
import '../../../core/validation/form_validators.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
        body: Center(
            child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Image.asset('lib/assets/images/logo.png', height: 160),
              TextFormField(
                  controller: _email,
                  enabled: !auth.busy,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: FormValidators.email),
              TextFormField(
                  controller: _password,
                  enabled: !auth.busy,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  validator: FormValidators.loginPassword),
              const SizedBox(height: 16),
              if (auth.error != null)
                Text(auth.error!, style: const TextStyle(color: Colors.red)),
              if (auth.busy) const LinearProgressIndicator(),
              ElevatedButton(
                  onPressed: auth.busy
                      ? null
                      : () {
                          if (_form.currentState!.validate()) {
                            auth.login(_email.text.trim(), _password.text);
                          }
                        },
                  child: const Text('Entrar')),
              Wrap(alignment: WrapAlignment.center, children: [
                TextButton(
                    onPressed: auth.busy
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const ResetPasswordPage())),
                    child: const Text('Esqueci a senha')),
                TextButton(
                    onPressed: auth.busy
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const RegisterPage())),
                    child: const Text('Cadastrar-se')),
              ]),
            ])),
      ),
    )));
  }
}
