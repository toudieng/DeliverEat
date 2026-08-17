import 'package:flutter/foundation.dart';

import '../models/restaurant.dart';
import '../services/favorite_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoriteService _service = FavoriteService();

  List<Restaurant> favorites = [];
  final Set<String> _favoriteIds = {};
  bool isLoading = false;
  String? errorMessage;

  bool isFavorite(String restaurantId) => _favoriteIds.contains(restaurantId);

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      favorites = await _service.list();
      _favoriteIds
        ..clear()
        ..addAll(favorites.map((r) => r.id));
    } catch (e) {
      errorMessage = "Impossible de charger vos favoris.";
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> toggle(Restaurant restaurant) async {
    final wasFavorite = _favoriteIds.contains(restaurant.id);
    // Optimistic update for a snappy heart animation.
    if (wasFavorite) {
      _favoriteIds.remove(restaurant.id);
      favorites.removeWhere((r) => r.id == restaurant.id);
    } else {
      _favoriteIds.add(restaurant.id);
      favorites = [restaurant, ...favorites];
    }
    notifyListeners();
    try {
      if (wasFavorite) {
        await _service.remove(restaurant.id);
      } else {
        await _service.add(restaurant.id);
      }
    } catch (_) {
      // Roll back on failure.
      if (wasFavorite) {
        _favoriteIds.add(restaurant.id);
        favorites = [restaurant, ...favorites];
      } else {
        _favoriteIds.remove(restaurant.id);
        favorites.removeWhere((r) => r.id == restaurant.id);
      }
      notifyListeners();
    }
  }
}
