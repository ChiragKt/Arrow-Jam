import 'package:arrow_jam/services/ad_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists player statistics on-device using SharedPreferences.
///
/// Tracked variables:
///   totalGamesPlayed  – number of game sessions started
///   totalGameOvers    – number of times the player hit game-over
///   totalLevelClears  – number of individual levels completed
class StorageService {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  static const _kGamesPlayed = 'totalGamesPlayed';
  static const _kGameOvers = 'totalGameOvers';
  static const _kLevelClears = 'totalLevelClears';

  // ── Getters ───────────────────────────────────────────────────────────────

  Future<int> getTotalGamesPlayed() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kGamesPlayed) ?? 0;
  }

  Future<int> getTotalGameOvers() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kGameOvers) ?? 0;
  }

  Future<int> getTotalLevelClears() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kLevelClears) ?? 0;
  }

  /// Convenience: load all three stats in one call.
  Future<Map<String, int>> loadAllStats() async {
    final p = await SharedPreferences.getInstance();
    return {
      'totalGamesPlayed': p.getInt(_kGamesPlayed) ?? 0,
      'totalGameOvers': p.getInt(_kGameOvers) ?? 0,
      'totalLevelClears': p.getInt(_kLevelClears) ?? 0,
    };
  }

  // ── Incrementers ──────────────────────────────────────────────────────────

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

  // ── Reset (for "clear data" / dev use) ───────────────────────────────────

  Future<void> resetAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kGamesPlayed);
    await p.remove(_kGameOvers);
    await p.remove(_kLevelClears);
  }
}
