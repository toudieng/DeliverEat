import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../models/menu_item.dart';

class MenuItemTile extends StatelessWidget {
  const MenuItemTile({super.key, required this.item, required this.onAdd, this.quantityInCart = 0});

  final MenuItem item;
  final VoidCallback onAdd;
  final int quantityInCart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: item.resolvedImageUrl,
              width: 78,
              height: 78,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(width: 78, height: 78, color: scheme.surfaceContainerHighest),
              errorWidget: (_, _, _) => Container(
                width: 78,
                height: 78,
                color: scheme.surfaceContainerHighest,
                child: Icon(Icons.fastfood_rounded, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  Formatters.currency(item.price),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: quantityInCart > 0
                    ? Container(
                        key: const ValueKey('badge'),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: scheme.secondary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'x$quantityInCart',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      )
                    : const SizedBox(height: 18, key: ValueKey('empty')),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: item.available ? onAdd : null,
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.available ? scheme.primary : scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: item.available ? scheme.onPrimary : scheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
