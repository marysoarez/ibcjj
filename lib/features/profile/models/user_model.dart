class UserModel {
  static const pendingActivation = 'pendente';

  final String? uid;
  final String? email;
  final String? nome;
  final String? equipe;
  final String? faixa;
  final String? graduacao;
  final String? genero;
  final String? nascimento;
  final String? peso;
  final String? tecnico;
  final String? telefone;
  final String? ativacao;
  final String? profileImageUrl;

  UserModel({
    this.uid,
    this.email,
    this.nome,
    this.equipe,
    this.faixa,
    this.graduacao,
    this.genero,
    this.nascimento,
    this.peso,
    this.tecnico,
    this.telefone,
    this.ativacao = pendingActivation,
    this.profileImageUrl,
  });

  /// Missing documents/fields become empty text and a pending activation.
  /// The document ID is authoritative; the session email is a fallback.
  factory UserModel.fromMap(
    Map<String, dynamic>? data, {
    String? documentId,
    String? fallbackEmail,
  }) {
    final fields = data ?? const <String, dynamic>{};
    final email = _text(fields['email']);
    final genero = _text(fields['genero']);
    final ativacao = _text(fields['ativacao']);
    return UserModel(
      uid: documentId ?? _text(fields['uid']),
      email: email.isNotEmpty ? email : _text(fallbackEmail),
      nome: _text(fields['nome']),
      equipe: _text(fields['equipe']),
      faixa: _text(fields['faixa']),
      graduacao: _text(fields['graduacao'], allowNumber: true),
      genero: genero.isNotEmpty ? genero : _text(fields['gênero']),
      nascimento: _text(fields['nascimento']),
      peso: _text(fields['peso'], allowNumber: true),
      tecnico: _text(fields['tecnico']),
      telefone: _text(fields['telefone'], allowNumber: true),
      ativacao: ativacao.isNotEmpty ? ativacao : pendingActivation,
      profileImageUrl: _optionalText(fields['profileImageUrl']),
    );
  }

  /// Registration always starts pending, even if the caller supplied activation.
  factory UserModel.forRegistration({
    required String uid,
    required String email,
    required UserModel profile,
  }) {
    return UserModel.fromMap({
      ...profile.toMap(),
      'uid': uid,
      'email': email,
      'ativacao': pendingActivation,
      'profileImageUrl': null,
    });
  }

  Map<String, dynamic> toMap() => {
        'uid': _text(uid),
        'email': _text(email),
        'nome': _text(nome),
        'equipe': _text(equipe),
        'faixa': _text(faixa),
        'graduacao': _text(graduacao),
        'genero': _text(genero),
        'nascimento': _text(nascimento),
        'peso': _text(peso),
        'tecnico': _text(tecnico),
        'telefone': _text(telefone),
        'ativacao': _optionalText(ativacao) ?? pendingActivation,
        'profileImageUrl': _optionalText(profileImageUrl),
      };

  static String _text(Object? value, {bool allowNumber = false}) {
    if (value is String) return value.trim();
    if (allowNumber && value is num && value.isFinite) return value.toString();
    return '';
  }

  static String? _optionalText(Object? value) {
    final text = _text(value);
    return text.isEmpty ? null : text;
  }
}
