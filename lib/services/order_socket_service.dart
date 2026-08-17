import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/config/api_config.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/order.dart';

/// Connects to `wss://…/ws?token=<accessToken>` and streams [Order] updates
/// for a single order. Reconnects automatically with a fresh access token
/// (the URL-embedded token expires like any other) and exposes a
/// [connectionState] the UI can use to fall back to polling.
class OrderSocketService {
  OrderSocketService({required this.orderId});

  final String orderId;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  bool _disposed = false;
  int _retryAttempt = 0;

  final _orderController = StreamController<Order>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<Order> get orderUpdates => _orderController.stream;

  /// true = connected, false = disconnected (UI should start/keep polling).
  Stream<bool> get connectionState => _connectionController.stream;

  Future<void> connect() async {
    if (_disposed) return;
    final token = await SecureStorageService.instance.accessToken;
    if (token == null) {
      _connectionController.add(false);
      return;
    }
    try {
      final uri = Uri.parse('${ApiConfig.wsBaseUrl}/ws').replace(queryParameters: {'token': token});
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;
      if (_disposed) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _retryAttempt = 0;
      _connectionController.add(true);
      _subscription = channel.stream.listen(
        _handleMessage,
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      if (json['type'] == 'order_update' && json['order'] != null) {
        final order = Order.fromJson(json['order'] as Map<String, dynamic>);
        if (order.id == orderId) {
          _orderController.add(order);
        }
      }
    } catch (_) {
      // Ignore malformed frames.
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _connectionController.add(false);
    _subscription?.cancel();
    _retryAttempt = (_retryAttempt + 1).clamp(1, 5);
    final delay = Duration(seconds: _retryAttempt * 2);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, connect);
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    await _orderController.close();
    await _connectionController.close();
  }
}
