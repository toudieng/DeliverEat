import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../services/order_service.dart';

enum OrdersLoadState { idle, loading, loaded, empty, error }

class OrderProvider extends ChangeNotifier {
  final OrderService _service = OrderService();

  List<Order> orders = [];
  OrdersLoadState state = OrdersLoadState.idle;
  String? errorMessage;
  String? statusFilter;

  Future<Order> placeOrder({
    required String restaurantId,
    required List<CartItem> items,
    required String deliveryAddress,
    String? notes,
  }) {
    return _service.createOrder(
      restaurantId: restaurantId,
      items: items,
      deliveryAddress: deliveryAddress,
      notes: notes,
    );
  }

  Future<void> loadOrders() async {
    state = OrdersLoadState.loading;
    notifyListeners();
    try {
      final response = await _service.orders(status: statusFilter);
      orders = response.data;
      state = orders.isEmpty ? OrdersLoadState.empty : OrdersLoadState.loaded;
    } on ApiException catch (e) {
      errorMessage = e.friendlyMessage;
      state = OrdersLoadState.error;
    } catch (_) {
      errorMessage = "Une erreur inattendue est survenue.";
      state = OrdersLoadState.error;
    }
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    statusFilter = status;
    loadOrders();
  }

  Future<String?> cancelOrder(String orderId) async {
    try {
      final updated = await _service.cancel(orderId);
      final index = orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) orders[index] = updated;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.friendlyMessage;
    }
  }
}
