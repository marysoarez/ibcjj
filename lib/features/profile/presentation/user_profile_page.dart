import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'drawer_widget.dart';
import 'profile_view_model.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ProfileViewModel>();
    final user = model.user;
    final activation = user.ativacao?.toLowerCase() ?? '';
    // Existing validity policy is preserved; changing the year is a separate rule.
    final localValid =
        activation.contains('2025') || activation.contains('vitalício');
    final isValid = model.cardAccess?.allowed ?? localValid;
    final accessMessage = model.cardAccess?.message ??
        (localValid
            ? user.ativacao ?? 'Carteirinha ativa'
            : 'Carteirinha não ativada ou válida para o ano de 2025.');
    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(title: const Text('Carteirinha do Atleta')),
      body: Column(children: [
        if (model.busy) const LinearProgressIndicator(),
        if (model.message != null)
          Padding(
              padding: const EdgeInsets.all(12), child: Text(model.message!)),
        if (model.error != null)
          Padding(
              padding: const EdgeInsets.all(12),
              child: Text(model.error!,
                  style: const TextStyle(color: Colors.red))),
        if (model.cardAccess?.error != null)
          Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                  'Usando a autorização local: ${model.cardAccess!.error!}',
                  style: const TextStyle(color: Colors.deepOrange))),
        if (model.cardAccess?.warning != null)
          Padding(
              padding: const EdgeInsets.all(12),
              child: Text(model.cardAccess!.warning!,
                  style: const TextStyle(color: Colors.deepOrange))),
        Expanded(
            child: Stack(children: [
          Positioned.fill(
              child: Image.asset('lib/assets/images/background_ibcjj.jpg',
                  fit: BoxFit.cover)),
          if (!isValid)
            Center(
                child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    Text(accessMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, color: Colors.black87)),
                    const SizedBox(height: 20),
                    const Text('Clique aqui para regularizar',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.black87)),
                  ]),
            ))
          else
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('lib/assets/images/logo.png',
                        width: 130, height: 130),
                    Center(
                        child: Column(children: [
                      if (model.profileImageUrl != null)
                        ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(model.profileImageUrl!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.person, size: 80)))
                      else
                        const Text('Nenhuma imagem encontrada'),
                      ElevatedButton.icon(
                          onPressed: model.busy ? null : model.editProfileImage,
                          icon: const Icon(Icons.add_a_photo),
                          label: Text(model.profileImageUrl == null
                              ? 'Adicionar Foto'
                              : 'Alterar Foto')),
                    ])),
                    const SizedBox(height: 10),
                    _row('Nome:', user.nome),
                    _row('Graduação:', user.graduacao),
                    _row('Faixa:', user.faixa),
                    _row('Peso:', '${user.peso ?? ''} kg'),
                    _row('Gênero:', user.genero?.toUpperCase()),
                    _row('Nascimento:', user.nascimento),
                    _row('Técnico:', user.tecnico),
                    _row('Equipe:', user.equipe),
                    const SizedBox(height: 10),
                    const Text('Ativado:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(
                        width: double.infinity,
                        child: Card(
                            color: Colors.green,
                            child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(accessMessage,
                                    style: const TextStyle(
                                        fontSize: 18, color: Colors.black))))),
                  ]),
            ),
        ])),
      ]),
    );
  }

  Widget _row(String label, String? value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Flexible(
              child: Card(
                  child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(value ?? '',
                          style: const TextStyle(fontSize: 16))))),
        ],
      );
}
