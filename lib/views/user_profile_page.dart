import 'package:flutter/material.dart';
import 'package:ibcjj_flutter/views/login_page.dart';
import 'package:ibcjj_flutter/widgets/drawer_widget.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class UserProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      drawer: DrawerWidget(),
      appBar: AppBar(title: Text('Carteirinha do Atleta')),
      body: Stack(
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
                return Center(child: CircularProgressIndicator());
              }

              final user = viewModel.user!;
              final imageUrl = viewModel.profileImageUrl;
              final ativacao = user.ativacao?.toLowerCase() ?? '';
              // final validacao = user.validacao?.toLowerCase() ?? '';
              final isValid =
                  ativacao.contains('2025') || ativacao.contains('vitalício') ;
                      // validacao.contains('2025') || validacao.contains('vitalício');

              if (!isValid) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 80, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          'Carteirinha não ativada ou válida para o ano de 2025.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),SizedBox(height: 20),
                        Text(
                          'Clique aqui para regularizar ',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('lib/assets/images/logo.png', width: 130, height: 130),
                    Center(
                      child: imageUrl != null
                          ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              imageUrl,
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
                                  print('Erro ao editar a imagem: $e');
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
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
                          Text(
                            'Nenhuma imagem encontrada',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await viewModel.editProfileImage();
                              } catch (e) {
                                print('Erro ao adicionar imagem: $e');
                              }
                            },
                            icon: Icon(Icons.add_a_photo),
                            label: Text('Adicionar Foto'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildInfoRow('Nome:', user.nome),
                    _buildInfoRow('Graduação:', user.graduacao),
                    _buildInfoRow('Faixa:', user.faixa),
                    _buildInfoRow('Peso:', '${user.peso} kg'),
                    _buildInfoRow('Gênero:', user.genero?.toUpperCase()),
                    _buildInfoRow('Nascimento:', user.nascimento),
                    _buildInfoRow('Técnico:', user.tecnico),
                    _buildInfoRow('Equipe:', user.equipe),
                    SizedBox(height: 10),
                    Text('Ativado:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        color: user.ativacao != null ? Colors.green : null,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            '${user.ativacao ?? "Não ativado"}',
                            style: TextStyle(fontSize: 18, color: Colors.black),
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
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(value ?? '', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
