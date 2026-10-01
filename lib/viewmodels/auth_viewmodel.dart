  import 'dart:io';

  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:firebase_storage/firebase_storage.dart';
  import 'package:flutter/material.dart';
  import 'package:image_picker/image_picker.dart';
  import '../models/user_model.dart';

  class AuthViewModel with ChangeNotifier {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseStorage _storage = FirebaseStorage.instance;


    AuthViewModel() {
      _checkUserLoggedIn();  // Verifica se o usuário já está logado
    }

    // Função para verificar se o usuário está logado
    void _checkUserLoggedIn() async {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        // Carregar dados do usuário
        await fetchUserData();
        await fetchProfileImage();
      }
    }
    UserModel? _user;
    String? _profileImageUrl;

    UserModel? get user => _user;
    String? get profileImageUrl => _profileImageUrl;

    // Converte FirebaseUser para UserModel
    UserModel? _userFromFirebase(User? user) {
      return user != null ? UserModel(uid: user.uid, email: user.email) : null;
    }


    // Função para obter dados do Firestore
    Future<void> fetchUserData() async {
      try {
        User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          DocumentSnapshot userDoc = await _firestore.collection('Usuarios').doc(currentUser.uid).get();
          _user = UserModel.fromFirestore(userDoc.data() as Map<String, dynamic>);
          notifyListeners();
        }
      } catch (e) {
        throw e;
      }
    }

    // Função para obter a imagem do perfil no Firebase Storage
    // Future<void> fetchProfileImage() async {
    //   try {
    //     User? currentUser = _auth.currentUser;
    //     if (currentUser != null) {
    //       String downloadURL = await _storage.ref('usuarios/${currentUser.uid}/profile.jpg').getDownloadURL();
    //       _profileImageUrl = downloadURL;
    //       notifyListeners();
    //     }
    //   } catch (e) {
    //     throw e;
    //   }
    // }



    // Login
    Future<void> login(String email, String password) async {
      try {
        UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        _user = _userFromFirebase(result.user);
        await fetchUserData(); // Buscar dados adicionais do Firestore
        await fetchProfileImage(); // Buscar imagem do perfil
        notifyListeners();
      } catch (e) {
        throw e;
      }
    }

    // Desconectar
    Future<void> logout() async {
      await _auth.signOut();
      _user = null;
      _profileImageUrl = null;
      notifyListeners();
    }

    // Registrar novo usuário
    Future<void> register(String email, String password, UserModel userModel) async {
      try {
        UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        User? firebaseUser = result.user;

        if (firebaseUser != null) {
          // Gravar dados no Firestore
          await _firestore.collection('Usuarios').doc(firebaseUser.uid).set({
            'uid': firebaseUser.uid,
            'email': userModel.email,
            'nome': userModel.nome,
            'equipe': userModel.equipe,
            'faixa': userModel.faixa,
            'graduacao': userModel.graduacao,
            'genero': userModel.genero,
            'nascimento': userModel.nascimento,
            'peso': userModel.peso,
            'tecnico': userModel.tecnico,
            'telefone': userModel.telefone,
            'ativacao': userModel.ativacao,
          });

          _user = _userFromFirebase(firebaseUser);
          await fetchProfileImage();
          notifyListeners();
        }
      } catch (e) {
        throw e;
      }
    }

    // Resetar a senha
    Future<void> resetPassword(String email) async {
      try {
        await _auth.sendPasswordResetEmail(email: email);
      } catch (e) {
        throw e;
      }
    }
// Função para editar a imagem do perfil
    // Função para editar a imagem do perfil
    Future<void> editProfileImage() async {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);

        if (image != null) {
          User? currentUser = _auth.currentUser;
          if (currentUser != null) {
            final String uid = currentUser.uid;
            final String fileName = "profile.jpg";
            final ref = _storage.ref('usuarios/$uid/$fileName');

            // Upload da nova imagem (sobrescreve a antiga)
            await ref.putFile(File(image.path));

            // Obter o novo URL de download
            String newImageUrl = await ref.getDownloadURL();

            // Atualizar URL da imagem e Firestore
            _profileImageUrl = newImageUrl;
            await _firestore.collection('usuarios').doc(uid).update({
              'profileImageUrl': newImageUrl,
            });

            // Notificar a mudança
            notifyListeners();  // Garantir que a UI seja atualizada
          }
        }
      } catch (e) {
        print('Erro ao editar a imagem: $e');
        throw e;
      }
    }



// Função para buscar a imagem de perfil
    Future<void> fetchProfileImage() async {
      try {
        User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          final String uid = currentUser.uid;
          final String fileName = "profile.jpg";
          final ref = _storage.ref('usuarios/$uid/$fileName');

          // Obtendo a URL de download
          String downloadURL = await ref.getDownloadURL();
          _profileImageUrl = downloadURL;

          notifyListeners();
        }
      } catch (e) {
        print("Erro ao buscar imagem de perfil: $e");
      }
    }





  }
