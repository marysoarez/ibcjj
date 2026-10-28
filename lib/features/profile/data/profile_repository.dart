import '../../auth/data/auth_repository.dart';
import '../models/user_model.dart';

abstract class ProfileRepository {
  /// Null means that authentication exists but the profile document is missing.
  Future<UserModel?> fetch(AuthSession session);
  Future<UserModel> saveRegistration(AuthSession session, UserModel profile);
  Future<String?> updatePhoto(String uid);
}
