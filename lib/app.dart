import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class DeliverEatApp extends StatefulWidget {
  const DeliverEatApp({super.key});

  @override
  State<DeliverEatApp> createState() => _DeliverEatAppState();
}

class _DeliverEatAppState extends State<DeliverEatApp> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return _SessionWatcher(
      onExpired: () {
        rootNavigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'DeliverEat',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeProvider.mode,
        locale: localeProvider.locale,
        supportedLocales: const [Locale('fr'), Locale('en')],
        home: const SplashScreen(),
      ),
    );
  }
}

/// Forces navigation back to the login screen whenever the refresh token
/// itself becomes invalid (e.g. expired refresh token, or a second device
/// having rotated it first) after the user was previously authenticated —
/// mid-usage session expiry, not the normal splash-screen bootstrap.
class _SessionWatcher extends StatefulWidget {
  const _SessionWatcher({required this.onExpired, required this.child});

  final VoidCallback onExpired;
  final Widget child;

  @override
  State<_SessionWatcher> createState() => _SessionWatcherState();
}

class _SessionWatcherState extends State<_SessionWatcher> {
  AuthStatus? _previous;

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    if (_previous == AuthStatus.authenticated && status == AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onExpired());
    }
    _previous = status;
    return widget.child;
  }
}
