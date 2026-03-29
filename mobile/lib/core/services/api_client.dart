import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiFailure implements Exception {
  const ApiFailure({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const Duration _requestTimeout = Duration(seconds: 15);

  final http.Client _client;

  Future<dynamic> get(
    String path, {
    String? bearerToken,
    Map<String, String>? headers,
  }) {
    final Uri uri = _buildUri(path);
    return _send(
      uri,
      () => _client.get(
        uri,
        headers: _buildHeaders(
          bearerToken: bearerToken,
          headers: headers,
        ),
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
    Map<String, String>? headers,
  }) {
    final Uri uri = _buildUri(path);
    return _send(
      uri,
      () => _client.post(
        uri,
        headers: _buildHeaders(
          bearerToken: bearerToken,
          headers: headers,
        ),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
    Map<String, String>? headers,
  }) {
    final Uri uri = _buildUri(path);
    return _send(
      uri,
      () => _client.patch(
        uri,
        headers: _buildHeaders(
          bearerToken: bearerToken,
          headers: headers,
        ),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
    Map<String, String>? headers,
  }) {
    final Uri uri = _buildUri(path);
    return _send(
      uri,
      () => _client.put(
        uri,
        headers: _buildHeaders(
          bearerToken: bearerToken,
          headers: headers,
        ),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> delete(
    String path, {
    String? bearerToken,
    Map<String, String>? headers,
  }) {
    final Uri uri = _buildUri(path);
    return _send(
      uri,
      () => _client.delete(
        uri,
        headers: _buildHeaders(
          bearerToken: bearerToken,
          headers: headers,
        ),
      ),
    );
  }

  Map<String, String> _buildHeaders({
    String? bearerToken,
    Map<String, String>? headers,
  }) {
    final Map<String, String> allHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    if (bearerToken != null && bearerToken.isNotEmpty) {
      allHeaders['Authorization'] = 'Bearer $bearerToken';
    }

    return allHeaders;
  }

  Uri _buildUri(String path) {
    return Uri.parse('${ApiConfig.baseUrl}$path');
  }

  Future<dynamic> _send(
    Uri uri,
    Future<http.Response> Function() request,
  ) async {
    late final http.Response response;

    try {
      response = await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw ApiFailure(
        message:
            'Tempo esgotado ao conectar ao servidor em ${uri.origin}. '
            'Verifique se o backend esta ativo.',
      );
    } on Exception {
      throw ApiFailure(
        message:
            'Nao foi possivel conectar ao servidor em ${uri.origin}. '
            'Verifique se o backend esta ativo e se o IP configurado esta correto.',
      );
    }

    final dynamic data = _decodeBody(response.body);

    if (response.statusCode >= 400) {
      final String message = switch (data) {
        final Map<String, dynamic> map =>
          (map['error'] as String? ?? 'Falha ao comunicar com o servidor.')
              .trim(),
        _ => 'Falha ao comunicar com o servidor.',
      };

      throw ApiFailure(
        message: message,
        statusCode: response.statusCode,
      );
    }

    return data;
  }

  dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } on FormatException {
      throw const ApiFailure(
        message: 'O servidor respondeu em um formato inesperado.',
      );
    }
  }
}
