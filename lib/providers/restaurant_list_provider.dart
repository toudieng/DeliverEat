import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/storage/local_cache_service.dart';
import '../models/category.dart';
import '../models/restaurant.dart';
import '../services/catalog_service.dart';

enum LoadState { idle, loading, loadingMore, loaded, empty, error }

class RestaurantListProvider extends ChangeNotifier {
  final CatalogService _catalogService = CatalogService();

  List<Restaurant> restaurants = [];
  List<FoodCategory> categories = [];
  LoadState state = LoadState.idle;
  String? errorMessage;
  bool isOffline = false;

  String search = '';
  String? categoryId;
  String sort = 'rating';

  int _page = 1;
  bool _hasNextPage = true;

  bool get isLoadingMore => state == LoadState.loadingMore;

  Future<void> bootstrap() async {
    unawaited(_loadCategories());
    await refresh();
  }

  Future<void> _loadCategories() async {
    try {
      categories = await _catalogService.categories();
      notifyListeners();
    } catch (_) {
      // Non-critical: the home screen still works without category chips.
    }
  }

  Future<void> refresh() async {
    _page = 1;
    _hasNextPage = true;
    state = LoadState.loading;
    isOffline = false;
    notifyListeners();
    try {
      final response = await _catalogService.restaurants(
        search: search,
        category: categoryId,
        sort: sort,
        page: _page,
      );
      restaurants = response.data;
      _hasNextPage = response.meta.hasNextPage;
      state = restaurants.isEmpty ? LoadState.empty : LoadState.loaded;
      if (search.isEmpty && categoryId == null) {
        unawaited(_cacheRestaurants(restaurants));
      }
    } on ApiException catch (e) {
      final cached = await _loadCachedRestaurants();
      if (cached.isNotEmpty && e.code == 'NETWORK_ERROR') {
        restaurants = cached;
        isOffline = true;
        state = LoadState.loaded;
      } else {
        errorMessage = e.friendlyMessage;
        state = LoadState.error;
      }
    } catch (_) {
      errorMessage = "Une erreur inattendue est survenue.";
      state = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasNextPage || state == LoadState.loadingMore || state == LoadState.loading) return;
    state = LoadState.loadingMore;
    notifyListeners();
    try {
      final response = await _catalogService.restaurants(
        search: search,
        category: categoryId,
        sort: sort,
        page: _page + 1,
      );
      _page += 1;
      restaurants = [...restaurants, ...response.data];
      _hasNextPage = response.meta.hasNextPage;
      state = LoadState.loaded;
    } catch (_) {
      // Silently keep current list; user can pull to refresh or scroll again.
      state = LoadState.loaded;
    }
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    refresh();
  }

  void setCategory(String? id) {
    categoryId = categoryId == id ? null : id;
    refresh();
  }

  void setSort(String value) {
    sort = value;
    refresh();
  }

  Future<void> _cacheRestaurants(List<Restaurant> list) async {
    // Store raw-ish maps for offline replay; only fields the model needs.
    await LocalCacheService.instance.cacheRestaurants(list.map((r) => {
          'id': r.id,
          'name': r.name,
          'imageUrl': r.imageUrl,
          'rating': r.rating,
          'deliveryTime': r.deliveryTimeMinutes,
          'deliveryFee': r.deliveryFee,
          'isOpen': r.isOpen,
          'category': r.category,
        }).toList());
  }

  Future<List<Restaurant>> _loadCachedRestaurants() async {
    final cached = await LocalCacheService.instance.cachedRestaurants;
    return cached.map(Restaurant.fromJson).toList();
  }
}
