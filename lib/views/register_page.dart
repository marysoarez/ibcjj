import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Certifique-se de que esta linha esteja presente
import 'package:provider/provider.dart';
import '../model/user_model.dart';
import '../view_model/auth_view_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _docController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _equipeController = TextEditingController();
  final TextEditingController _graduacaoController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _tecnicoController = TextEditingController();

  DateTime? _nascimento;
  String? _faixa;
  String? _genero;

  // Lista de opções
  final List<String> _faixas = [
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
    'Vermelho',
  ];

  final List<String> _generos = [
    'masculino',
    'feminino',
    'Outros',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomeController.dispose();
    _docController.dispose();
    _telefoneController.dispose();
    _equipeController.dispose();
    _graduacaoController.dispose();
    _pesoController.dispose();
    _tecnicoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nascimento ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _nascimento) {
      if (!mounted) return;
      setState(() {
        _nascimento = picked;
      });
    }
  }

  void _register(AuthViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      try {
        UserModel userModel = UserModel(
          uid: '', // UID será gerado pelo Firebase
          email: _emailController.text.trim(),
          nome: _nomeController.text.trim(),
          doc: _docController.text.trim().isEmpty
              ? null
              : _docController.text.trim(),
          equipe: _equipeController.text.trim(),
          faixa: _faixa,
          graduacao: _graduacaoController.text.trim(),
          genero: _genero,
          nascimento:
              DateFormat('yyyy-MM-dd').format(_nascimento!), // Formato de data
          peso: _pesoController.text.trim(),
          tecnico: _tecnicoController.text.trim().isEmpty
              ? null
              : _tecnicoController.text.trim(),
          telefone: _telefoneController.text.trim(),
          appsCarteira: const ['ibcjj'],
        );

        // Cadastrar novo usuário
        await viewModel.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          userModel,
        );

        // Fazer login automaticamente após o cadastro
        await viewModel.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cadastro realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(
            context); // Voltar para a tela anterior ou para a página principal
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erro ao cadastrar: ${_getErrorMessage(e.toString())}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Função para converter mensagens de erro comuns em mensagens em português
  String _getErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Este e-mail já está em uso.';
    } else if (error.contains('invalid-email')) {
      return 'O e-mail informado é inválido.';
    } else if (error.contains('weak-password')) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    } else {
      return 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Registro'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu email';
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
                        return 'Por favor, insira sua senha';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(labelText: 'Nome'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu nome';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _telefoneController,
                    decoration: InputDecoration(
                        labelText: 'Telefone (Formato: (xx) xxxxx-xxxx)'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu telefone';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _docController,
                    decoration: InputDecoration(
                      labelText: 'Documento (opcional)',
                    ),
                  ),
                  TextFormField(
                    controller: _equipeController,
                    decoration: InputDecoration(labelText: 'Equipe'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua equipe';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _tecnicoController,
                    decoration: InputDecoration(
                      labelText: 'Professor ou técnico (opcional)',
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Faixa'),
                    initialValue: _faixa,
                    onChanged: (newValue) {
                      setState(() {
                        _faixa = newValue;
                      });
                    },
                    items: _faixas.map((faixa) {
                      return DropdownMenuItem(
                        value: faixa,
                        child: Text(faixa),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor, selecione sua faixa';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _graduacaoController,
                    decoration: InputDecoration(labelText: 'Graduação'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua graduação';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Gênero'),
                    initialValue: _genero,
                    onChanged: (newValue) {
                      setState(() {
                        _genero = newValue;
                      });
                    },
                    items: _generos.map((genero) {
                      return DropdownMenuItem(
                        value: genero,
                        child: Text(genero),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor, selecione seu gênero';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration:
                        InputDecoration(labelText: 'Data de Nascimento'),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    controller: TextEditingController(
                        text: _nascimento != null
                            ? DateFormat('dd/MM/yyyy').format(_nascimento!)
                            : ''),
                    validator: (value) {
                      if (_nascimento == null) {
                        return 'Por favor, insira sua data de nascimento';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _pesoController,
                    decoration: InputDecoration(labelText: 'Peso (kg)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu peso';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _register(authViewModel),
                    child: Text('Cadastrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
