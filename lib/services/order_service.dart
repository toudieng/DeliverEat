import '../core/network/api_client.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/paginated_response.dart';

class OrderService {
  final ApiClient _client = ApiClient.instance;

  Future<Order> createOrder({
    required String restaurantId,
    required List<CartItem> items,
    required String deliveryAddress,
    String? notes,
  }) async {
    final response = await _client.post('/orders', data: {
      'restaurantId': restaurantId,
      'items': items
          .map((e) => {'menuItemId': e.menuItem.id, 'quantity': e.quantity})
          .toList(),
      'deliveryAddress': deliveryAddress,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PaginatedResponse<Order>> orders({String? status, int page = 1, int limit = 20}) async {
    final response = await _client.get('/orders', query: {
      if (status != null && status.isNotEmpty) 'status': status,
      'page': page,
      'limit': limit,
    });
    final data = response.data;
    if (data is Map && data.containsKey('meta')) {
      return PaginatedResponse.fromJson(data as Map<String, dynamic>, Order.fromJson);
    }
    final list = (data is List ? data : (data as Map)['data'] as List? ?? [])
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResponse(
      data: list,
      meta: const PaginationMeta(page: 1, limit: 20, total: 0, totalPages: 1, hasNextPage: false),
    );
  }

  Future<Order> order(String id) async {
    final response = await _client.get('/orders/$id');
    return Order.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Order> cancel(String id) async {
    final response = await _client.post('/orders/$id/cancel');
    return Order.fromJson(response.data as Map<String, dynamic>);
  }
}
