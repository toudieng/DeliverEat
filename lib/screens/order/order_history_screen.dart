import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/locale_provider.dart';
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
  static const List<String?> _statusFilters = [
    null,
    'pending',
    'confirmed',
    'preparing',
    'delivering',
    'delivered',
    'cancelled',
  ];

  static String _statusLabel(AppStrings strings, String? status) {
    switch (status) {
      case null:
        return strings.t('statusAll');
      case 'pending':
        return strings.t('statusPending');
      case 'confirmed':
        return strings.t('statusConfirmed');
      case 'preparing':
        return strings.t('statusPreparing');
      case 'delivering':
        return strings.t('statusDelivering');
      case 'delivered':
        return strings.t('statusDelivered');
      case 'cancelled':
        return strings.t('statusCancelled');
      default:
        return status;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderProvider>().loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final strings = context.watch<LocaleProvider>().strings;
    return Scaffold(
      appBar: AppBar(title: Text(strings.t('myOrders'))),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: _statusFilters.map((status) {
                final selected = provider.statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_statusLabel(strings, status)),
                    selected: selected,
                    onSelected: (_) => context.read<OrderProvider>().setStatusFilter(status),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(context, provider, strings)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, OrderProvider provider, AppStrings strings) {
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
        return EmptyStateView(
          message: strings.t('noOrders'),
          subtitle: strings.t('noOrdersSubtitle'),
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
    final strings = context.read<LocaleProvider>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.t('cancelOrderConfirmTitle')),
        content: Text(strings.t('cancelOrderConfirmBody')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.t('goBack'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.t('cancelOrderAction'))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await context.read<OrderProvider>().cancelOrder(order.id);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.t('orderCancelled'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
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
                      order.restaurantName ?? '${strings.t('orderNumber')} #${order.id}',
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
                      child: Text(strings.t('cancelOrder')),
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
