import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/locale_provider.dart';
import '../../providers/order_tracking_provider.dart';
import '../../widgets/order_status_timeline.dart';
import '../root/root_shell.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.orderId, this.initialOrder});

  final String orderId;
  final Order? initialOrder;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrderTrackingProvider(orderId: orderId, initialOrder: initialOrder),
      child: const _OrderTrackingView(),
    );
  }
}

class _OrderTrackingView extends StatelessWidget {
  const _OrderTrackingView();

  @override
  Widget build(BuildContext context) {
    final tracking = context.watch<OrderTrackingProvider>();
    final order = tracking.order;
    final strings = context.watch<LocaleProvider>().strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('orderTracking')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _LiveIndicator(isLive: tracking.isLive)),
          ),
        ],
      ),
      body: order == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      key: ValueKey('hero-${order.status}'),
                      padding: const EdgeInsets.all(18),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: order.status == OrderStatus.delivered
                              ? AppColors.successGradient
                              : AppColors.heroGradient,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  order.restaurantName ?? strings.t('yourOrder'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                                ),
                              ),
                              if (order.status == OrderStatus.delivered) const _DeliveredBadge(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${strings.t('orderNumber')} #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            Formatters.currency(order.total),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 28),
                    Text(strings.isFrench ? 'Statut' : 'Status', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: KeyedSubtree(
                        key: ValueKey(order.status),
                        child: OrderStatusTimeline(order: order),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(strings.t('deliveryAddress'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(order.deliveryAddress, style: Theme.of(context).textTheme.bodyMedium),
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(strings.isFrench ? 'Remarques' : 'Notes', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(order.notes!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 28),
                    if (order.status == OrderStatus.delivered)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const RootShell()),
                            (route) => false,
                          ),
                          child: Text(strings.t('backToHome')),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DeliveredBadge extends StatelessWidget {
  const _DeliveredBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < 8; i++) _ConfettiDot(index: i),
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 22),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }
}

class _ConfettiDot extends StatelessWidget {
  const _ConfettiDot({required this.index});
  final int index;

  static const _colors = [AppColors.amber, Colors.white, AppColors.secondary];

  @override
  Widget build(BuildContext context) {
    final angle = (index / 8) * 2 * math.pi;
    final dx = 34 * math.cos(angle);
    final dy = 34 * math.sin(angle);
    return Positioned(
      left: 30,
      top: 30,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: _colors[index % _colors.length], shape: BoxShape.circle),
      )
          .animate()
          .fadeIn(duration: 150.ms)
          .moveX(begin: 0, end: dx, duration: 650.ms, curve: Curves.easeOut)
          .moveY(begin: 0, end: dy, duration: 650.ms, curve: Curves.easeOut)
          .fadeOut(delay: 250.ms, duration: 400.ms),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator({required this.isLive});
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final AppStrings strings = context.watch<LocaleProvider>().strings;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isLive ? AppColors.success : Colors.grey,
            shape: BoxShape.circle,
          ),
        ).animate(onPlay: (c) => isLive ? c.repeat(reverse: true) : null).fadeIn(duration: 700.ms).then().fadeOut(duration: 700.ms),
        const SizedBox(width: 6),
        Text(
          isLive ? strings.t('live') : strings.t('reconnecting'),
          style: TextStyle(fontSize: 12, color: isLive ? AppColors.success : Colors.grey, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
