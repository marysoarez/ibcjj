// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
//
// class PhotoViewModel {
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   final FirebaseAuth auth = FirebaseAuth.instance;
//   final FirebaseStorage storage = FirebaseStorage.instance;
//   final ImagePicker picker = ImagePicker();
//
//   // Função para alterar a foto do perfil
//   Future<void> updateProfilePhoto() async {
//     final user = auth.currentUser;
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//
//     if (user != null && pickedFile != null) {
//       try {
//         // Define o caminho do arquivo no Firebase Storage
//         final storageRef = storage.ref().child('usuarios/${user.uid}');
//
//         // Faz o upload do arquivo
//         await storageRef.putFile(File(pickedFile.path));
//
//         // Obtém a URL da imagem
//         final downloadUrl = await storageRef.getDownloadURL();
//
//         // Atualiza a URL da foto no Firestore
//         await firestore.collection('users').doc(user.uid).update({
//           'profilePhoto': downloadUrl,
//         });
//       } catch (e) {
//         // Adicione um tratamento de erro aqui, se necessário
//         print("Erro ao fazer upload da foto de perfil: $e");
//       }
//     }
//   }
//
//   // Função para enviar imagem do certificado (permanece a mesma)
//   Future<void> uploadCertificate() async {
//     final user = auth.currentUser;
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//
//     if (user != null && pickedFile != null) {
//       await firestore.collection('certificates').add({
//         'userId': user.uid,
//         'certificateImage': pickedFile.path,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//     }
//   }
//
//   List<PhotoOption> getOptions() {
//     return [
//       PhotoOption(
//         label: "Alterar Foto do Perfil",
//         icon: Icons.person,
//         action: updateProfilePhoto,
//       ),
//       PhotoOption(
//         label: "Enviar Certificado",
//         icon: Icons.certificate,
//         action: uploadCertificate,
//       ),
//     ];
//   }
// }
