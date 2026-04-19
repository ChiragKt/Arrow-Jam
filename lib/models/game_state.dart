import 'dart:math';
import 'package:flutter/foundation.dart';
import '../themes/app_themes.dart';

/// Represents a single arrow on the grid
class Arrow {
  final int id;
  int col;
  int row;
  ArrowDirection direction;
  bool cleared; // true = has been launched and exited
  bool animating; // currently in flight

  Arrow({
    required this.id,
    required this.col,
    required this.row,
    required this.direction,
    this.cleared = false,
    this.animating = false,
  });

  Arrow copyWith({
    int? col,
    int? row,
    ArrowDirection? direction,
    bool? cleared,
    bool? animating,
  }) {
    return Arrow(
      id: id,
      col: col ?? this.col,
      row: row ?? this.row,
      direction: direction ?? this.direction,
      cleared: cleared ?? this.cleared,
      animating: animating ?? this.animating,
    );
  }
}

/// Difficulty configuration
class Difficulty {
  final String label;
  final String emoji;
  final int gridSize;  // n x n
  final int arrowCount;
  final int lives;

  const Difficulty({
    required this.label,
    required this.emoji,
    required this.gridSize,
    required this.arrowCount,
    required this.lives,
  });
}

const List<Difficulty> kDifficulties = [
  Difficulty(label: 'Easy',   emoji: '🟢', gridSize: 4, arrowCount: 5,  lives: 5),
  Difficulty(label: 'Normal', emoji: '🟡', gridSize: 5, arrowCount: 8,  lives: 4),
  Difficulty(label: 'Hard',   emoji: '🔴', gridSize: 6, arrowCount: 12, lives: 3),
  Difficulty(label: 'Expert', emoji: '💀', gridSize: 7, arrowCount: 18, lives: 3),
];

/// Tap result enum
enum TapResult { cleared, collision, invalid }

class GameState extends ChangeNotifier {
  int _difficultyIndex = 1; // default Normal
  int _lives = 4;
  int _level = 1;
  int _score = 0;
  bool _gameOver = false;
  bool _levelWon = false;
  bool _isAnimating = false;

  List<Arrow> _arrows = [];
  final Random _rng = Random();

  // Getters
  int get difficultyIndex => _difficultyIndex;
  Difficulty get difficulty => kDifficulties[_difficultyIndex];
  int get lives => _lives;
  int get level => _level;
  int get score => _score;
  bool get gameOver => _gameOver;
  bool get levelWon => _levelWon;
  bool get isAnimating => _isAnimating;
  List<Arrow> get arrows => _arrows;
  int get gridSize => difficulty.gridSize;
  List<Arrow> get activeArrows => _arrows.where((a) => !a.cleared).toList();

  void setDifficulty(int index) {
    _difficultyIndex = index.clamp(0, kDifficulties.length - 1);
    notifyListeners();
  }

  /// Start a fresh game
  void startGame() {
    _lives = difficulty.lives;
    _level = 1;
    _score = 0;
    _gameOver = false;
    _levelWon = false;
    _isAnimating = false;
    _generateLevel();
    notifyListeners();
  }

  /// Advance to next level (called after win animation)
  void nextLevel() {
    _level++;
    _levelWon = false;
    _isAnimating = false;
    // Slightly increase count per level but cap at grid capacity
    _generateLevel();
    notifyListeners();
  }

  /// Generate a guaranteed-solvable level
  void _generateLevel() {
    final size = difficulty.gridSize;
    // Arrow count grows a little each level
    int count = (difficulty.arrowCount + (_level - 1)).clamp(
      difficulty.arrowCount,
      size * size - 1,
    );

    _arrows = _buildSolvableArrows(size, count);
  }

  /// Build a set of arrows where at least 1 is immediately free to clear.
  /// Strategy: place arrows one by one, then validate that at least one
  /// can slide to edge without hitting another.
  List<Arrow> _buildSolvableArrows(int size, int count) {
    for (int attempt = 0; attempt < 200; attempt++) {
      final arrows = _randomArrows(size, count);
      if (_hasFreeArrow(arrows, size)) return arrows;
    }
    // Fallback: build just a few guaranteed-free arrows
    return _guaranteedArrows(size, count);
  }

  List<Arrow> _randomArrows(int size, int count) {
    final occupied = <String>{};
    final list = <Arrow>[];
    int id = 0;
    int tries = 0;
    while (list.length < count && tries < 1000) {
      tries++;
      final col = _rng.nextInt(size);
      final row = _rng.nextInt(size);
      final key = '$col,$row';
      if (occupied.contains(key)) continue;
      occupied.add(key);
      final dir = ArrowDirection.values[_rng.nextInt(4)];
      list.add(Arrow(id: id++, col: col, row: row, direction: dir));
    }
    return list;
  }

  bool _hasFreeArrow(List<Arrow> arrows, int size) {
    for (final a in arrows) {
      if (_canClear(a, arrows, size)) return true;
    }
    return false;
  }

  bool _canClear(Arrow arrow, List<Arrow> allArrows, int size) {
    int c = arrow.col;
    int r = arrow.row;
    while (true) {
      switch (arrow.direction) {
        case ArrowDirection.up:    r--; break;
        case ArrowDirection.down:  r++; break;
        case ArrowDirection.left:  c--; break;
        case ArrowDirection.right: c++; break;
      }
      // Exited grid = clearable
      if (c < 0 || c >= size || r < 0 || r >= size) return true;
      // Hit another arrow = not clearable
      if (allArrows.any((a) => a.id != arrow.id && a.col == c && a.row == r)) {
        return false;
      }
    }
  }

  List<Arrow> _guaranteedArrows(int size, int count) {
    // Place arrows along edges pointing outward — always free
    final list = <Arrow>[];
    int id = 0;
    // Top row pointing up
    for (int c = 0; c < size && list.length < count; c++) {
      list.add(Arrow(id: id++, col: c, row: 0, direction: ArrowDirection.up));
    }
    // Fill remaining randomly without overlap
    final occupied = {for (final a in list) '${a.col},${a.row}'};
    int tries = 0;
    while (list.length < count && tries < 500) {
      tries++;
      final c = _rng.nextInt(size);
      final r = _rng.nextInt(size);
      final key = '$c,$r';
      if (occupied.contains(key)) continue;
      occupied.add(key);
      list.add(Arrow(
        id: id++,
        col: c,
        row: r,
        direction: ArrowDirection.values[_rng.nextInt(4)],
      ));
    }
    return list;
  }

  /// Tap handler — returns TapResult and triggers state changes.
  /// [onAnimationDone] is called after the flight animation completes.
  TapResult tapArrow(int arrowId, void Function() onAnimationDone) {
    if (_isAnimating) return TapResult.invalid;
    if (_gameOver || _levelWon) return TapResult.invalid;

    final idx = _arrows.indexWhere((a) => a.id == arrowId);
    if (idx == -1) return TapResult.invalid;
    final arrow = _arrows[idx];
    if (arrow.cleared) return TapResult.invalid;

    final size = difficulty.gridSize;

    // Check path
    final collision = _findCollision(arrow, size);

    if (collision != null) {
      // Collision: lose a life
      _lives--;
      if (_lives <= 0) {
        _lives = 0;
        _gameOver = true;
      }
      notifyListeners();
      return TapResult.collision;
    } else {
      // Clear: animate then mark cleared
      _isAnimating = true;
      _arrows[idx] = arrow.copyWith(animating: true);
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 450), () {
        final i2 = _arrows.indexWhere((a) => a.id == arrowId);
        if (i2 != -1) {
          _arrows[i2] = _arrows[i2].copyWith(animating: false, cleared: true);
        }
        _isAnimating = false;
        _score += 10;

        // Check win
        if (_arrows.every((a) => a.cleared)) {
          _levelWon = true;
          _score += 50 + (_level * 20); // level bonus
        }
        notifyListeners();
        onAnimationDone();
      });

      return TapResult.cleared;
    }
  }

  /// Returns the arrow that would be hit, or null if path is clear to edge.
  Arrow? _findCollision(Arrow arrow, int size) {
    int c = arrow.col;
    int r = arrow.row;
    while (true) {
      switch (arrow.direction) {
        case ArrowDirection.up:    r--; break;
        case ArrowDirection.down:  r++; break;
        case ArrowDirection.left:  c--; break;
        case ArrowDirection.right: c++; break;
      }
      if (c < 0 || c >= size || r < 0 || r >= size) return null;
      final hit = _arrows.where((a) => !a.cleared && a.col == c && a.row == r).firstOrNull;
      if (hit != null) return hit;
    }
  }

  void resetGame() {
    _gameOver = false;
    _levelWon = false;
    startGame();
  }
}
