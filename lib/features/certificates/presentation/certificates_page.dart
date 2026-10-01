import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'certificates_view_model.dart';

class CertificatesPage extends StatelessWidget {
  const CertificatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CertificatesViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Certificados')),
      body: Column(children: [
        ElevatedButton(
            onPressed: model.busy ? null : model.add,
            child: const Text('Adicionar Certificado')),
        // The previous WhatsApp code used placeholder credentials and a test
        // message. Keep the action visibly unavailable until a real service exists.
        const Tooltip(
            message: 'Solicitação de ativação ainda não disponível.',
            child: ElevatedButton(
                onPressed: null,
                child: Text('Enviar Solicitação de Ativação'))),
        if (model.busy) const LinearProgressIndicator(),
        if (model.error != null) ...[
          Text(model.error!, style: const TextStyle(color: Colors.red)),
          TextButton(
              onPressed: model.busy ? null : model.load,
              child: const Text('Tentar novamente')),
        ],
        Expanded(
            child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: model.items.length,
          itemBuilder: (context, index) {
            final item = model.items[index];
            return Card(
                child: Column(children: [
              Expanded(
                  child: Image.network(item.url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image))),
              Text(item.name),
              IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: model.busy ? null : () => model.delete(item)),
            ]));
          },
        )),
      ]),
    );
  }
}
