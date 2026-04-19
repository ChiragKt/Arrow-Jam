import 'dart:math';
import 'package:flutter/foundation.dart';
import 'maze_model.dart';

enum GameStatus { playing, won, lost, idle }

class DifficultyProfile {
  final int mazeSize;
  final int timeLimit;
  final String label;
  const DifficultyProfile({required this.mazeSize, required this.timeLimit, required this.label});
}

class GameState extends ChangeNotifier {
  int level = 1;
  int lives = 3;
  int score = 0;
  int highScore = 0;
  GameStatus status = GameStatus.idle;

  // Adaptive difficulty
  final List<int?> _recentSolveTimes = [];
  double _difficultyMultiplier = 1.0;

  // Current level data
  late MazeModel maze;
  int playerCol = 0;
  int playerRow = 0;
  int goalCol = 0;
  int goalRow = 0;
  int timeRemaining = 60;
  int _levelStartTime = 0;

  // Current profile
  DifficultyProfile get currentProfile => _profileForLevel();

  DifficultyProfile _profileForLevel() {
    // Base size scales with level, multiplier adjusts from solve speed
    int base = 5 + (level * 2);
    base = (base * _difficultyMultiplier).round().clamp(5, 25);
    // Add random variation ±1
    final jitter = Random().nextInt(3) - 1;
    final size = (base + jitter).clamp(5, 25);
    final time = (90 - level * 4 - ((_difficultyMultiplier - 1) * 20)).round().clamp(20, 90);
    String label = _difficultyMultiplier < 0.85
        ? '😴 Easy'
        : _difficultyMultiplier > 1.15
            ? '🔥 Hard'
            : '⚡ Normal';
    return DifficultyProfile(mazeSize: size, timeLimit: time, label: label);
  }

  void startLevel() {
    final profile = currentProfile;
    maze = MazeModel(cols: profile.mazeSize, rows: profile.mazeSize);
    playerCol = 0;
    playerRow = 0;
    goalCol = profile.mazeSize - 1;
    goalRow = profile.mazeSize - 1;
    timeRemaining = profile.timeLimit;
    _levelStartTime = DateTime.now().millisecondsSinceEpoch;
    status = GameStatus.playing;
    notifyListeners();
  }

  void tick() {
    if (status != GameStatus.playing) return;
    timeRemaining--;
    if (timeRemaining <= 0) {
      lives--;
      if (lives <= 0) {
        status = GameStatus.lost;
      } else {
        startLevel(); // retry same level
      }
    }
    notifyListeners();
  }

  bool tryMove(String direction) {
    if (status != GameStatus.playing) return false;
    if (!maze.canMove(playerCol, playerRow, direction)) return false;
    switch (direction) {
      case 'up':    playerRow--; break;
      case 'down':  playerRow++; break;
      case 'left':  playerCol--; break;
      case 'right': playerCol++; break;
    }
    notifyListeners();
    _checkGoal();
    return true;
  }

  void _checkGoal() {
    if (playerCol == goalCol && playerRow == goalRow) {
      final elapsed = ((DateTime.now().millisecondsSinceEpoch - _levelStartTime) / 1000).round();
      _recordSolveTime(elapsed, currentProfile.timeLimit);
      score += (timeRemaining * 10) + (level * 50);
      if (score > highScore) highScore = score;
      level++;
      status = GameStatus.won;
      notifyListeners();
    }
  }

  void _recordSolveTime(int seconds, int timeLimit) {
    _recentSolveTimes.add(seconds);
    if (_recentSolveTimes.length > 3) _recentSolveTimes.removeAt(0);
    _updateMultiplier(timeLimit);
  }

  void _updateMultiplier(int timeLimit) {
    if (_recentSolveTimes.isEmpty) return;
    final valid = _recentSolveTimes.whereType<int>().toList();
    if (valid.isEmpty) return;
    final avgTime = valid.reduce((a, b) => a + b) / valid.length;
    final ratio = avgTime / timeLimit;
    // Solved very fast (< 30% of time) → increase difficulty
    // Solved slowly (> 75% of time) → decrease difficulty
    if (ratio < 0.3) {
      _difficultyMultiplier = (_difficultyMultiplier + 0.15).clamp(0.7, 1.5);
    } else if (ratio > 0.75) {
      _difficultyMultiplier = (_difficultyMultiplier - 0.1).clamp(0.7, 1.5);
    }
    // else stays the same
  }

  void resetGame() {
    level = 1;
    lives = 3;
    score = 0;
    _difficultyMultiplier = 1.0;
    _recentSolveTimes.clear();
    status = GameStatus.idle;
    notifyListeners();
  }

  String hintDirection() {
    // Return compass hint toward goal
    final dc = goalCol - playerCol;
    final dr = goalRow - playerRow;
    if (dc.abs() >= dr.abs()) {
      return dc > 0 ? '→' : '←';
    } else {
      return dr > 0 ? '↓' : '↑';
    }
  }
}
