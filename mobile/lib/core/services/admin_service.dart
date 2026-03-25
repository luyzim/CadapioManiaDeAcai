import '../models/admin_models.dart';
import '../models/order_models.dart';
import 'admin_session_store.dart';
import 'api_client.dart';

class AdminService {
  AdminService({
    ApiClient? apiClient,
    AdminSessionStore? sessionStore,
  })  : _apiClient = apiClient ?? ApiClient(),
        _sessionStore = sessionStore ?? AdminSessionStore();

  final ApiClient _apiClient;
  final AdminSessionStore _sessionStore;

  Future<String?> restoreToken() {
    return _sessionStore.read();
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      await _apiClient.post(
        '/api/admin/login',
        body: <String, dynamic>{
          'email': email,
          'password': password,
        },
      ) as Map,
    );

    final String token = (data['token'] as String? ?? '').trim();
    if (token.isEmpty) {
      throw const ApiFailure(message: 'Falha ao abrir a sessao admin.');
    }

    await _sessionStore.write(token);
    return token;
  }

  Future<void> signOut() {
    return _sessionStore.clear();
  }

  Future<List<AdminDashboardOrder>> fetchDashboardOrders(
    String token, {
    String? status,
  }) async {
    final String path = status == null || status.isEmpty
        ? '/api/admin/orders'
        : '/api/admin/orders?status=${Uri.encodeQueryComponent(status)}';

    final List<dynamic> data = List<dynamic>.from(
      await _apiClient.get(
        path,
        bearerToken: token,
      ) as List<dynamic>? ??
          <dynamic>[],
    );

    return data
        .map(
          (dynamic order) => AdminDashboardOrder.fromMap(
            Map<String, dynamic>.from(order as Map),
          ),
        )
        .toList();
  }

  Future<List<OrderSummary>> fetchPaidOrders(String token) async {
    final List<dynamic> data = List<dynamic>.from(
      await _apiClient.get(
        '/api/admin/paid-orders',
        bearerToken: token,
      ) as List<dynamic>? ??
          <dynamic>[],
    );

    return data
        .map(
          (dynamic order) =>
              OrderSummary.fromMap(Map<String, dynamic>.from(order as Map)),
        )
        .toList();
  }

  Future<List<OrderSummary>> fetchDeliveryOrders(String token) async {
    final List<dynamic> data = List<dynamic>.from(
      await _apiClient.get(
        '/api/admin/delivery-orders',
        bearerToken: token,
      ) as List<dynamic>? ??
          <dynamic>[],
    );

    return data
        .map(
          (dynamic order) =>
              OrderSummary.fromMap(Map<String, dynamic>.from(order as Map)),
        )
        .toList();
  }

  Future<void> updateOrderStatus({
    required String token,
    required String orderId,
    required String status,
  }) async {
    await _apiClient.patch(
      '/api/admin/orders/$orderId/status',
      bearerToken: token,
      body: <String, dynamic>{'status': status},
    );
  }
}
