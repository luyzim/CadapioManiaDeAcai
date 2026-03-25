import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:3110';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3110';
      default:
        return 'http://localhost:3110';
    }
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
