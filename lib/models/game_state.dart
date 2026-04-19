import 'dart:math';
import 'package:flutter/foundation.dart';
import '../themes/app_themes.dart';

class Arrow {
  final int id;
  int col;
  int row;
  ArrowDirection direction;
  bool cleared;
  bool animating;

  Arrow({
    required this.id,
    required this.col,
    required this.row,
    required this.direction,
    this.cleared = false,
    this.animating = false,
  });

  Arrow copyWith({int? col, int? row, ArrowDirection? direction, bool? cleared, bool? animating}) {
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

class Difficulty {
  final String label;
  final String emoji;
  final int gridSize;
  final int arrowCount;
  final int lives;
  final int timeSeconds;

  const Difficulty({
    required this.label,
    required this.emoji,
    required this.gridSize,
    required this.arrowCount,
    required this.lives,
    required this.timeSeconds,
  });
}

const List<Difficulty> kDifficulties = [
  Difficulty(label: 'Easy',   emoji: '🟢', gridSize: 4, arrowCount: 5,  lives: 5, timeSeconds: 90),
  Difficulty(label: 'Normal', emoji: '🟡', gridSize: 5, arrowCount: 8,  lives: 4, timeSeconds: 70),
  Difficulty(label: 'Hard',   emoji: '🔴', gridSize: 6, arrowCount: 12, lives: 3, timeSeconds: 50),
  Difficulty(label: 'Expert', emoji: '💀', gridSize: 7, arrowCount: 18, lives: 3, timeSeconds: 35),
];

enum TapResult { cleared, collision, invalid }

class GameState extends ChangeNotifier {
  int _difficultyIndex = -1; // -1 = random
  bool _randomDifficulty = true;

  int _lives = 4;
  int _level = 1;
  int _score = 0;
  bool _gameOver = false;
  bool _levelWon = false;
  bool _isAnimating = false;
  int _timeRemaining = 60;

  List<Arrow> _arrows = [];
  final Random _rng = Random();

  // resolved difficulty for current game
  late Difficulty _activeDifficulty;

  // Getters
  int get difficultyIndex => _difficultyIndex;
  bool get randomDifficulty => _randomDifficulty;
  Difficulty get difficulty => _activeDifficulty;
  Difficulty get selectedDifficulty => _difficultyIndex < 0
      ? kDifficulties[1]
      : kDifficulties[_difficultyIndex];
  int get lives => _lives;
  int get level => _level;
  int get score => _score;
  bool get gameOver => _gameOver;
  bool get levelWon => _levelWon;
  bool get isAnimating => _isAnimating;
  List<Arrow> get arrows => _arrows;
  int get gridSize => _activeDifficulty.gridSize;
  int get timeRemaining => _timeRemaining;

  GameState() {
    _activeDifficulty = kDifficulties[1]; // default until startGame
  }

  void setRandomDifficulty(bool value) {
    _randomDifficulty = value;
    if (!value && _difficultyIndex < 0) _difficultyIndex = 1;
    notifyListeners();
  }

  void setDifficulty(int index) {
    _difficultyIndex = index.clamp(0, kDifficulties.length - 1);
    _randomDifficulty = false;
    notifyListeners();
  }

  void startGame() {
    _level = 1;
    _score = 0;
    _gameOver = false;
    _levelWon = false;
    _isAnimating = false;
    _resolveDifficulty();
    _lives = _activeDifficulty.lives;
    _generateLevel();
    notifyListeners();
  }

  void _resolveDifficulty() {
    if (_randomDifficulty) {
      _activeDifficulty = kDifficulties[_rng.nextInt(kDifficulties.length)];
    } else {
      _activeDifficulty = kDifficulties[_difficultyIndex.clamp(0, kDifficulties.length - 1)];
    }
  }

  /// Called every second by the UI timer
  void tick() {
    if (_gameOver || _levelWon) return;
    if (_timeRemaining <= 0) {
      _lives--;
      if (_lives <= 0) {
        _lives = 0;
        _gameOver = true;
      } else {
        // Retry same level
        _generateLevel();
      }
      notifyListeners();
      return;
    }
    _timeRemaining--;
    notifyListeners();
  }

  void nextLevel() {
    _level++;
    _levelWon = false;
    _isAnimating = false;
    _generateLevel();
    notifyListeners();
  }

  void _generateLevel() {
    final size = _activeDifficulty.gridSize;
    int count = (_activeDifficulty.arrowCount + (_level - 1)).clamp(
      _activeDifficulty.arrowCount,
      size * size - 1,
    );
    _arrows = _buildSolvableArrows(size, count);
    _timeRemaining = (_activeDifficulty.timeSeconds - (_level - 1) * 3).clamp(15, _activeDifficulty.timeSeconds);
  }

  List<Arrow> _buildSolvableArrows(int size, int count) {
    for (int attempt = 0; attempt < 300; attempt++) {
      final arrows = _randomArrows(size, count);
      if (_hasFreeArrow(arrows, size)) return arrows;
    }
    return _guaranteedArrows(size, count);
  }

  List<Arrow> _randomArrows(int size, int count) {
    final occupied = <String>{};
    final list = <Arrow>[];
    int id = 0, tries = 0;
    while (list.length < count && tries < 1000) {
      tries++;
      final col = _rng.nextInt(size);
      final row = _rng.nextInt(size);
      final key = '$col,$row';
      if (occupied.contains(key)) continue;
      occupied.add(key);
      list.add(Arrow(id: id++, col: col, row: row, direction: ArrowDirection.values[_rng.nextInt(4)]));
    }
    return list;
  }

  bool _hasFreeArrow(List<Arrow> arrows, int size) {
    for (final a in arrows) {
      if (_canClear(a, arrows, size)) return true;
    }
    return false;
  }

  bool _canClear(Arrow arrow, List<Arrow> all, int size) {
    int c = arrow.col, r = arrow.row;
    while (true) {
      switch (arrow.direction) {
        case ArrowDirection.up:    r--; break;
        case ArrowDirection.down:  r++; break;
        case ArrowDirection.left:  c--; break;
        case ArrowDirection.right: c++; break;
      }
      if (c < 0 || c >= size || r < 0 || r >= size) return true;
      if (all.any((a) => a.id != arrow.id && a.col == c && a.row == r)) return false;
    }
  }

  List<Arrow> _guaranteedArrows(int size, int count) {
    final list = <Arrow>[];
    int id = 0;
    for (int c = 0; c < size && list.length < count; c++) {
      list.add(Arrow(id: id++, col: c, row: 0, direction: ArrowDirection.up));
    }
    final occupied = {for (final a in list) '${a.col},${a.row}'};
    int tries = 0;
    while (list.length < count && tries < 500) {
      tries++;
      final c = _rng.nextInt(size);
      final r = _rng.nextInt(size);
      final key = '$c,$r';
      if (occupied.contains(key)) continue;
      occupied.add(key);
      list.add(Arrow(id: id++, col: c, row: r, direction: ArrowDirection.values[_rng.nextInt(4)]));
    }
    return list;
  }

  TapResult tapArrow(int arrowId, void Function() onAnimationDone) {
    if (_isAnimating) return TapResult.invalid;
    if (_gameOver || _levelWon) return TapResult.invalid;

    final idx = _arrows.indexWhere((a) => a.id == arrowId);
    if (idx == -1) return TapResult.invalid;
    final arrow = _arrows[idx];
    if (arrow.cleared || arrow.animating) return TapResult.invalid;

    final size = _activeDifficulty.gridSize;
    final collision = _findCollision(arrow, size);

    if (collision != null) {
      _lives--;
      if (_lives <= 0) {
        _lives = 0;
        _gameOver = true;
      }
      notifyListeners();
      return TapResult.collision;
    } else {
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

        if (_arrows.every((a) => a.cleared)) {
          _levelWon = true;
          _score += 50 + (_level * 20);
        }
        notifyListeners();
        onAnimationDone();
      });

      return TapResult.cleared;
    }
  }

  Arrow? _findCollision(Arrow arrow, int size) {
    int c = arrow.col, r = arrow.row;
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
