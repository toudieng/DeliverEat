enum OrderStatus { pending, confirmed, preparing, delivering, delivered, cancelled, unknown }

OrderStatus orderStatusFromString(String? value) {
  switch (value) {
    case 'pending':
      return OrderStatus.pending;
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'preparing':
      return OrderStatus.preparing;
    case 'delivering':
      return OrderStatus.delivering;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
    case 'canceled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.unknown;
  }
}

/// Canonical progression used to render the tracking timeline.
const List<OrderStatus> kOrderProgression = [
  OrderStatus.pending,
  OrderStatus.confirmed,
  OrderStatus.preparing,
  OrderStatus.delivering,
  OrderStatus.delivered,
];

class OrderStatusEvent {
  final OrderStatus status;
  final DateTime? timestamp;

  const OrderStatusEvent({required this.status, this.timestamp});

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) => OrderStatusEvent(
        status: orderStatusFromString(json['status'] as String?),
        timestamp: DateTime.tryParse((json['timestamp'] ?? json['at'] ?? '').toString()),
      );
}

class OrderLineItem {
  final String menuItemId;
  final String name;
  final int quantity;
  final int price;

  const OrderLineItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> json) => OrderLineItem(
        menuItemId: (json['menuItemId'] ?? json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        quantity: (json['quantity'] is num) ? (json['quantity'] as num).toInt() : 0,
        price: (json['price'] is num) ? (json['price'] as num).round() : 0,
      );
}

class Order {
  final String id;
  final String restaurantId;
  final String? restaurantName;
  final List<OrderLineItem> items;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final String deliveryAddress;
  final String? notes;
  final OrderStatus status;
  final List<OrderStatusEvent> statusHistory;
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.restaurantId,
    this.restaurantName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryAddress,
    this.notes,
    required this.status,
    this.statusHistory = const [],
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: (json['id'] ?? '').toString(),
        restaurantId: (json['restaurantId'] ?? json['restaurant']?['id'] ?? '').toString(),
        restaurantName: (json['restaurantName'] ?? json['restaurant']?['name']) as String?,
        items: (json['items'] as List? ?? [])
            .map((e) => OrderLineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: _asInt(json['subtotal']),
        deliveryFee: _asInt(json['deliveryFee']),
        total: _asInt(json['total']),
        deliveryAddress: (json['deliveryAddress'] ?? '').toString(),
        notes: json['notes'] as String?,
        status: orderStatusFromString(json['status'] as String?),
        statusHistory: (json['statusHistory'] as List? ?? [])
            .map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      );

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool get canCancel => status == OrderStatus.pending;
}
