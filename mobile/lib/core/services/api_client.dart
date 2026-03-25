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

  final http.Client _client;

  Future<dynamic> get(
    String path, {
    String? bearerToken,
    Map<String, String>? headers,
  }) {
    return _send(
      () => _client.get(
        Uri.parse('${ApiConfig.baseUrl}$path'),
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
    return _send(
      () => _client.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
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
    return _send(
      () => _client.patch(
        Uri.parse('${ApiConfig.baseUrl}$path'),
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
    return _send(
      () => _client.delete(
        Uri.parse('${ApiConfig.baseUrl}$path'),
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

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response = await request();
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

    return jsonDecode(body);
  }
}
