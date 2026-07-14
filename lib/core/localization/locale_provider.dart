import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina/core/config/app_config.dart';
import 'package:aina/core/di/injection.dart';

/// Holds and persists the user's chosen app language (English/Urdu).
/// Defaults to [AppConfig.defaultLocale] rather than the device locale,
/// since an unsupported device locale (e.g. French) should fall back to
/// English rather than silently breaking the localization lookup.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final stored = ref.read(sharedPrefsServiceProvider).locale;
    final languageCode = (stored != null && AppConfig.supportedLocales.contains(stored))
        ? stored
        : AppConfig.defaultLocale;
    return Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref.read(sharedPrefsServiceProvider).setLocale(locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
