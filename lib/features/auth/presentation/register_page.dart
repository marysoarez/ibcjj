import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../profile/models/user_model.dart';
import 'auth_view_model.dart';

class RegisterPage extends StatefulWidget {
  final bool completingProfile;
  const RegisterPage({super.key, this.completingProfile = false});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _equipe = TextEditingController();
  final _graduacao = TextEditingController();
  final _peso = TextEditingController();
  final _birthText = TextEditingController();
  DateTime? _birth;
  String? _faixa;
  String? _genero;

  static const _faixas = [
    'Branca',
    'Cinza',
    'Amarelo',
    'Laranja',
    'Verde',
    'Azul',
    'Roxo',
    'Marrom',
    'Preta',
    'Preta 1',
    'Preta 2',
    'Preta 3',
    'Preta 4',
    'Preta 5',
    'Preta 6',
    'Preta 7',
    'Preta 8',
    'Preta 9',
    'Preta 10',
    'Coral',
    'Vermelho'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.completingProfile) {
      _email.text = context.read<AuthViewModel>().session?.email ?? '';
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _email,
      _password,
      _nome,
      _telefone,
      _equipe,
      _graduacao,
      _peso,
      _birthText
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final value = await showDatePicker(
        context: context,
        initialDate: _birth ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now());
    if (!mounted || value == null) return;
    setState(() {
      _birth = value;
      _birthText.text = DateFormat('dd/MM/yyyy').format(value);
    });
  }

  Future<void> _submit(AuthViewModel auth) async {
    if (!_form.currentState!.validate()) return;
    final profile = UserModel(
      email: _email.text.trim(),
      nome: _nome.text.trim(),
      telefone: _telefone.text.trim(),
      equipe: _equipe.text.trim(),
      graduacao: _graduacao.text.trim(),
      peso: _peso.text.trim(),
      faixa: _faixa,
      genero: _genero,
      nascimento: DateFormat('yyyy-MM-dd').format(_birth!),
    );
    if (widget.completingProfile) {
      await auth.completeProfile(profile);
      if (mounted && auth.status == AuthStatus.authenticated) {
        Navigator.of(context).pop();
      }
    } else {
      await auth.register(_email.text.trim(), _password.text, profile);
      // The session gate replaces the guest navigator after account creation.
    }
  }

  Widget _field(TextEditingController controller, String label,
          {TextInputType? keyboard,
          bool obscure = false,
          bool enabled = true}) =>
      TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboard,
          obscureText: obscure,
          decoration: InputDecoration(labelText: label),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Preencha $label' : null);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.completingProfile ? 'Completar cadastro' : 'Registro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
            key: _form,
            child: AbsorbPointer(
              absorbing: auth.busy,
              child: Column(children: [
                _field(_email, 'Email',
                    keyboard: TextInputType.emailAddress,
                    enabled: !widget.completingProfile),
                if (!widget.completingProfile)
                  _field(_password, 'Senha', obscure: true),
                _field(_nome, 'Nome'),
                _field(_telefone, 'Telefone', keyboard: TextInputType.phone),
                _field(_equipe, 'Equipe'),
                DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Faixa'),
                    initialValue: _faixa,
                    items: _faixas
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) => setState(() => _faixa = value),
                    validator: (value) =>
                        value == null ? 'Selecione sua faixa' : null),
                _field(_graduacao, 'Graduação'),
                DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Gênero'),
                    initialValue: _genero,
                    items: ['masculino', 'feminino', 'Outros']
                        .map((value) =>
                            DropdownMenuItem(value: value, child: Text(value)))
                        .toList(),
                    onChanged: (value) => setState(() => _genero = value),
                    validator: (value) =>
                        value == null ? 'Selecione seu gênero' : null),
                TextFormField(
                    controller: _birthText,
                    readOnly: true,
                    onTap: _selectDate,
                    decoration:
                        const InputDecoration(labelText: 'Data de Nascimento'),
                    validator: (_) => _birth == null
                        ? 'Informe sua data de nascimento'
                        : null),
                _field(_peso, 'Peso (kg)', keyboard: TextInputType.number),
                const SizedBox(height: 16),
                if (auth.error != null)
                  Text(auth.error!, style: const TextStyle(color: Colors.red)),
                if (auth.busy) const LinearProgressIndicator(),
                ElevatedButton(
                    onPressed: auth.busy ? null : () => _submit(auth),
                    child: Text(widget.completingProfile
                        ? 'Salvar perfil'
                        : 'Cadastrar')),
              ]),
            )),
      ),
    );
  }
}
