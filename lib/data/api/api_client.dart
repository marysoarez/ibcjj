import 'dart:async';
import 'dart:convert';

import 'package:ibcjj_flutter/features/profile/models/user_model.dart';
import 'package:http/http.dart' as http;

typedef IdTokenProvider = Future<String?> Function();

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? requestId;

  const ApiException(
    this.message, {
    this.statusCode,
    this.requestId,
  });

  @override
  String toString() => message;
}

class ApiUserProfile {
  final String uid;
  final String? nome;
  final String? email;
  final String? doc;
  final String? equipe;
  final String? tecnico;
  final String? nascimento;
  final String? genero;
  final String? peso;
  final String? telefone;
  final String? faixa;
  final String? graduacao;
  final String? ativacao;
  final DateTime? carteiraValidaAte;
  final bool acessoVitalicio;
  final List<String> appsCarteira;

  const ApiUserProfile({
    required this.uid,
    this.nome,
    this.email,
    this.doc,
    this.equipe,
    this.tecnico,
    this.nascimento,
    this.genero,
    this.peso,
    this.telefone,
    this.faixa,
    this.graduacao,
    this.ativacao,
    this.carteiraValidaAte,
    required this.acessoVitalicio,
    required this.appsCarteira,
  });

  factory ApiUserProfile.fromJson(Map<String, dynamic> json) {
    final uid = json['uid'];
    if (uid is! String || uid.isEmpty) {
      throw const ApiException('Resposta inválida da API: UID ausente.');
    }

    final expiration = json['carteiraValidaAte'];
    DateTime? expirationDate;
    if (expiration is String) {
      expirationDate = DateTime.tryParse(expiration);
      if (expirationDate == null) {
        throw const ApiException(
          'Resposta inválida da API: data de validade inválida.',
        );
      }
    } else if (expiration != null) {
      throw const ApiException(
        'Resposta inválida da API: data de validade inválida.',
      );
    }

    final apps = json['appsCarteira'];
    if (apps != null && apps is! List) {
      throw const ApiException(
        'Resposta inválida da API: lista de aplicativos inválida.',
      );
    }
    final lifetimeAccess = json['acessoVitalicio'];
    if (lifetimeAccess != null && lifetimeAccess is! bool) {
      throw const ApiException(
        'Resposta inválida da API: permissão vitalícia inválida.',
      );
    }

    return ApiUserProfile(
      uid: uid,
      nome: _optionalString(json['nome']),
      email: _optionalString(json['email']),
      doc: _optionalString(json['doc']),
      equipe: _optionalString(json['equipe']),
      tecnico: _optionalString(json['tecnico']),
      nascimento: _optionalString(json['nascimento']),
      genero: _optionalString(json['genero']),
      peso: _optionalString(json['peso']),
      telefone: _optionalString(json['telefone']),
      faixa: _optionalString(json['faixa']),
      graduacao: _optionalString(json['graduacao']),
      ativacao: _optionalString(json['ativacao']),
      carteiraValidaAte: expirationDate,
      acessoVitalicio: lifetimeAccess == true,
      appsCarteira: apps is List
          ? apps.whereType<String>().map((app) => app.toLowerCase()).toList()
          : const [],
    );
  }

  UserModel toUserModel({String? profileImageUrl}) => UserModel.fromMap({
        'uid': uid,
        'nome': nome,
        'email': email,
        'equipe': equipe,
        'tecnico': tecnico,
        'nascimento': nascimento,
        'genero': genero,
        'peso': peso,
        'telefone': telefone,
        'faixa': faixa,
        'graduacao': graduacao,
        'ativacao': ativacao,
        'profileImageUrl': profileImageUrl,
      }, documentId: uid, fallbackEmail: email);
}

class ApiCardAccess {
  final String app;
  final bool allowed;
  final String message;

  const ApiCardAccess({
    required this.app,
    required this.allowed,
    required this.message,
  });

  factory ApiCardAccess.fromJson(Map<String, dynamic> json) {
    final app = json['app'];
    final allowed = json['allowed'];
    final message = json['message'];
    if (app is! String || allowed is! bool || message is! String) {
      throw const ApiException(
        'Resposta inválida da API: autorização da carteirinha.',
      );
    }
    return ApiCardAccess(app: app, allowed: allowed, message: message);
  }
}

class ApiClient {
  final Uri _apiBaseUri;
  final IdTokenProvider _getIdToken;
  final http.Client _httpClient;
  final Duration _timeout;
  final bool _ownsHttpClient;

  ApiClient({
    required String baseUrl,
    required IdTokenProvider getIdToken,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 10),
  })  : _apiBaseUri = _buildApiBaseUri(baseUrl),
        _getIdToken = getIdToken,
        _httpClient = httpClient ?? http.Client(),
        _timeout = timeout,
        _ownsHttpClient = httpClient == null;

  static ApiClient? fromEnvironment({
    required IdTokenProvider getIdToken,
    http.Client? httpClient,
  }) {
    const baseUrl = String.fromEnvironment('API_BASE_URL');
    if (baseUrl.trim().isEmpty) return null;
    return ApiClient(
      baseUrl: baseUrl,
      getIdToken: getIdToken,
      httpClient: httpClient,
    );
  }

  Future<ApiUserProfile> getMe() async {
    final json = await _get('/me');
    return ApiUserProfile.fromJson(json);
  }

  Future<ApiCardAccess> getCardAccess({required String app}) async {
    if (app != 'cbjjb' && app != 'ibcjj') {
      throw ArgumentError.value(app, 'app', 'Aplicativo não suportado.');
    }
    final json = await _get('/me/card-access', queryParameters: {'app': app});
    final access = ApiCardAccess.fromJson(json);
    if (access.app != app) {
      throw const ApiException(
        'A API retornou a autorização de outro aplicativo.',
        statusCode: 502,
      );
    }
    return access;
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final token = await _getIdToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Sessão Firebase não autenticada.',
          statusCode: 401);
    }

    final uri = _apiBaseUri.replace(
      path: '${_apiBaseUri.path}$path',
      queryParameters: queryParameters,
    );
    http.Response response;
    try {
      response = await _httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('A API demorou para responder.');
    } on http.ClientException {
      throw const ApiException('Não foi possível conectar à API.');
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('A API retornou uma resposta inválida.',
          statusCode: 502);
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('A API retornou uma resposta inválida.',
          statusCode: 502);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded['message'];
      final requestId = decoded['requestId'];
      throw ApiException(
        message is String ? message : 'Falha ao consultar a API.',
        statusCode: response.statusCode,
        requestId: requestId is String ? requestId : null,
      );
    }
    return decoded;
  }

  void close() {
    if (_ownsHttpClient) _httpClient.close();
  }

  static Uri _buildApiBaseUri(String baseUrl) {
    final parsed = Uri.tryParse(baseUrl.trim());
    if (parsed == null ||
        !parsed.hasAuthority ||
        parsed.host.isEmpty ||
        parsed.userInfo.isNotEmpty ||
        parsed.hasQuery ||
        parsed.hasFragment) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'URL base inválida.');
    }

    final isLocal = const {
      'localhost',
      '127.0.0.1',
      '::1',
      '10.0.2.2',
    }.contains(parsed.host.toLowerCase());
    if (parsed.scheme != 'https' && !(isLocal && parsed.scheme == 'http')) {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'Use HTTPS fora de um ambiente local.',
      );
    }

    final basePath = parsed.path.replaceFirst(RegExp(r'/+$'), '');
    return parsed.replace(path: '$basePath/api/v1');
  }
}

String? _optionalString(dynamic value) => value is String ? value : null;
