import 'package:flutter/foundation.dart';

import '../core/services/admin_service.dart';

class AdminSessionController extends ChangeNotifier {
  AdminSessionController(this._adminService);

  final AdminService _adminService;

  String? _token;
  bool _isReady = false;

  String? get token => _token;
  bool get isReady => _isReady;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> restoreSession() async {
    _token = await _adminService.restoreToken();
    _isReady = true;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _token = await _adminService.login(
      email: email,
      password: password,
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    await _adminService.signOut();
    _token = null;
    notifyListeners();
  }
}
