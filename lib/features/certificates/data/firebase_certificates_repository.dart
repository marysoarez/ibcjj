import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/certificate.dart';
import 'certificates_repository.dart';

class FirebaseCertificatesRepository implements CertificatesRepository {
  final FirebaseStorage _storage;
  final ImagePicker _picker;
  FirebaseCertificatesRepository(this._storage, this._picker);

  @override
  Future<List<Certificate>> list(String uid) async {
    final result = await _storage.ref('certificados/$uid').listAll();
    return Future.wait(result.items.map((item) async =>
        Certificate(name: item.name, url: await item.getDownloadURL())));
  }

  @override
  Future<bool> add(String uid) async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return false;
    final name = DateTime.now().microsecondsSinceEpoch.toString();
    await _storage
        .ref('certificados/$uid/$name')
        .putData(await image.readAsBytes());
    return true;
  }

  @override
  Future<void> delete(String uid, String name) =>
      _storage.ref('certificados/$uid/$name').delete();
}
