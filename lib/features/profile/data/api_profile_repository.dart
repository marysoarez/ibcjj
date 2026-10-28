import '../../../data/api/api_client.dart';
import '../../auth/data/auth_repository.dart';
import '../models/user_model.dart';
import 'profile_access_repository.dart';
import 'profile_repository.dart';

class ApiProfileRepository
    implements ProfileRepository, ProfileAccessRepository {
  final ProfileRepository _fallback;
  final ApiClient? _apiClient;
  final Map<String, ProfileCardAccess> _accessByUid = {};

  ApiProfileRepository(this._fallback, this._apiClient);

  @override
  Future<UserModel?> fetch(AuthSession session) async {
    UserModel? localProfile;
    Object? localFailure;
    StackTrace? localStackTrace;
    try {
      localProfile = await _fallback.fetch(session);
    } catch (failure, stackTrace) {
      localFailure = failure;
      localStackTrace = stackTrace;
    }

    _accessByUid.remove(session.uid);
    final apiClient = _apiClient;
    if (apiClient == null) {
      if (localFailure != null) {
        Error.throwWithStackTrace(localFailure, localStackTrace!);
      }
      return localProfile;
    }

    try {
      final apiProfile = await apiClient.getMe();
      if (apiProfile.uid != session.uid) {
        throw const ApiException(
          'A API retornou um perfil diferente da sessão autenticada.',
          statusCode: 502,
        );
      }

      try {
        final access = await apiClient.getCardAccess(app: 'ibcjj');
        _accessByUid[session.uid] = ProfileCardAccess(
          allowed: access.allowed,
          message: access.message,
          warning: localFailure == null
              ? null
              : 'Os dados locais do perfil não puderam ser carregados do Firebase.',
        );
      } on ApiException catch (failure) {
        _accessByUid[session.uid] = ProfileCardAccess(
          error: failure.message,
        );
      } catch (_) {
        _accessByUid[session.uid] = const ProfileCardAccess(
          error: 'Não foi possível consultar a autorização da API.',
        );
      }

      return apiProfile.toUserModel(
        profileImageUrl: localProfile?.profileImageUrl,
      );
    } on ApiException catch (failure) {
      _accessByUid[session.uid] = ProfileCardAccess(error: failure.message);
      if (localProfile != null) return localProfile;
      if (localFailure != null) {
        Error.throwWithStackTrace(localFailure, localStackTrace!);
      }
      rethrow;
    } catch (_) {
      _accessByUid[session.uid] = const ProfileCardAccess(
        error: 'Não foi possível consultar a API.',
      );
      if (localProfile != null) return localProfile;
      if (localFailure != null) {
        Error.throwWithStackTrace(localFailure, localStackTrace!);
      }
      rethrow;
    }
  }

  @override
  ProfileCardAccess? cardAccessFor(String uid) => _accessByUid[uid];

  @override
  Future<UserModel> saveRegistration(AuthSession session, UserModel profile) =>
      _fallback.saveRegistration(session, profile);

  @override
  Future<String?> updatePhoto(String uid) => _fallback.updatePhoto(uid);
}
