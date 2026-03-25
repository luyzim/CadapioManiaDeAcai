import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/client_session.dart';
import 'session_store.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    http.Client? client,
    SessionStore? sessionStore,
  })  : _client = client ?? http.Client(),
        _sessionStore = sessionStore ?? SessionStore();

  final http.Client _client;
  final SessionStore _sessionStore;

  Future<ClientSession?> restoreSession() {
    return _sessionStore.read();
  }

  Future<ClientSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _post(
      '/api/client/login',
      <String, dynamic>{
        'email': email,
        'password': password,
      },
    );

    final session = ClientSession.fromMap(data);
    await _sessionStore.write(session);
    return session;
  }

  Future<ClientSession> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final data = await _post(
      '/api/client/signup',
      <String, dynamic>{
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );

    final session = ClientSession.fromMap(data);
    await _sessionStore.write(session);
    return session;
  }

  Future<String> requestPasswordReset({required String email}) async {
    final data = await _post(
      '/api/client/forgot-password',
      <String, dynamic>{'email': email},
    );

    return (data['message'] as String? ?? 'Solicitacao enviada com sucesso.')
        .trim();
  }

  Future<void> signOut() {
    return _sessionStore.clear();
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}$path');
    late final http.Response response;

    try {
      response = await _client
          .post(
            url,
            headers: const <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw AuthFailure(
        'Nao foi possivel conectar ao servidor em ${ApiConfig.baseUrl}. '
        'Verifique se o backend esta ativo e se o IP configurado esta correto.',
      );
    }

    Map<String, dynamic> data = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        data = Map<String, dynamic>.from(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } on FormatException {
        throw const AuthFailure(
          'O servidor respondeu em um formato inesperado.',
        );
      }
    }

    if (response.statusCode >= 400) {
      throw AuthFailure(
        (data['error'] as String? ?? 'Falha ao comunicar com o servidor.')
            .trim(),
      );
    }

    return data;
  }
}
