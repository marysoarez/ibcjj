import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? uid;
  final String? email;
  final String? nome;
  final String? doc;
  final String? equipe;
  final String? faixa;
  final String? graduacao;
  final String? genero;
  final String? nascimento;
  final String? peso;
  final String? tecnico;
  final String? telefone;
  final String? ativacao;
  final DateTime? carteiraValidaAte;
  final bool acessoVitalicio;
  final List<String> appsCarteira;

  const UserModel({
    this.uid,
    this.email,
    this.nome,
    this.doc,
    this.equipe,
    this.faixa,
    this.graduacao,
    this.genero,
    this.nascimento,
    this.peso,
    this.tecnico,
    this.telefone,
    this.ativacao,
    this.carteiraValidaAte,
    this.acessoVitalicio = false,
    this.appsCarteira = const [],
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data) => UserModel(
        uid: data['uid'] as String?,
        email: data['email'] as String?,
        nome: data['nome'] as String?,
        doc: data['doc'] as String?,
        equipe: data['equipe'] as String?,
        faixa: data['faixa'] as String?,
        graduacao: data['graduacao'] as String?,
        genero: (data['genero'] ?? data['gênero']) as String?,
        nascimento: data['nascimento'] as String?,
        peso: data['peso'] as String?,
        tecnico: data['tecnico'] as String?,
        telefone: data['telefone'] as String?,
        ativacao: data['ativacao'] as String?,
        carteiraValidaAte: _dateFromFirestore(data['carteiraValidaAte']),
        acessoVitalicio: data['acessoVitalicio'] == true,
        appsCarteira: (data['appsCarteira'] as List<dynamic>?)
                ?.whereType<String>()
                .map((app) => app.toLowerCase())
                .toList() ??
            const [],
      );

  UserModel copyWith({
    String? uid,
    String? email,
    String? nome,
    String? doc,
    String? equipe,
    String? faixa,
    String? graduacao,
    String? genero,
    String? nascimento,
    String? peso,
    String? tecnico,
    String? telefone,
    String? ativacao,
    DateTime? carteiraValidaAte,
    bool? acessoVitalicio,
    List<String>? appsCarteira,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        nome: nome ?? this.nome,
        doc: doc ?? this.doc,
        equipe: equipe ?? this.equipe,
        faixa: faixa ?? this.faixa,
        graduacao: graduacao ?? this.graduacao,
        genero: genero ?? this.genero,
        nascimento: nascimento ?? this.nascimento,
        peso: peso ?? this.peso,
        tecnico: tecnico ?? this.tecnico,
        telefone: telefone ?? this.telefone,
        ativacao: ativacao ?? this.ativacao,
        carteiraValidaAte: carteiraValidaAte ?? this.carteiraValidaAte,
        acessoVitalicio: acessoVitalicio ?? this.acessoVitalicio,
        appsCarteira: appsCarteira ?? this.appsCarteira,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'nome': nome,
        'doc': doc,
        'equipe': equipe,
        'faixa': faixa,
        'graduacao': graduacao,
        'genero': genero,
        'nascimento': nascimento,
        'peso': peso,
        'tecnico': tecnico,
        'telefone': telefone,
        'ativacao': ativacao,
        'carteiraValidaAte': carteiraValidaAte == null
            ? null
            : Timestamp.fromDate(carteiraValidaAte!),
        'acessoVitalicio': acessoVitalicio,
        'appsCarteira': appsCarteira,
      };

  static DateTime? _dateFromFirestore(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
