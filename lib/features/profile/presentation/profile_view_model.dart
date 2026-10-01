import 'package:flutter/foundation.dart';
import '../../../core/errors/app_failure.dart';
import '../data/profile_repository.dart';
import '../models/user_model.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;
  UserModel _user;
  bool busy = false;
  String? error;
  bool _disposed = false;
  ProfileViewModel(this._repository, this._user);

  UserModel get user => _user;
  String? get profileImageUrl => _user.profileImageUrl;

  Future<void> editProfileImage() async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final url = await _repository.updatePhoto(_user.uid!);
      if (!_disposed && url != null) {
        _user = UserModel.fromMap({..._user.toMap(), 'profileImageUrl': url});
      }
    } catch (failure) {
      if (!_disposed) {
        error = failureMessage(failure, 'Não foi possível atualizar a foto.');
      }
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
