import 'package:final_ibcjj/domain/card_access_policy.dart';
import 'package:final_ibcjj/model/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 10, 16);

  test('validade anual inclui a data final', () {
    final user = UserModel(
      carteiraValidaAte: today,
      appsCarteira: const ['ibcjj'],
    );

    expect(
      CardAccessPolicy.evaluate(user, app: 'ibcjj', now: today).allowed,
      isTrue,
    );
  });

  test('acesso vitalício ainda respeita os aplicativos liberados', () {
    final user = UserModel(
      acessoVitalicio: true,
      appsCarteira: const ['cbjjb'],
    );

    expect(
      CardAccessPolicy.evaluate(user, app: 'ibcjj', now: today).allowed,
      isFalse,
    );
    expect(
      CardAccessPolicy.evaluate(user, app: 'cbjjb', now: today).allowed,
      isTrue,
    );
  });

  test('ativação textual antiga continua compatível', () {
    final user = UserModel(ativacao: 'Ativo 2026');

    expect(
      CardAccessPolicy.evaluate(user, app: 'ibcjj', now: today).allowed,
      isTrue,
    );
  });
}
