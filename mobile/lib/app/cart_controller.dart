import 'package:flutter/foundation.dart';

import '../core/models/cart_item.dart';
import '../core/models/menu_models.dart';
import '../core/services/cart_store.dart';

class CartController extends ChangeNotifier {
  CartController(this._cartStore);

  final CartStore _cartStore;

  List<CartItem> _items = const <CartItem>[];
  bool _isReady = false;

  List<CartItem> get items => _items;
  bool get isReady => _isReady;
  bool get isEmpty => _items.isEmpty;
  int get itemCount =>
      _items.fold<int>(0, (int sum, CartItem item) => sum + item.quantity);
  int get totalCents =>
      _items.fold<int>(0, (int sum, CartItem item) => sum + item.subtotalCents);

  Future<void> restoreCart() async {
    _items = await _cartStore.read();
    _isReady = true;
    notifyListeners();
  }

  Future<void> addItem(MenuItemModel item, {int quantity = 1}) async {
    final int index = _items.indexWhere((CartItem entry) => entry.itemId == item.id);

    if (index >= 0) {
      final CartItem existingItem = _items[index];
      final List<CartItem> nextItems = List<CartItem>.from(_items);
      nextItems[index] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      _items = nextItems;
    } else {
      _items = <CartItem>[
        ..._items,
        CartItem.fromMenuItem(item).copyWith(quantity: quantity),
      ];
    }

    await _persist();
  }

  Future<void> updateQuantity(int itemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(itemId);
      return;
    }

    _items = _items
        .map(
          (CartItem item) => item.itemId == itemId
              ? item.copyWith(quantity: quantity)
              : item,
        )
        .toList();

    await _persist();
  }

  Future<void> removeItem(int itemId) async {
    _items = _items.where((CartItem item) => item.itemId != itemId).toList();
    await _persist();
  }

  Future<void> clear() async {
    _items = const <CartItem>[];
    await _cartStore.clear();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _cartStore.write(_items);
    notifyListeners();
  }
}
