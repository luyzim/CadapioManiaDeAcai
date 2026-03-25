import '../models/order_models.dart';
import 'api_client.dart';

class OrdersService {
  OrdersService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<OrderSummary>> fetchMyOrders(String token) async {
    final List<dynamic> data = List<dynamic>.from(
      await _apiClient.get(
        '/api/client/my-orders',
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

  Future<OrderDetails> fetchOrderDetails(String orderId) async {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      await _apiClient.get('/api/orders/$orderId') as Map,
    );

    return OrderDetails.fromMap(data);
  }

  Future<CreatedOrder> createOrder({
    required String token,
    required String customerName,
    String? customerTable,
    String? deliveryAddress,
    String? deliveryCity,
    String? deliveryState,
    String? deliveryZipCode,
    required List<Map<String, dynamic>> items,
  }) async {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      await _apiClient.post(
        '/api/orders',
        bearerToken: token,
        body: <String, dynamic>{
          'customer_name': customerName,
          'customer_table': customerTable,
          'delivery_address': deliveryAddress,
          'delivery_city': deliveryCity,
          'delivery_state': deliveryState,
          'delivery_zip_code': deliveryZipCode,
          'items': items,
        },
      ) as Map,
    );

    return CreatedOrder.fromMap(data);
  }

  Future<void> confirmDelivery(String orderId) async {
    await _apiClient.post('/api/orders/$orderId/confirm-delivery');
  }
}
