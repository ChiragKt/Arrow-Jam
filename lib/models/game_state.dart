import 'arrow_model.dart';

class GameState {
  int lives;
  int level;
  int score;
  PuzzleGrid puzzle;
  bool isGameOver;
  bool isLevelWon;

  GameState({
    this.lives = 3,
    this.level = 1,
    this.score = 0,
    required this.puzzle,
    this.isGameOver = false,
    this.isLevelWon = false,
  });

  /// Grid size based on level
  static int gridSizeForLevel(int level) {
    if (level <= 2) return 4;
    if (level <= 4) return 5;
    if (level <= 6) return 6;
    if (level <= 9) return 7;
    return 8;
  }

  /// Number of arrows based on level
  static int arrowCountForLevel(int level) {
    if (level <= 2) return 5 + level;
    if (level <= 4) return 8 + level;
    if (level <= 6) return 12 + level;
    if (level <= 9) return 16 + level;
    return 22 + level;
  }
}
