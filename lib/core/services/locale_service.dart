import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locale service
/// Handles persistent storage and management of app locale
class LocaleService extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  SharedPreferences? _prefs;
  Locale? _currentLocale;

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('fr'), // French
    Locale('ar'), // Arabic
  ];

  /// Get locale display name
  static String getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Francais';
      case 'ar':
        return 'العربية';
      default:
        return locale.languageCode;
    }
  }

  /// Get locale flag emoji
  static String getLocaleFlag(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return '🇬🇧';
      case 'fr':
        return '🇫🇷';
      case 'ar':
        return '🇹🇳';
      default:
        return '🌐';
    }
  }

  /// Get current locale
  Locale? get currentLocale => _currentLocale;

  /// Initialize shared preferences and load saved locale
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final savedLocale = _prefs!.getString(_localeKey);
    if (savedLocale != null) {
      _currentLocale = Locale(savedLocale);
    }
  }

  /// Set and save locale
  Future<void> setLocale(Locale locale) async {
    await init();
    _currentLocale = locale;
    await _prefs!.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }

  /// Clear saved locale (use system default)
  Future<void> clearLocale() async {
    await init();
    _currentLocale = null;
    await _prefs!.remove(_localeKey);
    notifyListeners();
  }
}

/// Singleton instance
final localeService = LocaleService();
