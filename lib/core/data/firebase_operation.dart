import 'package:firebase_core/firebase_core.dart';
import '../errors/app_failure.dart';

Future<T> firebaseOperation<T>(
  Future<T> Function() action, {
  required String code,
  required String message,
}) async {
  try {
    return await action();
  } on AppFailure {
    rethrow;
  } catch (error, stack) {
    final detail = error is FirebaseException
        ? switch (error.code) {
            'permission-denied' ||
            'unauthorized' =>
              ' Verifique sua permissão de acesso.',
            'unauthenticated' => ' Entre novamente para continuar.',
            'unavailable' ||
            'network-request-failed' ||
            'retry-limit-exceeded' =>
              ' Confira sua conexão e tente novamente.',
            'quota-exceeded' =>
              ' O armazenamento está indisponível no momento.',
            _ => '',
          }
        : '';
    Error.throwWithStackTrace(AppFailure(code, '$message$detail'), stack);
  }
}
