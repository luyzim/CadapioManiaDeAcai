import 'menu_models.dart';

int _asInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse('$value') ?? 0;
}

class CartItem {
  const CartItem({
    required this.itemId,
    required this.name,
    required this.priceCents,
    required this.quantity,
    this.imageUrl,
    this.shortDescription,
  });

  final int itemId;
  final String name;
  final int priceCents;
  final int quantity;
  final String? imageUrl;
  final String? shortDescription;

  int get subtotalCents => priceCents * quantity;

  CartItem copyWith({
    int? itemId,
    String? name,
    int? priceCents,
    int? quantity,
    String? imageUrl,
    String? shortDescription,
  }) {
    return CartItem(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      priceCents: priceCents ?? this.priceCents,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      shortDescription: shortDescription ?? this.shortDescription,
    );
  }

  factory CartItem.fromMenuItem(MenuItemModel item) {
    return CartItem(
      itemId: item.id,
      name: item.name,
      priceCents: item.priceCents,
      quantity: 1,
      imageUrl: item.imageUrl,
      shortDescription: item.shortDescription,
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      itemId: _asInt(map['item_id']),
      name: (map['name'] as String? ?? '').trim(),
      priceCents: _asInt(map['price_cents']),
      quantity: _asInt(map['quantity']),
      imageUrl: (map['image_url'] as String?)?.trim(),
      shortDescription: (map['short_desc'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'item_id': itemId,
      'name': name,
      'price_cents': priceCents,
      'quantity': quantity,
      'image_url': imageUrl,
      'short_desc': shortDescription,
    };
  }
}
