import 'package:shared_preferences/shared_preferences.dart';

/// Persists player statistics, coins, and theme unlocks on-device.
class StorageService {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  static const _kGamesPlayed    = 'totalGamesPlayed';
  static const _kGameOvers      = 'totalGameOvers';
  static const _kLevelClears    = 'totalLevelClears';
  static const _kHighestLevel   = 'highestLevel';
  static const _kCoins          = 'coins';
  static const _kUnlockedThemes = 'unlockedThemes';
  static const _kLastDailyDate  = 'lastDailyDate';
  static const _kDailyChallengeLevel = 'dailyChallengeLevel';

  // Themes that are free from the start
  static const List<String> freeThemes = ['neon', 'lava', 'arctic'];

  // ── Stats ─────────────────────────────────────────────────────────────────

  Future<Map<String, int>> loadAllStats() async {
    final p = await SharedPreferences.getInstance();
    return {
      'totalGamesPlayed' : p.getInt(_kGamesPlayed)  ?? 0,
      'totalGameOvers'   : p.getInt(_kGameOvers)    ?? 0,
      'totalLevelClears' : p.getInt(_kLevelClears)  ?? 0,
      'highestLevel'     : p.getInt(_kHighestLevel) ?? 0,
    };
  }

  Future<void> incrementGamesPlayed() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kGamesPlayed, (p.getInt(_kGamesPlayed) ?? 0) + 1);
  }

  Future<void> incrementGameOvers() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kGameOvers, (p.getInt(_kGameOvers) ?? 0) + 1);
  }

  Future<void> incrementLevelClears() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLevelClears, (p.getInt(_kLevelClears) ?? 0) + 1);
  }

  Future<void> maybeUpdateHighestLevel(int level) async {
    final p = await SharedPreferences.getInstance();
    final current = p.getInt(_kHighestLevel) ?? 0;
    if (level > current) await p.setInt(_kHighestLevel, level);
  }

  // ── Coins ─────────────────────────────────────────────────────────────────

  Future<int> getCoins() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kCoins) ?? 0;
  }

  Future<int> addCoins(int amount) async {
    final p = await SharedPreferences.getInstance();
    final newTotal = (p.getInt(_kCoins) ?? 0) + amount;
    await p.setInt(_kCoins, newTotal);
    return newTotal;
  }

  Future<bool> spendCoins(int amount) async {
    final p = await SharedPreferences.getInstance();
    final current = p.getInt(_kCoins) ?? 0;
    if (current < amount) return false;
    await p.setInt(_kCoins, current - amount);
    return true;
  }

  // ── Theme unlocks ─────────────────────────────────────────────────────────

  Future<Set<String>> getUnlockedThemes() async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getStringList(_kUnlockedThemes) ?? [];
    return {...freeThemes, ...stored};
  }

  Future<bool> unlockTheme(String themeId, int cost) async {
    final spent = await spendCoins(cost);
    if (!spent) return false;
    final p = await SharedPreferences.getInstance();
    final current = p.getStringList(_kUnlockedThemes) ?? [];
    if (!current.contains(themeId)) {
      current.add(themeId);
      await p.setStringList(_kUnlockedThemes, current);
    }
    return true;
  }

  Future<bool> isThemeUnlocked(String themeId) async {
    if (freeThemes.contains(themeId)) return true;
    final p = await SharedPreferences.getInstance();
    final stored = p.getStringList(_kUnlockedThemes) ?? [];
    return stored.contains(themeId);
  }

  // ── Daily challenge ───────────────────────────────────────────────────────

  Future<bool> isDailyChallengeAvailable() async {
    final p = await SharedPreferences.getInstance();
    final lastDate = p.getString(_kLastDailyDate) ?? '';
    return lastDate != _todayString();
  }

  Future<bool> claimDailyChallenge() async {
    final p = await SharedPreferences.getInstance();
    final today = _todayString();
    if (p.getString(_kLastDailyDate) == today) return false;
    await p.setString(_kLastDailyDate, today);
    final levels = [4, 5, 6, 7];
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    await p.setInt(_kDailyChallengeLevel, levels[dayOfYear % levels.length]);
    return true;
  }

  Future<int> getDailyChallengeGridSize() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kDailyChallengeLevel) ?? 5;
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  Future<void> resetAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kGamesPlayed);
    await p.remove(_kGameOvers);
    await p.remove(_kLevelClears);
    await p.remove(_kHighestLevel);
  }
}
