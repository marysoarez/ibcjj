import 'package:flutter/material.dart';
import 'package:ibcjj_flutter/views/register_page.dart';
import 'package:ibcjj_flutter/views/reset_password_page.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _equipeController = TextEditingController();
  final TextEditingController _faixaController = TextEditingController();
  final TextEditingController _graduacaoController = TextEditingController();
  final TextEditingController _generoController = TextEditingController();
  final TextEditingController _nascimentoController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _tecnicoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _ativacaoController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomeController.dispose();
    _equipeController.dispose();
    _faixaController.dispose();
    _graduacaoController.dispose();
    _generoController.dispose();
    _nascimentoController.dispose();
    _pesoController.dispose();
    _tecnicoController.dispose();
    _telefoneController.dispose();
    _ativacaoController.dispose();

    super.dispose();
  }

  // Função de login
  void _login(AuthViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      try {
        await viewModel.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login com sucesso!')));
        // Redirecionar para outra página
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      print('$e');
      }
    }
  }

  // Função de cadastro
  void _register(AuthViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      try {
        // Criando o objeto UserModel com os dados do usuário
        UserModel userModel = UserModel(
          uid: '', // O Firebase irá gerar automaticamente o UID
          email: _emailController.text.trim(),
          nome: _nomeController.text.trim(),
          equipe: _equipeController.text.trim(),
          faixa: _faixaController.text.trim(),
          graduacao: _graduacaoController.text.trim(),
          genero: _generoController.text.trim(),
          nascimento: DateTime.parse(_nascimentoController.text.trim()).toIso8601String(), // Convertendo para string
          peso: _pesoController.text.trim(), // Conversão para double
          tecnico: _tecnicoController.text.trim(),
          telefone: _telefoneController.text.trim(),
          ativacao: _ativacaoController.text.trim(), // ou outro valor que você deseja
        );

        // Chamando a função register com todos os 3 parâmetros
        await viewModel.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          userModel, // Passando o objeto UserModel criado
        );

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cadastro realizado com sucesso!')));
        // Redirecionar para outra página ou outra ação após o cadastro
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  // Função de resetar senha
  void _resetPassword(AuthViewModel viewModel) async {
    if (_emailController.text.isNotEmpty) {
      try {
        await viewModel.resetPassword(_emailController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email de recuperação enviado!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Consumer<AuthViewModel>(
          builder: (context, viewModel, child) {
            return Form(
              key: _formKey,
              child: Column( crossAxisAlignment: CrossAxisAlignment.center,mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Image.asset('lib/assets/images/logo.png'),

                  // Container para os campos de login e botão de entrar
                  Container(
                    padding: EdgeInsets.all(16.0), // Ajuste o padding conforme necessário
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.center,mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(labelText: 'Email'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe seu email';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(labelText: 'Senha'),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe sua senha';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _login(viewModel),
                          child: Text('Entrar'),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),

                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround,crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ResetPasswordPage()),
                          );
                        },
                        child: Text('Esqueci a senha'),
                      ),
                      SizedBox(width: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterPage()),
                          );
                        },
                        child: Text('Cadastrar-se'),
                      ),
                    ],
                  ),

                ],
              ),
            );
          },
        ),
      ),
    );
  }}
