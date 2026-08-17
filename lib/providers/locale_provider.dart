import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/storage/local_cache_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale locale = const Locale('fr');

  AppStrings get strings => AppStrings(locale.languageCode);

  Future<void> bootstrap() async {
    final saved = await LocalCacheService.instance.locale;
    if (saved == 'en') locale = const Locale('en');
    notifyListeners();
  }

  Future<void> setEnglish(bool english) async {
    locale = Locale(english ? 'en' : 'fr');
    notifyListeners();
    await LocalCacheService.instance.saveLocale(english ? 'en' : 'fr');
  }
}
