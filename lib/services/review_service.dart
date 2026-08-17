import '../core/network/api_client.dart';
import '../models/paginated_response.dart';
import '../models/review.dart';

class ReviewService {
  final ApiClient _client = ApiClient.instance;

  Future<PaginatedResponse<Review>> reviews(String restaurantId, {int page = 1, int limit = 20}) async {
    final response = await _client.get('/restaurants/$restaurantId/reviews', query: {
      'page': page,
      'limit': limit,
    });
    final data = response.data;
    if (data is Map && data.containsKey('meta')) {
      return PaginatedResponse.fromJson(data as Map<String, dynamic>, Review.fromJson);
    }
    final list = (data is List ? data : (data as Map)['data'] as List? ?? [])
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResponse(
      data: list,
      meta: const PaginationMeta(page: 1, limit: 20, total: 0, totalPages: 1, hasNextPage: false),
    );
  }

  Future<Review> addReview(String restaurantId, {required int rating, required String comment}) async {
    final response = await _client.post('/restaurants/$restaurantId/reviews', data: {
      'rating': rating,
      'comment': comment,
    });
    return Review.fromJson(response.data as Map<String, dynamic>);
  }
}
