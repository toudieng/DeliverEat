import 'package:flutter/material.dart';

import '../core/storage/local_cache_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode mode = ThemeMode.system;

  Future<void> bootstrap() async {
    final saved = await LocalCacheService.instance.themeMode;
    if (saved == 'light') mode = ThemeMode.light;
    if (saved == 'dark') mode = ThemeMode.dark;
    notifyListeners();
  }

  bool get isDark => mode == ThemeMode.dark;

  Future<void> toggle(bool dark) async {
    mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await LocalCacheService.instance.saveThemeMode(dark ? 'dark' : 'light');
  }
}
