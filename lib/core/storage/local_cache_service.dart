import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Non-secret local persistence: theme/locale preference and the last
/// successful restaurant list, so the home screen stays browsable offline.
class LocalCacheService {
  LocalCacheService._();
  static final LocalCacheService instance = LocalCacheService._();

  static const _kThemeMode = 'pref_theme_mode';
  static const _kLocale = 'pref_locale';
  static const _kCachedRestaurants = 'cache_restaurants';

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode);
  }

  Future<String?> get themeMode async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kThemeMode);
  }

  Future<void> saveLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, code);
  }

  Future<String?> get locale async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLocale);
  }

  Future<void> cacheRestaurants(List<Map<String, dynamic>> restaurants) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedRestaurants, jsonEncode(restaurants));
  }

  Future<List<Map<String, dynamic>>> get cachedRestaurants async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCachedRestaurants);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
