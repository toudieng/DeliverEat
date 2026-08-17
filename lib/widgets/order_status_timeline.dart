import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/order.dart';

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.order});

  final Order order;

  static const Map<OrderStatus, IconData> _icons = {
    OrderStatus.pending: Icons.receipt_long_rounded,
    OrderStatus.confirmed: Icons.check_circle_rounded,
    OrderStatus.preparing: Icons.soup_kitchen_rounded,
    OrderStatus.delivering: Icons.delivery_dining_rounded,
    OrderStatus.delivered: Icons.home_rounded,
  };

  static const Map<OrderStatus, String> _labels = {
    OrderStatus.pending: 'Commande reçue',
    OrderStatus.confirmed: 'Confirmée',
    OrderStatus.preparing: 'En préparation',
    OrderStatus.delivering: 'En livraison',
    OrderStatus.delivered: 'Livrée',
  };

  @override
  Widget build(BuildContext context) {
    if (order.status == OrderStatus.cancelled) {
      return _CancelledBanner(order: order);
    }
    final currentIndex = kOrderProgression.indexOf(order.status);
    final historyByStatus = {for (final e in order.statusHistory) e.status: e.timestamp};

    return Column(
      children: List.generate(kOrderProgression.length, (index) {
        final status = kOrderProgression[index];
        final reached = currentIndex >= index;
        final isCurrent = currentIndex == index;
        final isLast = index == kOrderProgression.length - 1;
        final timestamp = historyByStatus[status];

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: reached ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      boxShadow: isCurrent
                          ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12, spreadRadius: 2)]
                          : null,
                    ),
                    child: Icon(
                      _icons[status],
                      color: reached ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ).animate(target: isCurrent ? 1 : 0).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.08, 1.08),
                        duration: 600.ms,
                        curve: Curves.easeInOut,
                      ),
                  if (!isLast)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 3,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: currentIndex > index
                            ? AppColors.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28, top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labels[status] ?? status.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: reached ? null : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            ),
                      ),
                      if (timestamp != null)
                        Text(
                          Formatters.time(timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        )
                      else if (isCurrent)
                        _PulsingLabel(text: 'En cours…'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _PulsingLabel extends StatelessWidget {
  const _PulsingLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 700.ms).then().fadeOut(duration: 700.ms);
  }
}

class _CancelledBanner extends StatelessWidget {
  const _CancelledBanner({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Commande annulée', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});
  final OrderStatus status;

  Color _color() {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
        return AppColors.primary;
      case OrderStatus.delivering:
        return const Color(0xFF3B82F6);
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.danger;
      case OrderStatus.unknown:
        return Colors.grey;
    }
  }

  String _label() {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.confirmed:
        return 'Confirmée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.delivering:
        return 'En livraison';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
      case OrderStatus.unknown:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100)),
      child: Text(_label(), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
