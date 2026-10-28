import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class CertificatesPage extends StatefulWidget {
  const CertificatesPage({super.key});

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _certificates = [];
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  CollectionReference<Map<String, dynamic>>? get _certificatesCollection {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;
    return _firestore
        .collection('Usuarios')
        .doc(userId)
        .collection('certificados');
  }

  Future<void> _loadCertificates() async {
    final collection = _certificatesCollection;
    if (collection == null) {
      _showMessage('Usuário não autenticado.', isError: true);
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final result =
          await collection.orderBy('createdAt', descending: true).get();
      final certificates = result.docs
          .map(
            (document) => <String, dynamic>{
              'id': document.id,
              ...document.data(),
            },
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _certificates = certificates;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Não foi possível carregar os certificados.', isError: true);
    }
  }

  Future<void> _uploadCertificate() async {
    final collection = _certificatesCollection;
    if (collection == null) {
      _showMessage('Usuário não autenticado.', isError: true);
      return;
    }
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 40,
    );
    if (pickedFile == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await pickedFile.readAsBytes();
      final encodedImage = base64Encode(bytes);
      if (encodedImage.length > 700000) {
        throw Exception('image-too-large');
      }
      await collection.add({
        'name': pickedFile.name,
        'imageBase64': encodedImage,
        'mimeType': pickedFile.mimeType ?? 'image/jpeg',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _loadCertificates();
      _showMessage('Certificado adicionado com sucesso.');
    } catch (error) {
      _showMessage(
        error.toString().contains('image-too-large')
            ? 'A imagem ficou muito grande. Escolha uma imagem menor.'
            : 'Não foi possível adicionar o certificado.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteCertificate(String id) async {
    final collection = _certificatesCollection;
    if (collection == null) return;
    try {
      await collection.doc(id).delete();
      if (!mounted) return;
      setState(() {
        _certificates.removeWhere((certificate) => certificate['id'] == id);
      });
      _showMessage('Certificado excluído.');
    } catch (_) {
      _showMessage('Não foi possível excluir o certificado.', isError: true);
    }
  }

  Future<void> _sendActivationRequest() async {
    if (_certificates.isEmpty) {
      _showMessage(
        'Adicione ao menos um certificado ou comprovante.',
        isError: true,
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Usuário não autenticado.', isError: true);
      return;
    }

    setState(() => _isSending = true);
    try {
      final request = await _firestore.collection('SolicitacoesAtivacao').add({
        'userId': user.uid,
        'email': user.email,
        'certificateIds': _certificates
            .map((certificate) => certificate['id'] as String)
            .toList(),
        'certificateCount': _certificates.length,
        'status': 'pendente',
        'requestedAt': FieldValue.serverTimestamp(),
      });
      final message = Uri.encodeComponent(
        'Olá, enviei ${_certificates.length} certificado(s) pelo aplicativo '
        'Carteira digital IBCJJ para solicitar a ativação.\n\n'
        'Meu UID: ${user.uid}\nProtocolo: ${request.id}',
      );
      final whatsappUrl = Uri.parse(
        'https://api.whatsapp.com/send?phone=5521981198541&text=$message',
      );
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
      _showMessage('Solicitação de ativação registrada com sucesso.');
    } catch (_) {
      _showMessage(
        'Não foi possível registrar a solicitação de ativação.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _openIbcjjSite() async {
    final url = Uri.parse(
      'https://www.ibcjj.com/product-page/carteira-digital-do-atleta',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showMessage('Não foi possível abrir o site da IBCJJ.', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Uint8List? _decodeImage(String? encodedImage) {
    if (encodedImage == null || encodedImage.isEmpty) return null;
    try {
      return base64Decode(encodedImage);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Certificados')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Faça a requisição e o pagamento da ativação no site da IBCJJ. '
                'Depois, adicione os certificados e o comprovante abaixo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _openIbcjjSite,
                child: const Text('Ir para o site da IBCJJ'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadCertificate,
                icon: _isUploading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate),
                label: Text(
                  _isUploading
                      ? 'Adicionando...'
                      : 'Adicionar certificado ou comprovante',
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _isSending ? null : _sendActivationRequest,
                icon: _isSending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isSending ? 'Enviando...' : 'Enviar solicitação de ativação',
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _certificates.isEmpty
                        ? const Center(
                            child: Text('Nenhum certificado adicionado.'))
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _certificates.length,
                            itemBuilder: (context, index) {
                              final certificate = _certificates[index];
                              final bytes = _decodeImage(
                                certificate['imageBase64'] as String?,
                              );
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: bytes == null
                                          ? const Icon(Icons.broken_image,
                                              size: 48)
                                          : Image.memory(bytes,
                                              fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        color: Colors.black54,
                                        padding: const EdgeInsets.all(6),
                                        child: Text(
                                          certificate['name'] as String? ??
                                              'Certificado',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton.filled(
                                        icon: const Icon(Icons.delete),
                                        color: Colors.white,
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () => _deleteCertificate(
                                          certificate['id'] as String,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
