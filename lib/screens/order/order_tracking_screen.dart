import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de commande'),
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
                      padding: const EdgeInsets.all(18),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.heroGradient),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.restaurantName ?? 'Votre commande',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Commande #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
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
                    Text('Statut', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: KeyedSubtree(
                        key: ValueKey(order.status),
                        child: OrderStatusTimeline(order: order),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Adresse de livraison', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(order.deliveryAddress, style: Theme.of(context).textTheme.bodyMedium),
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Remarques', style: Theme.of(context).textTheme.titleMedium),
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
                          child: const Text("Retour à l'accueil"),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator({required this.isLive});
  final bool isLive;

  @override
  Widget build(BuildContext context) {
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
          isLive ? 'En direct' : 'Reconnexion…',
          style: TextStyle(fontSize: 12, color: isLive ? AppColors.success : Colors.grey, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
