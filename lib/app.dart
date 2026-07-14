import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aina/core/config/flavor_config.dart';
import 'package:aina/core/localization/app_localizations.dart';
import 'package:aina/core/localization/locale_provider.dart';
import 'package:aina/core/routing/app_router.dart';
import 'package:aina/core/theme/app_theme.dart';
import 'package:aina/core/theme/theme_mode_provider.dart';

/// Root widget. Every cross-cutting concern set up in this phase —
/// theme, routing, localization — converges here. Feature screens never
/// construct their own `MaterialApp`; they're all reached through
/// [goRouterProvider]'s route table.
class AinaApp extends ConsumerWidget {
  const AinaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: FlavorConfig.instance.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        // Forces LTR/RTL directionality based on the active locale,
        // independent of the device's own system locale/direction.
        return Directionality(
          textDirection: locale.languageCode == 'ur' ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
