import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/errors/app_failure.dart';
import 'auth_view_model.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _email = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await auth.resetPassword(_email.text.trim());
      if (mounted) {
        setState(() =>
            _message = 'Instruções de redefinição enviadas para o seu e-mail.');
      }
    } catch (failure) {
      if (mounted) {
        setState(() => _message =
            failureMessage(failure, 'Não foi possível enviar o e-mail.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Redefinir Senha')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
              key: _form,
              child: Column(children: [
                TextFormField(
                    controller: _email,
                    enabled: !_busy,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe seu email'
                        : null),
                if (_message != null) Text(_message!),
                if (_busy) const LinearProgressIndicator(),
                ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: const Text('Enviar Email de Redefinição')),
              ])),
        ),
      );
}
