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

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final String normalized = '$value'.trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
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

class AdminCategory {
  const AdminCategory({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory AdminCategory.fromMap(Map<String, dynamic> map) {
    return AdminCategory(
      id: _asInt(map['id']),
      name: _asString(map['name']),
    );
  }
}

class AdminMenuItem {
  const AdminMenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.priceCents,
    required this.active,
    this.categoryName,
    this.shortDescription,
    this.ingredients,
    this.imageUrl,
  });

  final int id;
  final int categoryId;
  final String name;
  final int priceCents;
  final bool active;
  final String? categoryName;
  final String? shortDescription;
  final String? ingredients;
  final String? imageUrl;

  factory AdminMenuItem.fromMap(Map<String, dynamic> map) {
    return AdminMenuItem(
      id: _asInt(map['id']),
      categoryId: _asInt(map['category_id']),
      name: _asString(map['name']),
      priceCents: _asInt(map['price_cents']),
      active: _asBool(map['active']),
      categoryName: _asString(map['category_name']).isEmpty
          ? null
          : _asString(map['category_name']),
      shortDescription: _asString(map['short_desc']).isEmpty
          ? null
          : _asString(map['short_desc']),
      ingredients: _asString(map['ingredients']).isEmpty
          ? null
          : _asString(map['ingredients']),
      imageUrl: _asString(map['image_url']).isEmpty
          ? null
          : _asString(map['image_url']),
    );
  }
}
