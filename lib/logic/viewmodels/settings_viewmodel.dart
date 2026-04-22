import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  String _selectedLanguage = 'English';
  ThemeMode _themeMode = ThemeMode.system;
  bool _pushNotifications = true;
  bool _shiftReminders = false;

  String get selectedLanguage => _selectedLanguage;
  ThemeMode get themeMode => _themeMode;
  bool get pushNotifications => _pushNotifications;
  bool get shiftReminders => _shiftReminders;

  String get localeCode {
    switch (_selectedLanguage) {
      case 'Spanish': return 'es_ES';
      case 'Filipino': return 'fil_PH';
      default: return 'en_US';
    }
  }

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void togglePushNotifications(bool val) {
    _pushNotifications = val;
    notifyListeners();
  }

  void toggleShiftReminders(bool val) {
    _shiftReminders = val;
    notifyListeners();
  }
}
