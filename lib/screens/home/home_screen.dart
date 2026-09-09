import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantListProvider>().bootstrap();
      context.read<FavoritesProvider>().load();
    });
    _scrollController.addListener(_onScroll);
  }

  String _greeting(AppStrings strings) {
    final hour = DateTime.now().hour;
    if (hour < 12) return strings.t('greetingMorning');
    if (hour < 18) return strings.t('greetingAfternoon');
    return strings.t('greetingEvening');
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.heroGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(strings),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${strings.t('deliveringTo')} Dakar, Sénégal',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 28),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                          begin: -2,
                          end: 2,
                          duration: 1400.ms,
                          curve: Curves.easeInOut,
                        ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.08, end: 0, curve: Curves.easeOut),
            const SizedBox(height: 10),
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
                  Text(strings.t('sortBy'), style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: {
                          'rating': strings.t('sortRating'),
                          'deliveryTime': strings.t('sortDeliveryTime'),
                          'deliveryFee': strings.t('sortDeliveryFee'),
                        }.entries.map((entry) {
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
            Expanded(child: _buildBody(provider, favorites, strings)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(RestaurantListProvider provider, FavoritesProvider favorites, AppStrings strings) {
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
          message: strings.t('noResults'),
          subtitle: strings.t('noResultsSubtitle'),
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
                key: ValueKey(restaurant.id),
                padding: const EdgeInsets.only(bottom: 16),
                child: RestaurantCard(
                  restaurant: restaurant,
                  isFavorite: favorites.isFavorite(restaurant.id),
                  animationDelay: Duration(milliseconds: 40 * index.clamp(0, 8)),
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
