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

  Future<List<AdminCategory>> fetchCategories(String token) async {
    final List<dynamic> data = List<dynamic>.from(
      await _apiClient.get(
        '/api/admin/categories',
        bearerToken: token,
      ) as List<dynamic>? ??
          <dynamic>[],
    );

    return data
        .map(
          (dynamic category) => AdminCategory.fromMap(
            Map<String, dynamic>.from(category as Map),
          ),
        )
        .toList();
  }

  Future<List<AdminMenuItem>> fetchItems(String token) async {
    final List<dynamic> data = List<dynamic>.from(
      await _apiClient.get(
        '/api/admin/items',
        bearerToken: token,
      ) as List<dynamic>? ??
          <dynamic>[],
    );

    return data
        .map(
          (dynamic item) => AdminMenuItem.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<AdminCategory> createCategory({
    required String token,
    required String name,
  }) async {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      await _apiClient.post(
        '/api/admin/categories',
        bearerToken: token,
        body: <String, dynamic>{
          'name': name,
        },
      ) as Map,
    );

    return AdminCategory.fromMap(data);
  }

  Future<AdminCategory> updateCategory({
    required String token,
    required int categoryId,
    required String name,
  }) async {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      await _apiClient.put(
        '/api/admin/categories/$categoryId',
        bearerToken: token,
        body: <String, dynamic>{
          'name': name,
        },
      ) as Map,
    );

    return AdminCategory.fromMap(data);
  }

  Future<void> deleteCategory({
    required String token,
    required int categoryId,
  }) async {
    await _apiClient.delete(
      '/api/admin/categories/$categoryId',
      bearerToken: token,
    );
  }

  Future<AdminMenuItem> createItem({
    required String token,
    required int categoryId,
    required String name,
    required int priceCents,
    String? shortDescription,
    String? ingredients,
    String? imageUrl,
    required bool active,
  }) async {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      await _apiClient.post(
        '/api/admin/items',
        bearerToken: token,
        body: <String, dynamic>{
          'category_id': categoryId,
          'name': name,
          'short_desc': shortDescription,
          'ingredients': ingredients,
          'price_cents': priceCents,
          'image_url': imageUrl,
          'active': active,
        },
      ) as Map,
    );

    return AdminMenuItem.fromMap(data);
  }

  Future<AdminMenuItem> updateItem({
    required String token,
    required int itemId,
    required int categoryId,
    required String name,
    required int priceCents,
    String? shortDescription,
    String? ingredients,
    String? imageUrl,
    required bool active,
  }) async {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      await _apiClient.put(
        '/api/admin/items/$itemId',
        bearerToken: token,
        body: <String, dynamic>{
          'category_id': categoryId,
          'name': name,
          'short_desc': shortDescription,
          'ingredients': ingredients,
          'price_cents': priceCents,
          'image_url': imageUrl,
          'active': active,
        },
      ) as Map,
    );

    return AdminMenuItem.fromMap(data);
  }

  Future<void> deleteItem({
    required String token,
    required int itemId,
  }) async {
    await _apiClient.delete(
      '/api/admin/items/$itemId',
      bearerToken: token,
    );
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
