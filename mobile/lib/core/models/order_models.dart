DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse('$value');
}

int _asInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse('$value') ?? 0;
}

String _asString(dynamic value) => (value as String? ?? '').trim();

class OrderLineItem {
  const OrderLineItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPriceCents,
    this.imageUrl,
  });

  final int itemId;
  final String name;
  final int quantity;
  final int unitPriceCents;
  final String? imageUrl;

  int get subtotalCents => quantity * unitPriceCents;

  factory OrderLineItem.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> nestedItem = Map<String, dynamic>.from(
      map['items'] as Map? ?? <String, dynamic>{},
    );

    return OrderLineItem(
      itemId: _asInt(map['item_id']),
      name: _asString(map['name']).isNotEmpty
          ? _asString(map['name'])
          : _asString(nestedItem['name']),
      quantity: _asInt(map['qty']),
      unitPriceCents: _asInt(map['unit_price_cents']),
      imageUrl: (_asString(map['image_url']).isNotEmpty
              ? _asString(map['image_url'])
              : _asString(nestedItem['image_url']))
          .trim()
          .isEmpty
          ? null
          : (_asString(map['image_url']).isNotEmpty
              ? _asString(map['image_url'])
              : _asString(nestedItem['image_url'])),
    );
  }
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.status,
    required this.totalCents,
    required this.createdAt,
    this.customerName,
    this.customerTable,
    this.totalItems,
    this.items = const <OrderLineItem>[],
  });

  final String id;
  final String status;
  final int totalCents;
  final DateTime? createdAt;
  final String? customerName;
  final String? customerTable;
  final int? totalItems;
  final List<OrderLineItem> items;

  factory OrderSummary.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawItems =
        List<dynamic>.from(map['items'] as List<dynamic>? ?? <dynamic>[]);

    return OrderSummary(
      id: '${map['id'] ?? ''}',
      status: _asString(map['status']),
      totalCents: _asInt(map['total_cents']),
      createdAt: _parseDateTime(map['created_at']),
      customerName: _asString(map['customer_name']).isEmpty
          ? null
          : _asString(map['customer_name']),
      customerTable: _asString(map['customer_table']).isEmpty
          ? null
          : _asString(map['customer_table']),
      totalItems: map['total_items'] == null ? null : _asInt(map['total_items']),
      items: rawItems
          .map((dynamic item) => OrderLineItem.fromMap(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
    );
  }
}

class OrderDetails {
  const OrderDetails({
    required this.id,
    required this.status,
    required this.totalCents,
    required this.items,
    required this.createdAt,
    this.customerName,
    this.customerTable,
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryState,
    this.deliveryZipCode,
  });

  final String id;
  final String status;
  final int totalCents;
  final List<OrderLineItem> items;
  final DateTime? createdAt;
  final String? customerName;
  final String? customerTable;
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? deliveryState;
  final String? deliveryZipCode;

  factory OrderDetails.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawItems = List<dynamic>.from(
      map['order_items'] as List<dynamic>? ?? <dynamic>[],
    );

    return OrderDetails(
      id: '${map['id'] ?? ''}',
      status: _asString(map['status']),
      totalCents: _asInt(map['total_cents']),
      createdAt: _parseDateTime(map['created_at']),
      customerName: _asString(map['customer_name']).isEmpty
          ? null
          : _asString(map['customer_name']),
      customerTable: _asString(map['customer_table']).isEmpty
          ? null
          : _asString(map['customer_table']),
      deliveryAddress: _asString(map['delivery_address']).isEmpty
          ? null
          : _asString(map['delivery_address']),
      deliveryCity: _asString(map['delivery_city']).isEmpty
          ? null
          : _asString(map['delivery_city']),
      deliveryState: _asString(map['delivery_state']).isEmpty
          ? null
          : _asString(map['delivery_state']),
      deliveryZipCode: _asString(map['delivery_zip_code']).isEmpty
          ? null
          : _asString(map['delivery_zip_code']),
      items: rawItems
          .map((dynamic item) => OrderLineItem.fromMap(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
    );
  }
}

class CreatedOrder {
  const CreatedOrder({
    required this.id,
    required this.status,
    required this.totalCents,
  });

  final String id;
  final String status;
  final int totalCents;

  factory CreatedOrder.fromMap(Map<String, dynamic> map) {
    return CreatedOrder(
      id: '${map['id'] ?? ''}',
      status: _asString(map['status']),
      totalCents: _asInt(map['total_cents']),
    );
  }
}
