import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../cart/cart_screen.dart';
import '../favorites/favorites_screen.dart';
import '../home/home_screen.dart';
import '../order/order_history_screen.dart';
import '../profile/profile_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    FavoritesScreen(),
    OrderHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleProvider>().strings;
    final cart = context.watch<CartProvider>();
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: cart.isEmpty
          ? null
          : KeyedSubtree(
              key: ValueKey(cart.itemCount),
              child: FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
                icon: Badge(
                  label: Text('${cart.itemCount}'),
                  child: const Icon(Icons.shopping_bag_rounded),
                ),
                label: Text(strings.t('cart')),
              ),
            ).animate().scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 350.ms, curve: Curves.elasticOut),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: strings.t('home')),
          NavigationDestination(icon: const Icon(Icons.favorite_outline_rounded), selectedIcon: const Icon(Icons.favorite_rounded), label: strings.t('favorites')),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long_rounded), label: strings.t('orders')),
          NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: strings.t('profile')),
        ],
      ),
    );
  }
}
