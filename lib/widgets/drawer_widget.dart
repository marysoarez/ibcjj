import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ibcjj_flutter/views/certificates_page.dart';
import '../viewmodels/auth_viewmodel.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.red.shade700),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto do perfil
                CircleAvatar(
                  radius: 30,
                  backgroundImage: authViewModel.profileImageUrl != null
                      ? NetworkImage(authViewModel.profileImageUrl!)
                      : const AssetImage('assets/default_profile.jpg') as ImageProvider,
                ),
                const SizedBox(height: 10),
                // Nome do usuário
                Text(
                  authViewModel.user?.nome ?? "Nome não disponível",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                // Faixa do usuário
                Text(
                  "Faixa: ${authViewModel.user?.faixa ?? "Não especificada"}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),

              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.checklist_rtl),
            title: const Text('Certificados'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CertificatesPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () async {
              await authViewModel.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
          // ElevatedButton.icon(
          //   onPressed: () async {
          //     await authViewModel.logout();
          //     Navigator.of(context).pushReplacementNamed('/login');
          //   },
          //   icon: const Icon(Icons.logout),
          //   label: const Text('Sair'),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: Colors.redAccent,
          //   ),
          // ),
        ],
      ),
    );
  }
}
