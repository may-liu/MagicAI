// app_localizations.dart
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String> get _localizedStrings => _getStrings();

  Map<String, String> _getStrings() {
    switch (locale.languageCode) {
      case 'zh':
        return {
          'settings': '设置',
          'notifications': '通知',
          'privacy': '隐私',
          'storage': '存储',
          // 添加更多翻译...
        };
      default: // en
        return {
          'settings': 'Settings',
          'notifications': 'Notifications',
          'privacy': 'Privacy',
          'storage': 'Storage',
        };
    }
  }

  String get settings => _localizedStrings['settings']!;
  String get notifications => _localizedStrings['notifications']!;
  String get privacy => _localizedStrings['privacy']!;
  String get storage => _localizedStrings['storage']!;
  String get language => _localizedStrings['language']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

class LanguageSelector extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onChanged;

  const LanguageSelector({
    super.key,
    required this.currentLocale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Locale>(
      itemBuilder:
          (context) => [
            _buildLanguageItem(context, const Locale('en'), 'English'),
            _buildLanguageItem(context, const Locale('zh'), '中文'),
          ],
      onSelected: onChanged,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ListTile(
          leading: _buildLeading(context),
          title: Text(AppLocalizations.of(context).language),
          trailing: Text(currentLocale.languageCode.toUpperCase()),
        ),
      ),
    );
  }

  PopupMenuEntry<Locale> _buildLanguageItem(
    BuildContext context,
    Locale locale,
    String text,
  ) => PopupMenuItem(
    value: locale,
    child: Row(
      children: [
        Text(text),
        if (locale == currentLocale)
          const Icon(Icons.check, color: Colors.blue),
      ],
    ),
  );

  Widget _buildLeading(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.language),
  );
}
