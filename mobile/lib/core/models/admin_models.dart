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

class AdminDashboardOrder {
  const AdminDashboardOrder({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.totalItems,
    this.customerName,
    this.customerTable,
  });

  final String id;
  final String status;
  final DateTime? createdAt;
  final int totalItems;
  final String? customerName;
  final String? customerTable;

  factory AdminDashboardOrder.fromMap(Map<String, dynamic> map) {
    return AdminDashboardOrder(
      id: '${map['id'] ?? ''}',
      status: _asString(map['status']),
      createdAt: _parseDateTime(map['created_at']),
      totalItems: _asInt(map['total_items']),
      customerName: _asString(map['customer_name']).isEmpty
          ? null
          : _asString(map['customer_name']),
      customerTable: _asString(map['customer_table']).isEmpty
          ? null
          : _asString(map['customer_table']),
    );
  }
}
