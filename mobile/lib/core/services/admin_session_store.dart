import 'package:shared_preferences/shared_preferences.dart';

class AdminSessionStore {
  static const String _tokenKey = 'admin_session_token';

  Future<String?> read() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final String? token = preferences.getString(_tokenKey);

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return token.trim();
  }

  Future<void> write(String token) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token.trim());
  }

  Future<void> clear() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
  }
}
