import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState extends ChangeNotifier {
  String _themeId = 'neon';
  bool _soundEnabled = true;

  String get themeId => _themeId;
  bool get soundEnabled => _soundEnabled;

  SettingsState() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeId = prefs.getString('themeId') ?? 'neon';
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    notifyListeners();
  }

  Future<void> setTheme(String id) async {
    _themeId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeId', id);
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', _soundEnabled);
  }
}
