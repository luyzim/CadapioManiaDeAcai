import 'package:flutter/foundation.dart';

import '../core/models/client_session.dart';
import '../core/services/auth_service.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._authService);

  final AuthService _authService;

  ClientSession? _session;
  bool _isReady = false;

  ClientSession? get session => _session;
  bool get isReady => _isReady;
  bool get isAuthenticated => _session != null;

  Future<void> restoreSession() async {
    _session = await _authService.restoreSession();
    _isReady = true;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _session = await _authService.login(
      email: email,
      password: password,
    );
    notifyListeners();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    _session = await _authService.signUp(
      name: name,
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirmPassword,
    );
    notifyListeners();
  }

  Future<String> requestPasswordReset({required String email}) {
    return _authService.requestPasswordReset(email: email);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _session = null;
    notifyListeners();
  }
}
