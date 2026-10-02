import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../../certificates/data/certificates_repository.dart';
import '../../certificates/presentation/certificates_page.dart';
import '../../certificates/presentation/certificates_view_model.dart';
import 'profile_view_model.dart';
import '../../certificates/data/activation_contact.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileViewModel>();
    final auth = context.watch<AuthViewModel>();
    return Drawer(
        child: ListView(children: [
      DrawerHeader(
          decoration: BoxDecoration(color: Colors.red.shade700),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
                radius: 30,
                backgroundImage: profile.profileImageUrl == null
                    ? null
                    : NetworkImage(profile.profileImageUrl!),
                child: profile.profileImageUrl == null
                    ? const Icon(Icons.person)
                    : null),
            Text(profile.user.nome ?? '',
                style: const TextStyle(color: Colors.white)),
            Text('Faixa: ${profile.user.faixa ?? ''}',
                style: const TextStyle(color: Colors.white)),
          ])),
      ListTile(
          leading: const Icon(Icons.checklist_rtl),
          title: const Text('Certificados'),
          onTap: () {
            final navigator = Navigator.of(context);
            final repository = context.read<CertificatesRepository>();
            final contact = context.read<ActivationContact>();
            final uid = auth.session!.uid;
            navigator.pop();
            navigator.push(MaterialPageRoute<void>(
                builder: (_) => ChangeNotifierProvider(
                      create: (_) => CertificatesViewModel(repository, uid,
                          contact: contact)
                        ..load(),
                      child: const CertificatesPage(),
                    )));
          }),
      ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sair'),
          onTap: auth.busy
              ? null
              : () {
                  Navigator.of(context).pop();
                  auth.logout();
                }),
    ]));
  }
}
