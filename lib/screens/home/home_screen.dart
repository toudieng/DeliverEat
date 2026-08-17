import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/debouncer.dart';
import '../../models/restaurant.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/restaurant_list_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/restaurant_card.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';
import '../restaurant/restaurant_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _debouncer = Debouncer();

  static const Map<String, String> _sortOptions = {
    'rating': 'Note',
    'deliveryTime': 'Délai',
    'deliveryFee': 'Frais',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantListProvider>().bootstrap();
      context.read<FavoritesProvider>().load();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) {
      context.read<RestaurantListProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantListProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    final strings = context.watch<LocaleProvider>().strings;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline || provider.isOffline) OfflineBanner(message: strings.t('offline')),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Livraison à', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Dakar, Sénégal', style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: strings.t('search'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            context.read<RestaurantListProvider>().setSearch('');
                            setState(() {});
                          },
                        ),
                ),
                onChanged: (value) {
                  setState(() {});
                  _debouncer.run(() => context.read<RestaurantListProvider>().setSearch(value));
                },
              ),
            ),
            const SizedBox(height: 14),
            if (provider.categories.isNotEmpty)
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: provider.categories.length,
                  itemBuilder: (context, index) {
                    final category = provider.categories[index];
                    return CategoryChip(
                      category: category,
                      selected: provider.categoryId == category.id,
                      onTap: () => context.read<RestaurantListProvider>().setCategory(category.id),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Trier par', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _sortOptions.entries.map((entry) {
                          final selected = provider.sort == entry.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(entry.value),
                              selected: selected,
                              onSelected: (_) => context.read<RestaurantListProvider>().setSort(entry.key),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(provider, favorites)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(RestaurantListProvider provider, FavoritesProvider favorites) {
    switch (provider.state) {
      case LoadState.idle:
      case LoadState.loading:
        return const SkeletonList();
      case LoadState.error:
        return ErrorStateView(
          message: provider.errorMessage ?? 'Une erreur est survenue.',
          onRetry: () => provider.refresh(),
        );
      case LoadState.empty:
        return EmptyStateView(
          message: 'Aucun résultat',
          subtitle: 'Essayez une autre recherche ou catégorie.',
          icon: Icons.ramen_dining_rounded,
        );
      case LoadState.loaded:
      case LoadState.loadingMore:
        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            itemCount: provider.restaurants.length + (provider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.restaurants.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final restaurant = provider.restaurants[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RestaurantCard(
                  restaurant: restaurant,
                  isFavorite: favorites.isFavorite(restaurant.id),
                  onFavoriteTap: () => favorites.toggle(restaurant),
                  onTap: () => _openRestaurant(restaurant),
                ),
              );
            },
          ),
        );
    }
  }

  void _openRestaurant(Restaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RestaurantDetailScreen(restaurantId: restaurant.id, seed: restaurant)),
    );
  }
}
