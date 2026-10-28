class FormValidators {
  static String? requiredText(String? value, String label, {int max = 120}) {
    if (value == null || value.trim().isEmpty) return 'Preencha $label.';
    if (value.trim().length > max) {
      return '$label deve ter no máximo $max caracteres.';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 254 ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  static String? loginPassword(String? value) =>
      value == null || value.isEmpty ? 'Informe sua senha.' : null;

  static String? newPassword(String? value) => value == null || value.length < 6
      ? 'Use uma senha com pelo menos 6 caracteres.'
      : null;

  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[+()\d\s.-]+$').hasMatch(text) ||
        digits.length < 10 ||
        digits.length > 15) {
      return 'Informe um telefone com DDD (10 a 15 dígitos).';
    }
    return null;
  }

  static String? weight(String? value) {
    final weight = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (weight == null || !weight.isFinite || weight <= 0 || weight > 500) {
      return 'Informe um peso maior que zero e até 500 kg.';
    }
    return null;
  }

  static String? grade(String? value) {
    final grade = int.tryParse((value ?? '').trim());
    return grade == null || grade < 0 || grade > 10
        ? 'Informe uma graduação inteira entre 0 e 10.'
        : null;
  }
}
