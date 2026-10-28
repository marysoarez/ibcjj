class ProfileCardAccess {
  final bool? allowed;
  final String? message;
  final String? error;
  final String? warning;

  const ProfileCardAccess(
      {this.allowed, this.message, this.error, this.warning});
}

abstract interface class ProfileAccessRepository {
  ProfileCardAccess? cardAccessFor(String uid);
}
