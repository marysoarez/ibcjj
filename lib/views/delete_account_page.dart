import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../view_model/auth_view_model.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  static final Uri _deletionUrl = Uri.parse(
    'https://www.ibcjj.com/exclusao-de-conta',
  );

  final _passwordController = TextEditingController();
  bool _confirmed = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_confirmed || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confirme a exclusão e informe sua senha.'),
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir conta permanentemente?'),
        content: const Text(
          'Sua conta, perfil, foto e certificados serão excluídos. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir permanentemente'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await context.read<AuthViewModel>().deleteAccount(
            password: _passwordController.text,
          );

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sua conta foi excluída.')));
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'wrong-password' ||
        'invalid-credential' =>
          'Senha incorreta. Confira e tente novamente.',
        'requires-recent-login' =>
          'Entre novamente na conta antes de solicitar a exclusão.',
        _ => error.message ?? 'Não foi possível excluir a conta.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'unauthenticated' =>
          'Sua sessão expirou. Entre novamente antes de excluir a conta.',
        'failed-precondition' =>
          'Confirme novamente sua senha antes de excluir a conta.',
        'unavailable' =>
          'O serviço de exclusão está temporariamente indisponível. Tente novamente.',
        _ =>
          'Não foi possível concluir a exclusão. Nenhum sucesso foi confirmado.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível concluir a exclusão. Tente novamente ou '
            'contate ibcjj.contato@ibcjj.com.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _openDeletionPage() async {
    final opened = await launchUrl(
      _deletionUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a página de exclusão.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Excluir minha conta')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Exclusão permanente',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ao continuar, serão excluídos sua conta de acesso, dados do '
              'perfil, foto, certificados e comprovantes enviados. Esta ação '
              'não pode ser desfeita.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              obscureText: true,
              enabled: !_isDeleting,
              decoration: const InputDecoration(
                labelText: 'Confirme sua senha',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _confirmed,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Entendo que a exclusão é permanente e não pode ser desfeita.',
              ),
              onChanged: _isDeleting
                  ? null
                  : (value) => setState(() => _confirmed = value ?? false),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isDeleting ? null : _deleteAccount,
              icon: _isDeleting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever),
              label: Text(_isDeleting ? 'Excluindo...' : 'Excluir minha conta'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Se não conseguir acessar sua conta, solicite a exclusão pelo '
              'site da IBCJJ ou pelo e-mail ibcjj.contato@ibcjj.com.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _isDeleting ? null : _openDeletionPage,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir página oficial de exclusão'),
            ),
          ],
        ),
      ),
    );
  }
}
