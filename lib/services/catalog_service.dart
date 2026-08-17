import '../core/network/api_client.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../models/paginated_response.dart';
import '../models/restaurant.dart';

class CatalogService {
  final ApiClient _client = ApiClient.instance;

  Future<List<FoodCategory>> categories() async {
    final response = await _client.get('/categories');
    final data = response.data;
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list.map((e) => FoodCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PaginatedResponse<Restaurant>> restaurants({
    String? search,
    String? category,
    bool? openOnly,
    String? sort,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _client.get('/restaurants', query: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty) 'category': category,
      if (openOnly == true) 'open': true,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      'page': page,
      'limit': limit,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      Restaurant.fromJson,
    );
  }

  Future<Restaurant> restaurant(String id) async {
    final response = await _client.get('/restaurants/$id');
    return Restaurant.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MenuItem>> menu(String restaurantId) async {
    final response = await _client.get('/restaurants/$restaurantId/menu');
    final data = response.data;
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list.map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
