import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';

/// Cart state, structured (no scattered setState across screens).
///
/// Enforces the API's business rule that an order concerns a single
/// restaurant: adding an item from a different restaurant does not clear
/// the cart on its own — [conflictingRestaurant] surfaces so the UI can
/// show a confirmation dialog and call [clearAndAdd] or leave the cart as-is.
class CartProvider extends ChangeNotifier {
  Restaurant? _restaurant;
  final List<CartItem> _items = [];

  Restaurant? get restaurant => _restaurant;
  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  int get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);
  int get deliveryFee => _restaurant?.deliveryFee ?? 0;
  int get total => subtotal + deliveryFee;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Returns the restaurant of an in-progress conflicting add, or null if
  /// the item was added directly (same restaurant, or cart was empty).
  Restaurant? tryAdd(Restaurant restaurant, MenuItem menuItem) {
    if (_restaurant != null && _restaurant!.id != restaurant.id) {
      return restaurant;
    }
    _restaurant = restaurant;
    final existingIndex = _items.indexWhere((e) => e.menuItem.id == menuItem.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(menuItem: menuItem));
    }
    notifyListeners();
    return null;
  }

  void clearAndAdd(Restaurant restaurant, MenuItem menuItem) {
    _items.clear();
    _restaurant = restaurant;
    _items.add(CartItem(menuItem: menuItem));
    notifyListeners();
  }

  void increment(String menuItemId) {
    final item = _items.firstWhere((e) => e.menuItem.id == menuItemId);
    item.quantity++;
    notifyListeners();
  }

  void decrement(String menuItemId) {
    final index = _items.indexWhere((e) => e.menuItem.id == menuItemId);
    if (index < 0) return;
    if (_items[index].quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index].quantity--;
    }
    if (_items.isEmpty) _restaurant = null;
    notifyListeners();
  }

  void remove(String menuItemId) {
    _items.removeWhere((e) => e.menuItem.id == menuItemId);
    if (_items.isEmpty) _restaurant = null;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _restaurant = null;
    notifyListeners();
  }
}
