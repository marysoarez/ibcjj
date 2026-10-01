import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/data/auth_repository.dart';
import '../models/user_model.dart';
import 'profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImagePicker _picker;
  FirebaseProfileRepository(this._firestore, this._storage, this._picker);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('Usuarios');

  @override
  Future<UserModel?> fetch(AuthSession session) async {
    final snapshot = await _users.doc(session.uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    final profile = UserModel.fromMap(data,
        documentId: session.uid, fallbackEmail: session.email);
    if (profile.profileImageUrl != null) return profile;
    // Old profiles may only have a Storage image. Optional photo lookup must
    // not turn an otherwise valid profile into an authentication failure.
    try {
      final url = await _storage
          .ref('usuarios/${session.uid}/profile.jpg')
          .getDownloadURL();
      return UserModel.fromMap({...profile.toMap(), 'profileImageUrl': url});
    } on FirebaseException {
      return profile;
    }
  }

  @override
  Future<UserModel> saveRegistration(
      AuthSession session, UserModel profile) async {
    final value = UserModel.forRegistration(
        uid: session.uid, email: session.email ?? '', profile: profile);
    // Retry must not reset activation after a prior write succeeded remotely.
    return _firestore.runTransaction((transaction) async {
      final reference = _users.doc(session.uid);
      final existing = (await transaction.get(reference)).data();
      if (existing != null) {
        return UserModel.fromMap(existing,
            documentId: session.uid, fallbackEmail: session.email);
      }
      transaction.set(reference, value.toMap());
      return value;
    });
  }

  @override
  Future<String?> updatePhoto(String uid) async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    final reference = _storage.ref('usuarios/$uid/profile.jpg');
    await reference.putData(await image.readAsBytes());
    final url = await reference.getDownloadURL();
    await _users
        .doc(uid)
        .set({'uid': uid, 'profileImageUrl': url}, SetOptions(merge: true));
    return url;
  }
}
