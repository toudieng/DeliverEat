import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/state_views.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Panier')),
      body: cart.isEmpty
          ? const EmptyStateView(
              message: 'Votre panier est vide',
              subtitle: 'Ajoutez des plats depuis un restaurant pour commencer.',
              icon: Icons.shopping_bag_outlined,
            )
          : Column(
              children: [
                if (cart.restaurant != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(cart.restaurant!.name, style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _CartTile(item: item)
                          .animate()
                          .fadeIn(duration: 250.ms)
                          .slideX(begin: 0.05, end: 0);
                    },
                  ),
                ),
                _CartSummary(cart: cart),
              ],
            ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.menuItem.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(Formatters.currency(item.menuItem.price), style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          _QuantityStepper(
            quantity: item.quantity,
            onIncrement: () => cart.increment(item.menuItem.id),
            onDecrement: () => cart.decrement(item.menuItem.id),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onIncrement, required this.onDecrement});
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(quantity == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded, size: 18),
            onPressed: onDecrement,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              '$quantity',
              key: ValueKey(quantity),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(icon: const Icon(Icons.add_rounded, size: 18), onPressed: onIncrement),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart});
  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(label: 'Sous-total', value: cart.subtotal),
            _SummaryRow(label: 'Frais de livraison', value: cart.deliveryFee),
            const Divider(height: 20),
            _SummaryRow(label: 'Total', value: cart.total, emphasized: true),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
              child: const Text('Commander'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.emphasized = false});
  final String label;
  final int value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(Formatters.currency(value), style: style),
        ],
      ),
    );
  }
}
