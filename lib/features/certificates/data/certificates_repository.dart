import '../models/certificate.dart';

abstract class CertificatesRepository {
  Future<List<Certificate>> list(String uid);
  Future<bool> add(String uid);
  Future<void> delete(String uid, String name);
}
