import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  String _selectedLanguage = 'English';
  bool _isDarkMode = true;
  bool _pushNotifications = true;
  bool _shiftReminders = false;

  String get selectedLanguage => _selectedLanguage;
  bool get isDarkMode => _isDarkMode;
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

  void toggleDarkMode(bool val) {
    _isDarkMode = val;
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
