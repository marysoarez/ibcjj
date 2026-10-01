class AppFailure implements Exception {
  final String code;
  final String message;
  const AppFailure(this.code, this.message);

  @override
  String toString() => message;
}

String failureMessage(Object error, String fallback) =>
    error is AppFailure ? error.message : fallback;
