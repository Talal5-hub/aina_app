import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Loads `assets/translations/{locale}.json` and exposes nested-key
/// lookups (`t('home.greeting')`) with `{placeholder}` interpolation.
///
/// A JSON-per-locale approach was chosen over Flutter's generated
/// `.arb`/`gen_l10n` pipeline so translations can be added by a
/// non-developer editing a flat JSON file, and so adding Urdu didn't
/// require regenerating Dart code as part of this phase.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ur'),
  ];

  late Map<String, dynamic> _localizedStrings;

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(localizations != null, 'AppLocalizations not found in widget tree');
    return localizations!;
  }

  Future<bool> load() async {
    final jsonString = await rootBundle.loadString(
      'assets/translations/${locale.languageCode}.json',
    );
    _localizedStrings = json.decode(jsonString) as Map<String, dynamic>;
    return true;
  }

  /// Looks up a dot-separated key, e.g. `t('home.greeting', {'name': 'Ali'})`.
  /// Falls back to the key itself (never throws) if the key is missing,
  /// so a translation gap shows up as visible mistranslated text in QA
  /// rather than crashing the screen.
  String t(String key, [Map<String, String>? params]) {
    dynamic value = _localizedStrings;
    for (final segment in key.split('.')) {
      if (value is Map<String, dynamic> && value.containsKey(segment)) {
        value = value[segment];
      } else {
        return key;
      }
    }

    if (value is! String) return key;

    var result = value;
    params?.forEach((paramKey, paramValue) {
      result = result.replaceAll('{$paramKey}', paramValue);
    });
    return result;
  }

  bool get isRtl => locale.languageCode == 'ur';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.map((l) => l.languageCode).contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
