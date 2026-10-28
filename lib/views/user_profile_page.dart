import 'dart:convert';

import 'package:ibcjj_flutter/view_model/auth_view_model.dart';
import 'package:ibcjj_flutter/views/certificates_page.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../widgets/drawer_widget.dart';
import '../domain/card_access_policy.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(title: const Text('Carteirinha do Atleta')),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'lib/assets/images/background_ibcjj.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Consumer<AuthViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.user == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final user = viewModel.user!;
                final imageBase64 = viewModel.profileImageBase64;
                final access = CardAccessPolicy.evaluate(user, app: 'ibcjj');
                final isValid = access.allowed;

                // if (isValid) {
                //   print(ativacao); // ou exiba de outra forma
                // }

                if (!isValid) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 80, color: Colors.grey),
                          const SizedBox(height: 20),
                          Text(
                            access.message,
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(fontSize: 18, color: Colors.black87),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CertificatesPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Clique aqui para regularizar',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'lib/assets/images/logo.png',
                        width: 130,
                        height: 130,
                      ),
                      Center(
                        child: imageBase64 != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.memory(
                                      base64Decode(imageBase64),
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () async {
                                        try {
                                          await viewModel.editProfileImage();
                                        } catch (e) {
                                          debugPrint(
                                              'Erro ao editar a imagem: $e');
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  const Text(
                                    'Nenhuma imagem encontrada',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await viewModel.editProfileImage();
                                      } catch (e) {
                                        debugPrint(
                                            'Erro ao adicionar imagem: $e');
                                      }
                                    },
                                    icon: const Icon(Icons.add_a_photo),
                                    label: const Text('Adicionar Foto'),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow('Nome:', user.nome),
                      _buildInfoRow('Graduação:', user.graduacao),
                      _buildInfoRow('Faixa:', user.faixa),
                      _buildInfoRow('Peso:', '${user.peso} kg'),
                      _buildInfoRow('Gênero:', user.genero?.toUpperCase()),
                      _buildInfoRow('Nascimento:', user.nascimento),
                      _buildInfoRow('Técnico:', user.tecnico),
                      _buildInfoRow('Equipe:', user.equipe),
                      const SizedBox(height: 10),
                      const Text(
                        'Ativado:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          color: user.ativacao != null ? Colors.green : null,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              access.message,
                              style:
                                  const TextStyle(fontSize: 18, color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(value ?? '', style: const TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
