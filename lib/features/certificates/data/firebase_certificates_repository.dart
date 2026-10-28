import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/data/firebase_operation.dart';
import '../../../core/data/session_guard.dart';
import '../../../core/data/validated_image.dart';
import '../../../core/errors/app_failure.dart';
import '../models/certificate.dart';
import 'certificates_repository.dart';

class FirebaseCertificatesRepository implements CertificatesRepository {
  final FirebaseStorage _storage;
  final ImagePicker _picker;
  final SessionGuard _session;
  FirebaseCertificatesRepository(this._storage, this._picker,
      {required SessionGuard sessionGuard})
      : _session = sessionGuard;

  @override
  Future<List<Certificate>> list(String uid) => firebaseOperation(() async {
        _session.requireUser(uid);
        final result = await _storage.ref('certificados/$uid').listAll();
        _session.requireUser(uid);
        final items = await Future.wait(result.items.map((item) async {
          _session.requireUser(uid);
          final url = await item.getDownloadURL();
          _session.requireUser(uid);
          return Certificate(name: item.name, url: url);
        }));
        _session.requireUser(uid);
        return items;
      },
          code: 'certificates-load',
          message: 'Não foi possível carregar os certificados.');

  @override
  Future<bool> add(String uid) async {
    _session.requireUser(uid);
    final image = await ValidatedImage.pick(_picker);
    _session.requireUser(uid);
    if (image == null) return false;
    final name = DateTime.now().microsecondsSinceEpoch.toString();
    await firebaseOperation(() async {
      _session.requireUser(uid);
      await _storage.ref('certificados/$uid/$name').putData(
          image.bytes, SettableMetadata(contentType: image.contentType));
      _session.requireUser(uid);
    },
        code: 'certificate-upload',
        message: 'Não foi possível enviar o certificado.');
    return true;
  }

  @override
  Future<void> delete(String uid, String name) => firebaseOperation(() async {
        _session.requireUser(uid);
        if (name.isEmpty || name.contains('/') || name.contains('\\')) {
          throw const AppFailure(
              'certificate-name', 'Certificado inválido. Atualize a lista.');
        }
        await _storage.ref('certificados/$uid/$name').delete();
        _session.requireUser(uid);
      },
          code: 'certificate-delete',
          message: 'Não foi possível excluir o certificado.');
}
