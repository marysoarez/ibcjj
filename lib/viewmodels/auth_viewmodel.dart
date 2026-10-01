import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';

class AuthViewModel with ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImagePicker _imagePicker;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('Usuarios');

  AuthViewModel({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    ImagePicker? imagePicker,
    bool restoreSession = true,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _imagePicker = imagePicker ?? ImagePicker() {
    if (restoreSession) _checkUserLoggedIn();
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
        final userDoc = await _users.doc(currentUser.uid).get();
        _user = UserModel.fromMap(
          userDoc.data(),
          documentId: currentUser.uid,
          fallbackEmail: currentUser.email,
        );
        _profileImageUrl = _user!.profileImageUrl;
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
  Future<void> register(
      String email, String password, UserModel userModel) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;

      if (firebaseUser != null) {
        // Gravar dados no Firestore
        final profile = UserModel.forRegistration(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          profile: userModel,
        );
        await _users.doc(firebaseUser.uid).set(profile.toMap());

        _user = profile;
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
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);

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
          await _users.doc(uid).set({
            'uid': uid,
            'profileImageUrl': newImageUrl,
          }, SetOptions(merge: true));
          _profileImageUrl = newImageUrl;
          _user = UserModel.fromMap({
            ...?_user?.toMap(),
            'profileImageUrl': newImageUrl,
          }, documentId: uid, fallbackEmail: currentUser.email);

          // Notificar a mudança
          notifyListeners(); // Garantir que a UI seja atualizada
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
        _user = UserModel.fromMap({
          ...?_user?.toMap(),
          'profileImageUrl': downloadURL,
        }, documentId: currentUser.uid, fallbackEmail: currentUser.email);

        notifyListeners();
      }
    } catch (e) {
      print("Erro ao buscar imagem de perfil: $e");
    }
  }
}
