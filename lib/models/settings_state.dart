import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';

class SettingsState extends ChangeNotifier {
  String _themeId = 'neon';
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _hapticsEnabled = true;
  int _coins = 0;
  Set<String> _unlockedThemes = {'neon', 'lava', 'arctic'};

  String get themeId => _themeId;
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  int get coins => _coins;
  Set<String> get unlockedThemes => _unlockedThemes;

  SettingsState() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeId = prefs.getString('themeId') ?? 'neon';
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _musicEnabled = prefs.getBool('musicEnabled') ?? true;
    _hapticsEnabled = prefs.getBool('hapticsEnabled') ?? true;
    _coins = await StorageService().getCoins();
    _unlockedThemes = await StorageService().getUnlockedThemes();
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

  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicEnabled', _musicEnabled);
  }

  Future<void> toggleHaptics() async {
    _hapticsEnabled = !_hapticsEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hapticsEnabled', _hapticsEnabled);
  }

  bool isThemeUnlocked(String themeId) => _unlockedThemes.contains(themeId);

  Future<bool> tryUnlockTheme(String themeId, int cost) async {
    if (_coins < cost) return false;
    final ok = await StorageService().unlockTheme(themeId, cost);
    if (ok) {
      _coins -= cost;
      _unlockedThemes.add(themeId);
      notifyListeners();
    }
    return ok;
  }

  Future<void> addCoins(int amount) async {
    _coins = await StorageService().addCoins(amount);
    notifyListeners();
  }

  Future<void> refreshCoins() async {
    _coins = await StorageService().getCoins();
    notifyListeners();
  }
}
