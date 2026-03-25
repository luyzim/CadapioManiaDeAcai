import 'package:shared_preferences/shared_preferences.dart';

import '../models/client_session.dart';

class SessionStore {
  static const String _sessionKey = 'client_session';

  Future<ClientSession?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final storedSession = preferences.getString(_sessionKey);

    if (storedSession == null || storedSession.isEmpty) {
      return null;
    }

    return ClientSession.fromJson(storedSession);
  }

  Future<void> write(ClientSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, session.toJson());
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
  }
}
