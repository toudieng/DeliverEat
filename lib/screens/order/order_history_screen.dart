import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_status_timeline.dart';
import '../../widgets/state_views.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  static const Map<String?, String> _statusLabels = {
    null: 'Toutes',
    'pending': 'En attente',
    'confirmed': 'Confirmées',
    'preparing': 'En préparation',
    'delivering': 'En livraison',
    'delivered': 'Livrées',
    'cancelled': 'Annulées',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderProvider>().loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: _statusLabels.entries.map((entry) {
                final selected = provider.statusFilter == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: selected,
                    onSelected: (_) => context.read<OrderProvider>().setStatusFilter(entry.key),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(context, provider)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, OrderProvider provider) {
    switch (provider.state) {
      case OrdersLoadState.idle:
      case OrdersLoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case OrdersLoadState.error:
        return ErrorStateView(
          message: provider.errorMessage ?? 'Une erreur est survenue.',
          onRetry: provider.loadOrders,
        );
      case OrdersLoadState.empty:
        return const EmptyStateView(
          message: 'Aucune commande',
          subtitle: 'Vos commandes passées apparaîtront ici.',
          icon: Icons.receipt_long_outlined,
        );
      case OrdersLoadState.loaded:
        return RefreshIndicator(
          onRefresh: provider.loadOrders,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.orders.length,
            itemBuilder: (context, index) => _OrderTile(order: provider.orders[index]),
          ),
        );
    }
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final Order order;

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Retour')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Annuler la commande')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await context.read<OrderProvider>().cancelOrder(order.id);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande annulée')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id, initialOrder: order)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.restaurantName ?? 'Commande #${order.id}',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  OrderStatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(Formatters.dateTime(order.createdAt), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.currency(order.total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (order.canCancel)
                    TextButton(
                      onPressed: () => _cancel(context),
                      style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      child: const Text('Annuler'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
