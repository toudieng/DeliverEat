import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/utils/formatters.dart';
import '../models/restaurant.dart';
import 'rating_stars.dart';

class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.heroTag,
  });

  final Restaurant restaurant;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: restaurant.isOpen ? onTap : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: heroTag ?? 'restaurant-image-${restaurant.id}',
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ColorFiltered(
                      colorFilter: restaurant.isOpen
                          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                          : ColorFilter.mode(Colors.black.withValues(alpha: 0.45), BlendMode.darken),
                      child: CachedNetworkImage(
                        imageUrl: restaurant.resolvedImageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, _) => Container(color: scheme.surfaceContainerHighest),
                        errorWidget: (_, _, _) => Container(
                          color: scheme.surfaceContainerHighest,
                          child: Icon(Icons.restaurant_rounded, color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!restaurant.isOpen)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _Badge(
                      label: 'Fermé',
                      color: Colors.black87,
                      icon: Icons.lock_clock_rounded,
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _FavoriteButton(isFavorite: isFavorite, onTap: onFavoriteTap),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      RatingStars(rating: restaurant.rating, size: 15),
                      const SizedBox(width: 12),
                      Icon(Icons.timer_outlined, size: 15, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text('${restaurant.deliveryTimeMinutes} min', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 12),
                      Icon(Icons.pedal_bike_rounded, size: 15, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(Formatters.currency(restaurant.deliveryFee), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, this.onTap});
  final bool isFavorite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(isFavorite),
            color: isFavorite ? Colors.redAccent : Colors.black54,
            size: 18,
          ),
        ),
      ),
    );
  }
}
