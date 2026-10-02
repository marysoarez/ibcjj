import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/certificate.dart';
import 'certificates_view_model.dart';

class CertificatesPage extends StatelessWidget {
  const CertificatesPage({super.key});

  Future<void> _confirmDelete(BuildContext context, CertificatesViewModel model,
      Certificate item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir certificado?'),
        content: const Text(
            'O arquivo será removido. Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (!context.mounted || confirmed != true || model.busy) return;
    await model.delete(item);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<CertificatesViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Certificados')),
      body: Column(children: [
        Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
          ElevatedButton(
              onPressed: model.busy ? null : model.add,
              child: const Text('Adicionar Certificado')),
          ElevatedButton(
              onPressed: model.busy ? null : model.requestActivation,
              child: const Text('Solicitar ativação pelo WhatsApp')),
        ]),
        const Padding(
            padding: EdgeInsets.all(8),
            child: Text('JPEG, PNG ou WebP • até 5 MB e 20 megapixels')),
        if (model.busy) const LinearProgressIndicator(),
        if (model.message != null)
          Padding(
              padding: const EdgeInsets.all(8), child: Text(model.message!)),
        if (model.error != null) ...[
          Padding(
              padding: const EdgeInsets.all(8),
              child: Text(model.error!,
                  style: const TextStyle(color: Colors.red))),
          TextButton(
              onPressed: model.busy ? null : model.load,
              child: const Text('Atualizar lista')),
        ],
        Expanded(
            child: model.items.isEmpty && !model.busy && model.error == null
                ? const Center(child: Text('Nenhum certificado enviado.'))
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 260,
                            childAspectRatio: .85,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8),
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
                        Text(item.name,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        IconButton(
                            tooltip: 'Excluir certificado',
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: model.busy
                                ? null
                                : () => _confirmDelete(context, model, item)),
                      ]));
                    },
                  )),
      ]),
    );
  }
}
