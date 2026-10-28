import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/api/api_client.dart';
import '../domain/card_access_policy.dart';
import '../model/user_model.dart';

class AuthViewModel with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );
  final ApiClient? _apiClient;

  AuthViewModel({ApiClient? apiClient})
      : _apiClient = apiClient ??
            ApiClient.fromEnvironment(
              getIdToken: () async =>
                  FirebaseAuth.instance.currentUser?.getIdToken(),
            ) {
    _checkUserLoggedIn(); // Verifica se o usuário já está logado
  }

  // Função para verificar se o usuário está logado
  void _checkUserLoggedIn() async {
    final firebaseUser = _auth.currentUser;
    _user = _userFromFirebase(firebaseUser);
    try {
      if (firebaseUser != null) {
        await fetchUserData();
        await fetchProfileImage();
      }
    } finally {
      _isRestoringSession = false;
      notifyListeners();
    }
  }

  UserModel? _user;
  String? _profileImageBase64;
  bool _isRestoringSession = true;
  CardAccessDecision? _apiCardAccess;
  String? _apiErrorMessage;

  UserModel? get user => _user;
  String? get profileImageBase64 => _profileImageBase64;
  bool get isRestoringSession => _isRestoringSession;
  CardAccessDecision? get apiCardAccess => _apiCardAccess;
  String? get apiErrorMessage => _apiErrorMessage;

  // Converte FirebaseUser para UserModel
  UserModel? _userFromFirebase(User? user) {
    return user != null ? UserModel(uid: user.uid, email: user.email) : null;
  }

  // Função para obter dados do Firestore
  Future<void> fetchUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    UserModel? apiProfile;
    CardAccessDecision? apiAccess;
    _apiErrorMessage = null;
    _apiCardAccess = null;

    if (_apiClient != null) {
      try {
        final response = await _apiClient.getMe();
        if (response.uid != currentUser.uid) {
          throw const ApiException(
            'A API retornou um perfil diferente da sessão autenticada.',
            statusCode: 502,
          );
        }
        apiProfile = response.toUserModel();

        try {
          final access = await _apiClient.getCardAccess(app: 'ibcjj');
          apiAccess = CardAccessDecision(
            allowed: access.allowed,
            message: access.message,
          );
        } on ApiException catch (error) {
          _apiErrorMessage = error.message;
        } catch (_) {
          _apiErrorMessage = 'Não foi possível consultar a autorização da API.';
        }
      } on ApiException catch (error) {
        _apiErrorMessage = error.message;
      } catch (_) {
        _apiErrorMessage = 'Não foi possível consultar a API.';
      }
    }

    UserModel? firestoreProfile;
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('Usuarios').doc(currentUser.uid).get();
      final data = userDoc.data();
      firestoreProfile = data is Map<String, dynamic>
          ? UserModel.fromFirestore(data)
          : _userFromFirebase(currentUser);
    } catch (_) {
      // Mantém a sessão disponível durante falhas temporárias de rede.
    }

    _user = apiProfile ?? firestoreProfile ?? _userFromFirebase(currentUser);
    _apiCardAccess = apiProfile == null ? null : apiAccess;
    notifyListeners();
  }

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
      rethrow;
    }
  }

  // Desconectar
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _profileImageBase64 = null;
    notifyListeners();
  }

  Future<void> deleteAccount({required String password}) async {
    final currentUser = _auth.currentUser;
    final email = currentUser?.email;

    if (currentUser == null || email == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Não foi possível identificar a conta conectada.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await currentUser.reauthenticateWithCredential(credential);

    // Força a emissão de um token cujo auth_time reflita a reautenticação.
    // A Function recusa tokens antigos e usa exclusivamente o UID autenticado.
    await currentUser.getIdToken(true);
    await _functions.httpsCallable('deleteOwnAccount').call<void>();

    // A conta já foi removida no servidor; limpa a sessão e os dados locais.
    await _auth.signOut();

    _user = null;
    _profileImageBase64 = null;
    notifyListeners();
  }

  // Registrar novo usuário
  Future<void> register(
    String email,
    String password,
    UserModel userModel,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;

      if (firebaseUser != null) {
        // Gravar dados no Firestore
        await _firestore.collection('Usuarios').doc(firebaseUser.uid).set({
          ...userModel.toMap(),
          'uid': firebaseUser.uid,
        });

        _user = _userFromFirebase(firebaseUser);
        await fetchProfileImage();
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Resetar a senha
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Função para editar a imagem do perfil
  // Função para editar a imagem do perfil
  Future<void> editProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 40,
      );

      if (image != null) {
        User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          final bytes = await image.readAsBytes();
          final encodedImage = base64Encode(bytes);
          if (encodedImage.length > 700000) {
            throw Exception(
              'A imagem ficou muito grande. Escolha uma imagem menor.',
            );
          }

          _profileImageBase64 = encodedImage;
          await _firestore.collection('Usuarios').doc(currentUser.uid).set({
            'profileImageBase64': encodedImage,
            'profileImageUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Notificar a mudança
          notifyListeners(); // Garantir que a UI seja atualizada
        }
      }
    } catch (e) {
      debugPrint('Erro ao editar a imagem: $e');
      rethrow;
    }
  }

  // Função para buscar a imagem de perfil
  Future<void> fetchProfileImage() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userDocument =
            await _firestore.collection('Usuarios').doc(currentUser.uid).get();
        final data = userDocument.data();
        _profileImageBase64 = data?['profileImageBase64'] as String?;

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao buscar imagem de perfil: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      // Exemplo: Atualizar usuário no Firestore
      await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(user.uid)
          .update({
        'nome': user.nome,
        'doc': user.doc,
        'equipe': user.equipe,
        'faixa': user.faixa,
        'graduacao': user.graduacao,
        'genero': user.genero,
        'nascimento': user.nascimento,
        'peso': user.peso,
        'telefone': user.telefone,
        'tecnico': user.tecnico,
      });
      await fetchUserData();

      notifyListeners();
    } catch (e) {
      throw Exception("Erro ao atualizar usuário: $e");
    }
  }

  @override
  void dispose() {
    _apiClient?.close();
    super.dispose();
  }
}
