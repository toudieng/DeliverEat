import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/menu_item.dart';
import '../../models/paginated_response.dart';
import '../../models/restaurant.dart';
import '../../models/review.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/catalog_service.dart';
import '../../services/review_service.dart';
import '../../widgets/menu_item_tile.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/state_views.dart';
import '../cart/cart_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key, required this.restaurantId, this.seed});

  final String restaurantId;
  final Restaurant? seed;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final CatalogService _catalogService = CatalogService();
  final ReviewService _reviewService = ReviewService();

  Restaurant? _restaurant;
  List<Review> _reviews = [];
  bool _loading = true;
  bool _reviewsLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restaurant = widget.seed;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final restaurant = await _catalogService.restaurant(widget.restaurantId);
      setState(() {
        _restaurant = restaurant;
        _error = null;
      });
    } on ApiException catch (e) {
      if (_restaurant == null) setState(() => _error = e.friendlyMessage);
    } catch (_) {
      if (_restaurant == null) setState(() => _error = "Une erreur est survenue.");
    }
    setState(() => _loading = false);
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _reviewsLoading = true);
    try {
      final PaginatedResponse<Review> response = await _reviewService.reviews(widget.restaurantId);
      setState(() => _reviews = response.data);
    } catch (_) {
      // Reviews are secondary content; fail silently, keep menu usable.
    }
    setState(() => _reviewsLoading = false);
  }

  void _addToCart(MenuItem item) {
    final cart = context.read<CartProvider>();
    final conflict = cart.tryAdd(_restaurant!, item);
    if (conflict != null) {
      _showConflictDialog(conflict, item);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} ajouté au panier'), duration: const Duration(milliseconds: 900)),
      );
    }
  }

  void _showConflictDialog(Restaurant newRestaurant, MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier ?'),
        content: Text(
          'Votre panier contient déjà des articles de "${context.read<CartProvider>().restaurant?.name}". '
          'Une commande ne peut concerner qu\'un seul restaurant.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              context.read<CartProvider>().clearAndAdd(newRestaurant, item);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Panier vidé, ${item.name} ajouté')),
              );
            },
            child: const Text('Vider et ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _restaurant == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && _restaurant == null) {
      return Scaffold(appBar: AppBar(), body: ErrorStateView(message: _error!, onRetry: _load));
    }
    final restaurant = _restaurant!;
    final sections = MenuSection.groupBySection(restaurant.menu);
    final favorites = context.watch<FavoritesProvider>();
    final cart = context.watch<CartProvider>();
    final quantities = {for (final item in cart.items) item.menuItem.id: item.quantity};

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            leading: _CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
            actions: [
              _CircleIconButton(
                icon: favorites.isFavorite(restaurant.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: favorites.isFavorite(restaurant.id) ? Colors.redAccent : null,
                onTap: () => favorites.toggle(restaurant),
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'restaurant-image-${restaurant.id}',
                    child: CachedNetworkImage(
                      imageUrl: restaurant.resolvedImageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(restaurant.name, style: Theme.of(context).textTheme.headlineSmall),
                      ),
                      if (!restaurant.isOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(100)),
                          child: const Text('Fermé', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  if (restaurant.description != null && restaurant.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(restaurant.description!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: [
                      RatingStars(rating: restaurant.rating, size: 18),
                      _InfoPill(icon: Icons.timer_outlined, label: '${restaurant.deliveryTimeMinutes} min'),
                      _InfoPill(icon: Icons.pedal_bike_rounded, label: Formatters.currency(restaurant.deliveryFee)),
                    ],
                  ),
                  const Divider(height: 32),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
          if (sections.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: EmptyStateView(message: 'Menu indisponible', icon: Icons.menu_book_rounded),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, sectionIndex) {
                    final section = sections[sectionIndex];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.title, style: Theme.of(context).textTheme.titleLarge),
                        const Divider(),
                        ...section.items.map(
                          (item) => MenuItemTile(
                            item: item,
                            quantityInCart: quantities[item.id] ?? 0,
                            onAdd: () => _addToCart(item),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  childCount: sections.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              child: _ReviewsSection(
                reviews: _reviews,
                loading: _reviewsLoading,
                restaurant: restaurant,
                onSubmitted: _loadReviews,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty || cart.restaurant?.id != restaurant.id
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
                  icon: const Icon(Icons.shopping_bag_rounded),
                  label: Text('Voir le panier · ${Formatters.currency(cart.total)}'),
                ),
              ),
            ).animate().slideY(begin: 1, end: 0, duration: 250.ms),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color ?? Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _ReviewsSection extends StatefulWidget {
  const _ReviewsSection({
    required this.reviews,
    required this.loading,
    required this.restaurant,
    required this.onSubmitted,
  });

  final List<Review> reviews;
  final bool loading;
  final Restaurant restaurant;
  final Future<void> Function() onSubmitted;

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  final ReviewService _reviewService = ReviewService();
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _submitting = false;
  String? _formError;
  bool _alreadyReviewed = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_commentController.text.trim().isEmpty) {
      setState(() => _formError = 'Merci de laisser un commentaire.');
      return;
    }
    setState(() {
      _submitting = true;
      _formError = null;
    });
    try {
      await _reviewService.addReview(
        widget.restaurant.id,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      _commentController.clear();
      await widget.onSubmitted();
    } on ApiException catch (e) {
      if (e.code == 'ALREADY_REVIEWED') {
        setState(() => _alreadyReviewed = true);
      } else {
        setState(() => _formError = e.friendlyMessage);
      }
    } catch (_) {
      setState(() => _formError = "Une erreur est survenue.");
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Avis clients', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Aucun avis pour le moment.', style: Theme.of(context).textTheme.bodyMedium),
          )
        else
          ...widget.reviews.map((review) => _ReviewTile(review: review)),
        const SizedBox(height: 20),
        if (_alreadyReviewed)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.amber),
                SizedBox(width: 10),
                Expanded(child: Text('Vous avez déjà laissé un avis pour ce restaurant.')),
              ],
            ),
          )
        else ...[
          Text('Laisser un avis', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          RatingInput(value: _rating, onChanged: (v) => setState(() => _rating = v)),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Votre expérience…'),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 8),
            Text(_formError!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Publier'),
          ),
        ],
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: Theme.of(context).textTheme.titleSmall),
                    RatingStars(rating: review.rating.toDouble(), size: 13),
                  ],
                ),
              ),
              if (review.createdAt != null)
                Text(Formatters.dateTime(review.createdAt), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(review.comment),
        ],
      ),
    );
  }
}
