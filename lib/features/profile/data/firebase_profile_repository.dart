import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/data/firebase_operation.dart';
import '../../../core/data/session_guard.dart';
import '../../../core/data/validated_image.dart';
import '../../auth/data/auth_repository.dart';
import '../models/user_model.dart';
import 'profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImagePicker _picker;
  final SessionGuard _session;
  FirebaseProfileRepository(this._firestore, this._storage, this._picker,
      {required SessionGuard sessionGuard})
      : _session = sessionGuard;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('Usuarios');

  @override
  Future<UserModel?> fetch(AuthSession session) => firebaseOperation(() async {
        _session.requireUser(session.uid);
        final data = (await _users.doc(session.uid).get()).data();
        _session.requireUser(session.uid);
        if (data == null) return null;
        final profile = UserModel.fromMap(data,
            documentId: session.uid, fallbackEmail: session.email);
        if (profile.profileImageUrl != null) return profile;
        try {
          final url = await _storage
              .ref('usuarios/${session.uid}/profile.jpg')
              .getDownloadURL();
          _session.requireUser(session.uid);
          return UserModel.fromMap(
              {...profile.toMap(), 'profileImageUrl': url});
        } on FirebaseException catch (error) {
          _session.requireUser(session.uid);
          if (error.code == 'object-not-found') return profile;
          rethrow;
        }
      },
          code: 'profile-load',
          message: 'Não foi possível carregar os dados ou a foto do perfil.');

  @override
  Future<UserModel> saveRegistration(AuthSession session, UserModel profile) =>
      firebaseOperation(() async {
        _session.requireUser(session.uid);
        final value = UserModel.forRegistration(
            uid: session.uid, email: session.email ?? '', profile: profile);
        final result = await _firestore.runTransaction((transaction) async {
          _session.requireUser(session.uid);
          final reference = _users.doc(session.uid);
          final existing = (await transaction.get(reference)).data();
          _session.requireUser(session.uid);
          if (existing != null) {
            return UserModel.fromMap(existing,
                documentId: session.uid, fallbackEmail: session.email);
          }
          transaction.set(reference, value.toMap());
          return value;
        });
        _session.requireUser(session.uid);
        return result;
      }, code: 'profile-save', message: 'Não foi possível salvar o perfil.');

  @override
  Future<String?> updatePhoto(String uid) async {
    _session.requireUser(uid);
    final image = await ValidatedImage.pick(_picker);
    _session.requireUser(uid);
    if (image == null) return null;
    final reference = _storage.ref('usuarios/$uid/profile.jpg');
    await firebaseOperation(() async {
      _session.requireUser(uid);
      await reference.putData(
          image.bytes, SettableMetadata(contentType: image.contentType));
      _session.requireUser(uid);
    }, code: 'photo-upload', message: 'Não foi possível enviar a foto.');
    final url = await firebaseOperation(() async {
      _session.requireUser(uid);
      final value = await reference.getDownloadURL();
      _session.requireUser(uid);
      return value;
    },
        code: 'photo-url',
        message: 'A foto foi enviada, mas não foi possível obter seu link.');
    await firebaseOperation(() async {
      _session.requireUser(uid);
      await _users
          .doc(uid)
          .set({'uid': uid, 'profileImageUrl': url}, SetOptions(merge: true));
      _session.requireUser(uid);
    },
        code: 'photo-document',
        message:
            'A foto foi enviada, mas o perfil não foi atualizado. Tente novamente.');
    return url;
  }
}
