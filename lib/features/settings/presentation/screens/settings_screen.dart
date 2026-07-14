import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aina/core/config/app_config.dart';
import 'package:aina/core/localization/locale_provider.dart';
import 'package:aina/core/storage/hive_service.dart';
import 'package:aina/core/theme/app_colors.dart';
import 'package:aina/core/theme/theme_extensions.dart';
import 'package:aina/core/theme/theme_mode_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SectionLabel('Appearance'),
          _SettingsCard(
            child: Column(
              children: ThemeMode.values.map((mode) {
                return RadioListTile<ThemeMode>(
                  value: mode,
                  groupValue: themeMode,
                  activeColor: AppColors.primary,
                  title: Text(
                    _themeModeLabel(mode),
                    style: TextStyle(color: context.textPrimary),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(themeModeProvider.notifier).setThemeMode(value);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Language'),
          _SettingsCard(
            child: Column(
              children: AppConfig.supportedLocales.map((code) {
                return RadioListTile<String>(
                  value: code,
                  groupValue: locale.languageCode,
                  activeColor: AppColors.primary,
                  title: Text(
                    _localeLabel(code),
                    style: TextStyle(color: context.textPrimary),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(localeProvider.notifier).setLocale(Locale(value));
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Support'),
          _SettingsCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.email_outlined, color: context.textPrimary),
                  title: Text('Email support', style: TextStyle(color: context.textPrimary)),
                  subtitle: Text(
                    AppConfig.supportEmail,
                    style: TextStyle(color: context.textSecondary),
                  ),
                  onTap: () => launchUrl(Uri.parse('mailto:${AppConfig.supportEmail}')),
                ),
                ListTile(
                  leading: Icon(Icons.chat_outlined, color: context.textPrimary),
                  title: Text('WhatsApp support', style: TextStyle(color: context.textPrimary)),
                  // Forced LTR: a phone number is never actually RTL content,
                  // but Urdu locale makes the ambient paragraph direction RTL,
                  // which repositions the leading "+" to the end of the string.
                  subtitle: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      AppConfig.supportWhatsapp,
                      style: TextStyle(color: context.textSecondary),
                    ),
                  ),
                  onTap: () => launchUrl(
                    Uri.parse('https://wa.me/${AppConfig.supportWhatsapp.replaceAll('+', '')}'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Storage'),
          _SettingsCard(
            child: ListTile(
              leading: Icon(Icons.cleaning_services_outlined, color: context.textPrimary),
              title: Text('Clear local cache', style: TextStyle(color: context.textPrimary)),
              subtitle: Text(
                'Clears cached salon listings and search history',
                style: TextStyle(color: context.textSecondary),
              ),
              onTap: () async {
                await HiveService.clearAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Local cache cleared.')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${AppConfig.appName} · v1.0.0',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'Match device setting',
    };
  }

  String _localeLabel(String code) {
    return switch (code) {
      'ur' => 'اردو (Urdu)',
      _ => 'English',
    };
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary, fontSize: 14),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.outlineColor),
      ),
      child: child,
    );
  }
}
