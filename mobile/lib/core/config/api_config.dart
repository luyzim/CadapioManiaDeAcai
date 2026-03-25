import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _defaultApiPort = String.fromEnvironment(
    'API_PORT',
    defaultValue: '3110',
  );

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    if (kIsWeb) {
      return _resolveWebBaseUrl();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:$_defaultApiPort';
      default:
        return 'http://localhost:$_defaultApiPort';
    }
  }

  static String _resolveWebBaseUrl() {
    final Uri currentUri = Uri.base;
    final String host = currentUri.host.trim().isEmpty
        ? 'localhost'
        : currentUri.host.trim();

    return 'http://$host:$_defaultApiPort';
  }

  static String resolveUrl(String path) {
    final String normalizedPath = path.trim();
    if (normalizedPath.isEmpty) {
      return baseUrl;
    }

    if (normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://')) {
      return normalizedPath;
    }

    if (normalizedPath.startsWith('/')) {
      return '$baseUrl$normalizedPath';
    }

    return '$baseUrl/$normalizedPath';
  }
}
