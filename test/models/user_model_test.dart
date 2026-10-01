import 'package:flutter_test/flutter_test.dart';
import 'package:ibcjj_flutter/models/user_model.dart';

void main() {
  group('UserModel contract', () {
    test('round trips every canonical field', () {
      final data = <String, dynamic>{
        'uid': 'athlete-1',
        'email': 'athlete@example.com',
        'nome': 'Atleta',
        'equipe': 'Equipe',
        'faixa': 'Preta',
        'graduacao': '2',
        'genero': 'feminino',
        'nascimento': '1990-01-01',
        'peso': '70.5',
        'tecnico': 'Técnico',
        'telefone': '+5500000000000',
        'ativacao': 'vitalício',
        'profileImageUrl': 'https://example.com/photo.jpg',
      };
      expect(UserModel.fromMap(data).toMap(), data);
    });

    test('reads legacy gender but writes only the canonical key', () {
      final model = UserModel.fromMap({'gênero': 'feminino'});
      expect(model.genero, 'feminino');
      expect(model.toMap()['genero'], 'feminino');
      expect(model.toMap(), isNot(contains('gênero')));
    });

    test('canonical gender wins when both keys exist', () {
      expect(
        UserModel.fromMap({'genero': 'masculino', 'gênero': 'feminino'}).genero,
        'masculino',
      );
    });

    for (final value in [null, '', '  ', 123]) {
      test('legacy gender is used for invalid canonical value $value', () {
        expect(
          UserModel.fromMap({'genero': value, 'gênero': 'feminino'}).genero,
          'feminino',
        );
      });
    }

    test('missing document uses session identity and safe defaults', () {
      final model = UserModel.fromMap(
        null,
        documentId: 'session-uid',
        fallbackEmail: 'session@example.com',
      );
      expect(model.uid, 'session-uid');
      expect(model.email, 'session@example.com');
      expect(model.ativacao, UserModel.pendingActivation);
      expect(model.profileImageUrl, isNull);
      expect(model.nome, '');
      expect(model.genero, '');
      expect(model.toMap()['tecnico'], '');
      expect(model.toMap()['profileImageUrl'], isNull);
    });

    test('empty and null documents share the same defaults', () {
      expect(UserModel.fromMap({}).toMap(), UserModel.fromMap(null).toMap());
      expect(UserModel().toMap(), UserModel.fromMap(null).toMap());
    });

    test('incomplete document preserves available data', () {
      final model = UserModel.fromMap({'nome': 'Ana', 'faixa': 'Azul'});
      expect(model.nome, 'Ana');
      expect(model.faixa, 'Azul');
      expect(model.telefone, '');
      expect(model.nascimento, '');
      expect(model.ativacao, 'pendente');
    });

    test('wrong field types do not crash or grant activation', () {
      final model = UserModel.fromMap({
        'uid': false,
        'nome': ['Ana'],
        'email': 123,
        'faixa': {'value': 'Preta'},
        'ativacao': true,
        'profileImageUrl': 123,
      });
      expect(model.uid, '');
      expect(model.nome, '');
      expect(model.email, '');
      expect(model.faixa, '');
      expect(model.ativacao, 'pendente');
      expect(model.profileImageUrl, isNull);
    });

    test('numeric legacy contact, weight and grade are readable as text', () {
      final model = UserModel.fromMap({
        'peso': 75.5,
        'graduacao': 2,
        'telefone': 123456789,
      });
      expect(model.peso, '75.5');
      expect(model.graduacao, '2');
      expect(model.telefone, '123456789');
    });

    test('document identity overrides inconsistent embedded uid', () {
      final model = UserModel.fromMap(
        {'uid': 'wrong', 'email': 'saved@example.com'},
        documentId: 'correct',
        fallbackEmail: 'session@example.com',
      );
      expect(model.uid, 'correct');
      expect(model.email, 'saved@example.com');
    });

    test('registration uses auth identity and cannot inherit activation', () {
      final model = UserModel.forRegistration(
        uid: 'auth-uid',
        email: 'auth@example.com',
        profile: UserModel(
          uid: 'untrusted',
          email: 'other@example.com',
          nome: 'Ana',
          genero: 'feminino',
          ativacao: 'vitalício',
          profileImageUrl: 'https://example.com/old.jpg',
        ),
      );
      expect(model.uid, 'auth-uid');
      expect(model.email, 'auth@example.com');
      expect(model.nome, 'Ana');
      expect(model.genero, 'feminino');
      expect(model.ativacao, 'pendente');
      expect(model.profileImageUrl, isNull);
      expect(UserModel.fromMap(model.toMap()).toMap(), model.toMap());
    });

    for (final value in [null, '', '   ']) {
      test('empty activation $value defaults to pending', () {
        expect(UserModel.fromMap({'ativacao': value}).ativacao, 'pendente');
        expect(UserModel(ativacao: value).toMap()['ativacao'], 'pendente');
      });
    }

    test('reading existing activation does not reset it', () {
      expect(UserModel.fromMap({'ativacao': '2025'}).ativacao, '2025');
      expect(
          UserModel.fromMap({'ativacao': 'vitalício'}).ativacao, 'vitalício');
    });
  });
}
