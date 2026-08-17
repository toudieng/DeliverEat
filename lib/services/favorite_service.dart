import '../core/network/api_client.dart';
import '../models/restaurant.dart';

class FavoriteService {
  final ApiClient _client = ApiClient.instance;

  Future<List<Restaurant>> list() async {
    final response = await _client.get('/me/favorites');
    final data = response.data;
    final list = data is List ? data : (data['data'] as List? ?? []);
    return list.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> add(String restaurantId) => _client.post('/me/favorites/$restaurantId');

  Future<void> remove(String restaurantId) => _client.delete('/me/favorites/$restaurantId');
}
