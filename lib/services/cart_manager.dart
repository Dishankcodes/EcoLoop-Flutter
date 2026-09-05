import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartManager extends ChangeNotifier {
  CartManager._();
  static final CartManager instance = CartManager._();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  int get uniqueItemCount => _items.length;

  double get subtotal => _items.fold(
        0,
        (sum, item) => sum + item.price * item.quantity,
      );

  double get delivery => _items.isEmpty ? 0 : (subtotal >= 999 ? 0 : 49);

  double get total => subtotal + delivery;

  CartItem? find(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void addProduct(Map<String, dynamic> product, {int quantity = 1}) {
    addItem(CartItem.fromProduct(product, quantity: quantity));
  }

  void addItem(CartItem newItem) {
    final index = _items.indexWhere((item) => item.id == newItem.id);

    if (index == -1) {
      _items.add(newItem);
    } else {
      final old = _items[index];
      final max = old.availableQuantity;
      final nextQuantity = (old.quantity + newItem.quantity).clamp(1, max);
      _items[index] = old.copyWith(quantity: nextQuantity);
    }

    notifyListeners();
  }

  bool increase(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return false;

    final item = _items[index];
    if (item.quantity >= item.availableQuantity) return false;

    _items[index] = item.copyWith(quantity: item.quantity + 1);
    notifyListeners();
    return true;
  }

  bool decrease(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return false;

    final item = _items[index];
    if (item.quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index] = item.copyWith(quantity: item.quantity - 1);
    }

    notifyListeners();
    return true;
  }

  void remove(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
