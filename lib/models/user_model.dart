class UserModel {
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
    this.ativacao,
  });

  // Criar um factory para construir o UserModel a partir do Firestore
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      nome: data['nome'],
      equipe: data['equipe'],
      faixa: data['faixa'],
      graduacao: data['graduacao'],
      genero: data['gênero'],
      nascimento: data['nascimento'],
      peso: data['peso'] ,
      tecnico: data['tecnico'],
      telefone: data['telefone'],
      ativacao: data['ativacao'],
    );
  }
}
