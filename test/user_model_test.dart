import 'package:ibcjj_flutter/model/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserva os dados do usuário ao converter para mapa', () {
    const user = UserModel(
      uid: 'user-1',
      email: 'atleta@example.com',
      nome: 'Atleta',
      faixa: 'Preta',
    );

    expect(user.toMap(), containsPair('uid', 'user-1'));
    expect(user.toMap(), containsPair('email', 'atleta@example.com'));
    expect(user.toMap(), containsPair('nome', 'Atleta'));
    expect(user.toMap(), containsPair('faixa', 'Preta'));
  });

  test('copyWith altera somente os campos informados', () {
    const original = UserModel(uid: 'user-1', nome: 'Nome antigo');
    final updated = original.copyWith(nome: 'Nome novo');

    expect(updated.uid, original.uid);
    expect(updated.nome, 'Nome novo');
  });
}
