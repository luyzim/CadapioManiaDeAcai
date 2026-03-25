import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';

class CartStore {
  static const String _cartKey = 'client_cart_items';

  Future<List<CartItem>> read() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final String? storedCart = preferences.getString(_cartKey);

    if (storedCart == null || storedCart.isEmpty) {
      return const <CartItem>[];
    }

    final List<dynamic> decoded = List<dynamic>.from(
      jsonDecode(storedCart) as List<dynamic>,
    );

    return decoded
        .map(
          (dynamic item) =>
              CartItem.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> write(List<CartItem> items) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.setString(
      _cartKey,
      jsonEncode(
        items.map((CartItem item) => item.toMap()).toList(),
      ),
    );
  }

  Future<void> clear() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.remove(_cartKey);
  }
}
