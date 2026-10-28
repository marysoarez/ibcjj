import '../model/user_model.dart';

class CardAccessDecision {
  final bool allowed;
  final String message;

  const CardAccessDecision({required this.allowed, required this.message});
}

class CardAccessPolicy {
  static CardAccessDecision evaluate(
    UserModel user, {
    required String app,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final enabledApps = user.appsCarteira.map((value) => value.toLowerCase());
    final appAllowed = user.appsCarteira.isEmpty || enabledApps.contains(app);
    if (!appAllowed) {
      return const CardAccessDecision(
        allowed: false,
        message: 'Carteirinha não liberada para este aplicativo',
      );
    }

    final legacyActivation = _normalize(user.ativacao ?? '');
    if (user.acessoVitalicio || legacyActivation.contains('vitalicio')) {
      return const CardAccessDecision(
        allowed: true,
        message: 'Carteirinha vitalícia',
      );
    }

    if (user.carteiraValidaAte != null) {
      final expiration = _dateOnly(user.carteiraValidaAte!);
      final valid = !expiration.isBefore(today);
      return CardAccessDecision(
        allowed: valid,
        message: valid
            ? 'Carteirinha válida até ${_format(expiration)}'
            : 'Carteirinha vencida em ${_format(expiration)}',
      );
    }

    if ((user.ativacao ?? '').contains('${today.year}')) {
      return CardAccessDecision(
        allowed: true,
        message: 'Carteirinha válida para ${today.year}',
      );
    }
    return CardAccessDecision(
      allowed: false,
      message: 'Carteirinha não ativada para ${today.year}',
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _format(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');
}
