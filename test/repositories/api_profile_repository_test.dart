import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ibcjj_flutter/data/api/api_client.dart';
import 'package:ibcjj_flutter/features/auth/data/auth_repository.dart';
import 'package:ibcjj_flutter/features/profile/data/api_profile_repository.dart';
import 'package:ibcjj_flutter/features/profile/data/profile_access_repository.dart';
import 'package:ibcjj_flutter/features/profile/models/user_model.dart';
import '../support/repository_fakes.dart';

void main() {
  const session = AuthSession('uid-1', 'ana@example.com');

  test('API profile and card access override Firestore values safely',
      () async {
    final fallback = FakeProfileRepository()
      ..profile = UserModel(
        uid: 'uid-1',
        email: 'ana@example.com',
        nome: 'Perfil local',
        ativacao: 'vitalício',
        profileImageUrl: 'https://example.test/local-photo.jpg',
      );
    final requests = <http.Request>[];
    final apiClient = ApiClient(
      baseUrl: 'https://api.example.test',
      getIdToken: () async => 'synthetic-id-token',
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/v1/me') {
          return http.Response(
            jsonEncode({
              'uid': 'uid-1',
              'nome': 'Nome da API',
              'email': 'ana@example.com',
              'ativacao': 'Ativo',
              'appsCarteira': ['ibcjj'],
              'acessoVitalicio': false,
              'carteiraValidaAte': '2026-12-31T00:00:00Z',
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'app': 'ibcjj',
            'allowed': true,
            'message': 'Carteirinha válida pela API',
          }),
          200,
        );
      }),
    );
    final repository = ApiProfileRepository(fallback, apiClient);

    final profile = await repository.fetch(session);
    final access =
        (repository as ProfileAccessRepository).cardAccessFor(session.uid);

    expect(profile?.nome, 'Nome da API');
    expect(profile?.profileImageUrl, 'https://example.test/local-photo.jpg');
    expect(access?.allowed, isTrue);
    expect(access?.message, 'Carteirinha válida pela API');
    expect(requests, hasLength(2));
    expect(
      requests.every(
        (request) =>
            request.headers['authorization'] == 'Bearer synthetic-id-token',
      ),
      isTrue,
    );
  });

  test('API failure returns the Firestore profile and visible access error',
      () async {
    final fallback = FakeProfileRepository();
    final repository = ApiProfileRepository(
      fallback,
      ApiClient(
        baseUrl: 'https://api.example.test',
        getIdToken: () async => 'synthetic-id-token',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'statusCode': 503,
              'message': 'Serviço indisponível',
              'requestId': 'request-test',
            }),
            503,
          ),
        ),
      ),
    );

    final profile = await repository.fetch(session);
    final access =
        (repository as ProfileAccessRepository).cardAccessFor(session.uid);

    expect(profile, same(fallback.profile));
    expect(access?.allowed, isNull);
    expect(access?.error, 'Serviço indisponível');
  });

  test('API profile UID mismatch falls back instead of changing account',
      () async {
    final fallback = FakeProfileRepository();
    final repository = ApiProfileRepository(
      fallback,
      ApiClient(
        baseUrl: 'https://api.example.test',
        getIdToken: () async => 'synthetic-id-token',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'uid': 'different-uid'}),
            200,
          ),
        ),
      ),
    );

    final profile = await repository.fetch(session);
    final access =
        (repository as ProfileAccessRepository).cardAccessFor(session.uid);

    expect(profile, same(fallback.profile));
    expect(access?.allowed, isNull);
    expect(access?.error, contains('diferente da sessão'));
  });

  test('API profile can serve when Firestore profile fetch fails', () async {
    final fallback = FakeProfileRepository()
      ..fetchError = StateError('Firestore unavailable');
    final repository = ApiProfileRepository(
      fallback,
      ApiClient(
        baseUrl: 'https://api.example.test',
        getIdToken: () async => 'synthetic-id-token',
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/v1/me') {
            return http.Response(
              jsonEncode({'uid': 'uid-1', 'nome': 'Nome da API'}),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'app': 'ibcjj',
              'allowed': false,
              'message': 'Acesso bloqueado',
            }),
            200,
          );
        }),
      ),
    );

    final profile = await repository.fetch(session);
    final access =
        (repository as ProfileAccessRepository).cardAccessFor(session.uid);

    expect(profile?.nome, 'Nome da API');
    expect(access?.allowed, isFalse);
    expect(access?.warning, contains('perfil'));
  });
}
