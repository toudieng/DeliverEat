import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/order_service.dart';
import '../services/order_socket_service.dart';

/// Drives a single order's live status: WebSocket first, falling back to
/// polling `GET /api/orders/:id` whenever the socket is down, and switching
/// back to the socket as soon as it reconnects.
class OrderTrackingProvider extends ChangeNotifier {
  OrderTrackingProvider({required this.orderId, Order? initialOrder}) : order = initialOrder {
    _start();
  }

  final String orderId;
  final OrderService _orderService = OrderService();
  OrderSocketService? _socket;

  Order? order;
  bool isLive = false;

  StreamSubscription<Order>? _orderSub;
  StreamSubscription<bool>? _connectionSub;
  Timer? _pollTimer;

  Future<void> _start() async {
    if (order == null) {
      try {
        order = await _orderService.order(orderId);
        notifyListeners();
      } catch (_) {
        // Will retry through polling below once connection state settles.
      }
    }
    if (order != null && order!.status == OrderStatus.delivered) return;

    final socket = OrderSocketService(orderId: orderId);
    _socket = socket;
    _orderSub = socket.orderUpdates.listen((updated) {
      order = updated;
      notifyListeners();
      if (updated.status == OrderStatus.delivered || updated.status == OrderStatus.cancelled) {
        _stopPolling();
      }
    });
    _connectionSub = socket.connectionState.listen((connected) {
      isLive = connected;
      notifyListeners();
      if (connected) {
        _stopPolling();
      } else {
        _startPolling();
      }
    });
    await socket.connect();
  }

  void _startPolling() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      try {
        final fresh = await _orderService.order(orderId);
        order = fresh;
        notifyListeners();
        if (fresh.status == OrderStatus.delivered || fresh.status == OrderStatus.cancelled) {
          _stopPolling();
        }
      } catch (_) {
        // Keep polling; a transient failure shouldn't stop the loop.
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    _connectionSub?.cancel();
    _pollTimer?.cancel();
    _socket?.dispose();
    super.dispose();
  }
}
