import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/favorites_provider.dart';
import '../../widgets/restaurant_card.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';
import '../restaurant/restaurant_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      body: RefreshIndicator(
        onRefresh: favorites.load,
        child: Builder(builder: (context) {
          if (favorites.isLoading && favorites.favorites.isEmpty) {
            return const SkeletonList();
          }
          if (favorites.errorMessage != null && favorites.favorites.isEmpty) {
            return ErrorStateView(message: favorites.errorMessage!, onRetry: favorites.load);
          }
          if (favorites.favorites.isEmpty) {
            return const EmptyStateView(
              message: 'Aucun restaurant favori',
              subtitle: 'Appuyez sur le cœur d\'un restaurant pour le retrouver ici.',
              icon: Icons.favorite_border_rounded,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: favorites.favorites.length,
            itemBuilder: (context, index) {
              final restaurant = favorites.favorites[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RestaurantCard(
                  restaurant: restaurant,
                  isFavorite: true,
                  heroTag: 'fav-restaurant-image-${restaurant.id}',
                  onFavoriteTap: () => favorites.toggle(restaurant),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RestaurantDetailScreen(restaurantId: restaurant.id, seed: restaurant),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
