import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp/whatsapp.dart';

class CertificatesPage extends StatefulWidget {
  @override
  _CertificatesPageState createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  List<Map<String, String>> _certificates = [];

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('Erro: usuário não autenticado.');
      return;
    }
    final ListResult result = await _firebaseStorage.ref('certificados/$userId').listAll();
    final certificates = await Future.wait(result.items.map((item) async {
      final url = await item.getDownloadURL();
      return {'name': item.name, 'url': url};
    }).toList());
    setState(() {
      _certificates = certificates;
    });
  }

  Future<void> _uploadCertificate() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      try {
        await _firebaseStorage.ref('certificados/$userId/$fileName').putFile(file);
        _loadCertificates();
      } catch (e) {
        print('Erro ao fazer upload: $e');
      }
    }
  }

  Future<void> _sendActivationRequest() async {
    const accessToken ='EAAGp6aTb8.....';
    const fromNumberId = '1082772452xxxxx';

    final whatsapp = WhatsApp(accessToken, fromNumberId);
    var res = await whatsapp.sendMessage(
        phoneNumber: '+5521990466071',
        text: "Hello, this is a test message!"
    );
  }



  Future<void> _deleteCertificate(String name) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('Erro: usuário não autenticado.');
      return;
    }
    try {
      await _firebaseStorage.ref('certificados/$userId/$name').delete();
      setState(() {
        _certificates.removeWhere((certificate) => certificate['name'] == name);
      });
    } catch (e) {
      print('Erro ao excluir certificado: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Certificados'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _uploadCertificate,
            child: Text('Adicionar Certificado'),
          ),
          ElevatedButton(
            onPressed: _sendActivationRequest,
            child: Text('Enviar Solicitação de Ativação'),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: _certificates.length,
              itemBuilder: (context, index) {
                final certificate = _certificates[index];
                return Stack(
                  children: [
                    Card(
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              certificate['url']!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              certificate['name']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteCertificate(certificate['name']!),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
