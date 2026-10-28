import 'dart:convert';

import 'package:final_ibcjj/data/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const profileJson = {
    'uid': 'firebase-user-1',
    'nome': 'Atleta',
    'email': 'atleta@example.com',
    'doc': '123',
    'equipe': 'Equipe',
    'tecnico': 'Técnico',
    'nascimento': '2000-01-02',
    'genero': 'Feminino',
    'peso': '60',
    'telefone': '11999999999',
    'faixa': 'Azul',
    'graduacao': '2',
    'ativacao': 'Ativo 2026',
    'carteiraValidaAte': '2026-12-31T00:00:00.000Z',
    'acessoVitalicio': false,
    'appsCarteira': ['IBCJJ', 'cbjjb', 42],
  };

  test('GET /me envia o token no header e converte campos tipados', () async {
    late http.Request capturedRequest;
    final client = ApiClient(
      baseUrl: 'https://api.example.test/',
      getIdToken: () async => 'synthetic-firebase-token',
      httpClient: MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode(profileJson), 200);
      }),
    );

    final profile = await client.getMe();

    expect(capturedRequest.method, 'GET');
    expect(capturedRequest.url.path, '/api/v1/me');
    expect(capturedRequest.url.query, isEmpty);
    expect(capturedRequest.headers['authorization'],
        'Bearer synthetic-firebase-token');
    expect(profile.uid, 'firebase-user-1');
    expect(profile.toUserModel().nome, 'Atleta');
    expect(profile.carteiraValidaAte, DateTime.utc(2026, 12, 31));
    expect(profile.appsCarteira, ['ibcjj', 'cbjjb']);
    client.close();
  });

  test('GET de acesso envia aplicativo como query parameter', () async {
    final client = ApiClient(
      baseUrl: 'https://api.example.test',
      getIdToken: () async => 'token',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/me/card-access');
        expect(request.url.queryParameters, {'app': 'ibcjj'});
        return http.Response(
          jsonEncode({
            'app': 'ibcjj',
            'allowed': true,
            'message': 'Carteirinha ativa',
          }),
          200,
        );
      }),
    );

    final access = await client.getCardAccess(app: 'ibcjj');
    expect(access.allowed, isTrue);
    expect(access.message, 'Carteirinha ativa');
    client.close();
  });

  test('não executa requisição sem um ID token', () async {
    var requestCount = 0;
    final client = ApiClient(
      baseUrl: 'https://api.example.test',
      getIdToken: () async => null,
      httpClient: MockClient((_) async {
        requestCount++;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      client.getMe(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 401),
      ),
    );
    expect(requestCount, 0);
    client.close();
  });

  test('preserva status e requestId dos erros do contrato', () async {
    final client = ApiClient(
      baseUrl: 'https://api.example.test',
      getIdToken: () async => 'token',
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'statusCode': 403,
            'message': 'Acesso negado',
            'requestId': 'req-synthetic-1',
          }),
          403,
        );
      }),
    );

    await expectLater(
      client.getMe(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having((error) => error.requestId, 'requestId', 'req-synthetic-1')
            .having((error) => error.message, 'message', 'Acesso negado'),
      ),
    );
    client.close();
  });

  test('recusa HTTP fora de hosts locais', () {
    expect(
      () => ApiClient(
        baseUrl: 'http://api.example.test',
        getIdToken: () async => 'token',
      ),
      throwsArgumentError,
    );
  });

  test('permite HTTP local somente quando configurado explicitamente', () {
    final client = ApiClient(
      baseUrl: 'http://10.0.2.2:3000',
      getIdToken: () async => 'token',
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );

    expect(client, isA<ApiClient>());
    client.close();
  });

  test('recusa aplicativos não cobertos pelo contrato', () async {
    final client = ApiClient(
      baseUrl: 'https://api.example.test',
      getIdToken: () async => 'token',
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );

    await expectLater(
      client.getCardAccess(app: 'another-app'),
      throwsArgumentError,
    );
    client.close();
  });

  test('encerra a espera quando a API ultrapassa o timeout', () async {
    final client = ApiClient(
      baseUrl: 'https://api.example.test',
      getIdToken: () async => 'token',
      timeout: const Duration(milliseconds: 1),
      httpClient: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      client.getMe(),
      throwsA(isA<ApiException>().having(
        (error) => error.message,
        'message',
        'A API demorou para responder.',
      )),
    );
    client.close();
  });
}
