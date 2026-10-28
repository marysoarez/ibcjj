import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../model/user_model.dart';
import '../view_model/auth_view_model.dart';

class EditPage extends StatefulWidget {
  final UserModel user;

  const EditPage({super.key, required this.user});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _telefoneController;
  late TextEditingController _equipeController;
  late TextEditingController _graduacaoController;
  late TextEditingController _pesoController;
  late TextEditingController _tecnicoController; // Novo controller

  DateTime? _nascimento;
  String? _genero;

  final List<String> _generos = ['Masculino', 'Feminino', 'Outros'];

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.user.nome);
    _telefoneController = TextEditingController(text: widget.user.telefone);
    _equipeController = TextEditingController(text: widget.user.equipe);
    _graduacaoController = TextEditingController(text: widget.user.graduacao);
    _pesoController = TextEditingController(text: widget.user.peso);
    _tecnicoController = TextEditingController(
        text: widget.user.tecnico); // Inicializa o novo campo

    _nascimento = widget.user.nascimento != null
        ? DateFormat('yyyy-MM-dd').parse(widget.user.nascimento!)
        : null;
    _genero = widget.user.genero;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _equipeController.dispose();
    _graduacaoController.dispose();
    _pesoController.dispose();
    _tecnicoController.dispose(); // Dispose do novo controller

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

  void _saveChanges(AuthViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      try {
        UserModel updatedUser = widget.user.copyWith(
          nome: _nomeController.text.trim(),
          telefone: _telefoneController.text.trim(),
          equipe: _equipeController.text.trim(),
          graduacao: _graduacaoController.text.trim(),
          tecnico: _tecnicoController.text
              .trim(), // Atualiza o campo técnico: _graduacaoController.text.trim(),
          genero: _genero,
          nascimento: _nascimento != null
              ? DateFormat('yyyy-MM-dd').format(_nascimento!)
              : null,
          peso: _pesoController.text.trim(),
        );

        await viewModel.updateUser(updatedUser);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Dados atualizados com sucesso!'),
              backgroundColor: Colors.green),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao atualizar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Informe seu nome'
                        : null,
                  ),
                  TextFormField(
                    controller: _telefoneController,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Informe seu telefone'
                        : null,
                  ),
                  TextFormField(
                    controller: _equipeController,
                    decoration: const InputDecoration(labelText: 'Equipe'),
                  ),
                  TextFormField(
                    controller: _graduacaoController,
                    decoration: const InputDecoration(labelText: 'Graduação'),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Gênero'),
                    initialValue: _genero,
                    onChanged: (newValue) => setState(() => _genero = newValue),
                    items: _generos.map((genero) {
                      return DropdownMenuItem(
                          value: genero, child: Text(genero));
                    }).toList(),
                    validator: (value) =>
                        value == null ? 'Selecione seu gênero' : null,
                  ),
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Data de Nascimento'),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    controller: TextEditingController(
                      text: _nascimento != null
                          ? DateFormat('dd/MM/yyyy').format(_nascimento!)
                          : '',
                    ),
                  ),
                  TextFormField(
                    controller: _pesoController,
                    decoration: const InputDecoration(labelText: 'Peso (kg)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    // Novo campo técnico
                    controller: _tecnicoController,
                    decoration: const InputDecoration(labelText: 'Técnico'),
                  ),
                  ElevatedButton(
                    onPressed: () => authViewModel.editProfileImage(),
                    child: const Text('Editar Foto de Perfil'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _saveChanges(authViewModel),
                    child: const Text('Salvar Alterações'),
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
