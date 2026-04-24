import 'dart:math';
import 'package:flutter/foundation.dart';
import '../themes/app_themes.dart';
import '../services/storage_service.dart';

// ── ArrowCell ─────────────────────────────────────────────────────────────────

class ArrowCell {
  final int col;
  final int row;
  const ArrowCell(this.col, this.row);

  @override
  bool operator ==(Object other) =>
      other is ArrowCell && other.col == col && other.row == row;
  @override
  int get hashCode => col * 1000 + row;
  @override
  String toString() => '($col,$row)';
}

// ── Arrow ─────────────────────────────────────────────────────────────────────

class Arrow {
  final int            id;
  final List<ArrowCell> cells;
  final ArrowDirection  direction;
  bool cleared;
  bool animating;

  Arrow({
    required this.id,
    required this.cells,
    required this.direction,
    this.cleared   = false,
    this.animating = false,
  });

  int get col => cells.first.col;
  int get row => cells.first.row;

  Arrow copyWith({bool? cleared, bool? animating}) => Arrow(
    id:        id,
    cells:     cells,
    direction: direction,
    cleared:   cleared   ?? this.cleared,
    animating: animating ?? this.animating,
  );
}

// ── Difficulty ────────────────────────────────────────────────────────────────

class Difficulty {
  final String label;
  final String emoji;
  final int    gridSize;
  final int    lives;
  final int    timeSeconds;

  const Difficulty({
    required this.label,
    required this.emoji,
    required this.gridSize,
    required this.lives,
    required this.timeSeconds,
  });
}

const List<Difficulty> kDifficulties = [
  Difficulty(label: 'Easy',   emoji: '🟢', gridSize: 4, lives: 5, timeSeconds: 90),
  Difficulty(label: 'Normal', emoji: '🟡', gridSize: 5, lives: 4, timeSeconds: 70),
  Difficulty(label: 'Hard',   emoji: '🔴', gridSize: 6, lives: 3, timeSeconds: 50),
  Difficulty(label: 'Expert', emoji: '💀', gridSize: 7, lives: 3, timeSeconds: 35),
];

Difficulty _customDifficulty(int size) => Difficulty(
  label:       'Custom',
  emoji:       '🔧',
  gridSize:    size,
  lives:       (size / 2).ceil().clamp(2, 6),
  timeSeconds: (size * size * 2.5).toInt().clamp(20, 180),
);

// ── TapResult ─────────────────────────────────────────────────────────────────

enum TapResult { cleared, collision, invalid }

// ── GameState ─────────────────────────────────────────────────────────────────

class GameState extends ChangeNotifier {
  // ── Mode selection ────────────────────────────────────────────────────────
  int  _difficultyIndex  = -1;
  bool _randomDifficulty = true;
  bool _isCustom         = false;
  int  _customGridSize   = 5;

  // ── Runtime state ─────────────────────────────────────────────────────────
  int  _lives         = 4;
  int  _level         = 1;
  int  _score         = 0;
  bool _gameOver      = false;
  bool _levelWon      = false;
  bool _isAnimating   = false;
  int  _timeRemaining = 60;
  int  _generation    = 0;

  List<Arrow>  _arrows = [];
  final Random _rng    = Random();
  late Difficulty _activeDifficulty;

  final StorageService _storage = StorageService();

  // ── Getters ───────────────────────────────────────────────────────────────

  int         get difficultyIndex    => _difficultyIndex;
  bool        get randomDifficulty   => _randomDifficulty;
  bool        get isCustom           => _isCustom;
  int         get customGridSize     => _customGridSize;
  Difficulty  get difficulty         => _activeDifficulty;
  Difficulty  get selectedDifficulty => _isCustom
      ? _customDifficulty(_customGridSize)
      : (_difficultyIndex < 0 ? kDifficulties[1] : kDifficulties[_difficultyIndex]);
  int         get lives              => _lives;
  int         get level              => _level;
  int         get score              => _score;
  bool        get gameOver           => _gameOver;
  bool        get levelWon           => _levelWon;
  bool        get isAnimating        => _isAnimating;
  List<Arrow> get arrows             => _arrows;
  int         get gridSize           => _activeDifficulty.gridSize;
  int         get timeRemaining      => _timeRemaining;
  int         get generation         => _generation;

  GameState() {
    _activeDifficulty = kDifficulties[1];
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  void setRandomDifficulty(bool value) {
    _randomDifficulty = value;
    _isCustom         = false;
    if (!value && _difficultyIndex < 0) _difficultyIndex = 1;
    notifyListeners();
  }

  void setDifficulty(int index) {
    _difficultyIndex  = index.clamp(0, kDifficulties.length - 1);
    _randomDifficulty = false;
    _isCustom         = false;
    notifyListeners();
  }

  void setCustom(int gridSize) {
    _customGridSize   = gridSize.clamp(3, 10);
    _isCustom         = true;
    _randomDifficulty = false;
    notifyListeners();
  }

  // ── Game flow ─────────────────────────────────────────────────────────────

  void startGame() {
    _generation++;
    _level       = 1;
    _score       = 0;
    _gameOver    = false;
    _levelWon    = false;
    _isAnimating = false;
    _resolveDifficulty();
    _lives = _activeDifficulty.lives;
    _generateLevel();
    notifyListeners();
    // Persist: count a new game session
    _storage.incrementGamesPlayed();
  }

  void _resolveDifficulty() {
    if (_isCustom) {
      _activeDifficulty = _customDifficulty(_customGridSize);
    } else if (_randomDifficulty) {
      _activeDifficulty = kDifficulties[_rng.nextInt(kDifficulties.length)];
    } else {
      _activeDifficulty =
          kDifficulties[_difficultyIndex.clamp(0, kDifficulties.length - 1)];
    }
  }

  void tick() {
    if (_gameOver || _levelWon) return;
    if (_timeRemaining <= 0) {
      _lives--;
      if (_lives <= 0) {
        _lives    = 0;
        _gameOver = true;
        // Persist: game-over via time-out
        _storage.incrementGameOvers();
      } else {
        _generation++;
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
    _levelWon    = false;
    _isAnimating = false;
    _generateLevel();
    notifyListeners();
  }

  void resetGame() {
    _gameOver = false;
    _levelWon = false;
    startGame();
  }

  /// Rewarded-ad continuation: restore one life and resume from current level.
  /// Call this inside `AdService().showRewarded(onRewarded: () { gs.continueAfterGameOver(); })`.
  void continueAfterGameOver() {
    _gameOver    = false;
    _lives       = 1;        // one last life to keep going
    _isAnimating = false;
    _generateLevel();        // fresh puzzle, same level
    notifyListeners();
  }

  void _generateLevel() {
    final int size = _activeDifficulty.gridSize;
    _arrows = _buildSolvablePuzzle(size);
    _timeRemaining = (_activeDifficulty.timeSeconds - (_level - 1) * 3)
        .clamp(15, _activeDifficulty.timeSeconds);
  }

  // ── Puzzle generation ─────────────────────────────────────────────────────

  List<Arrow> _buildSolvablePuzzle(int size) {
    final n = size * size;

    final cells = [
      for (int r = 0; r < size; r++)
        for (int c = 0; c < size; c++) ArrowCell(c, r),
    ]..shuffle(_rng);

    final assignment = List<ArrowDirection?>.filled(n, null);

    final cellIndex = <ArrowCell, int>{};
    for (int i = 0; i < n; i++) cellIndex[cells[i]] = i;

    int dc(ArrowDirection d) => switch (d) {
      ArrowDirection.left  => -1,
      ArrowDirection.right =>  1,
      _                    =>  0,
    };
    int dr(ArrowDirection d) => switch (d) {
      ArrowDirection.up   => -1,
      ArrowDirection.down =>  1,
      _                   =>  0,
    };

    List<int> rayTargets(int idx, ArrowDirection d) {
      final cell = cells[idx];
      final targets = <int>[];
      int c = cell.col + dc(d);
      int r = cell.row + dr(d);
      while (c >= 0 && c < size && r >= 0 && r < size) {
        final t = cellIndex[ArrowCell(c, r)];
        if (t != null) targets.add(t);
        c += dc(d);
        r += dr(d);
      }
      return targets;
    }

    final adj = List.generate(n, (_) => <int>{});

    bool hasCycle(int start) {
      final colour = List.filled(n, 0);
      final stack  = <(int, bool)>[];
      stack.add((start, false));

      while (stack.isNotEmpty) {
        final (node, isReturn) = stack.removeLast();
        if (isReturn)          { colour[node] = 2; continue; }
        if (colour[node] == 2)   continue;
        if (colour[node] == 1)   return true;

        colour[node] = 1;
        stack.add((node, true));

        for (final nb in adj[node]) {
          if (colour[nb] == 1) return true;
          if (colour[nb] == 0) stack.add((nb, false));
        }
      }
      return false;
    }

    bool backtrack(int idx) {
      if (idx == n) return true;

      final dirs = ArrowDirection.values.toList()..shuffle(_rng);

      for (final dir in dirs) {
        final targets = rayTargets(idx, dir);
        for (final t in targets) adj[idx].add(t);

        if (!hasCycle(idx)) {
          assignment[idx] = dir;
          if (backtrack(idx + 1)) return true;
        }

        for (final t in targets) adj[idx].remove(t);
        assignment[idx] = null;
      }

      return false;
    }

    final solved = backtrack(0);
    if (!solved) return _fallbackArrows(size);

    final arrows = <Arrow>[];
    for (int i = 0; i < n; i++) {
      arrows.add(Arrow(
        id:        i,
        cells:     [cells[i]],
        direction: assignment[i]!,
      ));
    }

    if (!_isSolvable(arrows, size)) return _fallbackArrows(size);
    return arrows;
  }

  bool _isSolvable(List<Arrow> arrows, int size) {
    final cleared  = List.filled(arrows.length, false);
    int  remaining = arrows.length;

    while (remaining > 0) {
      bool progress = false;

      for (int i = 0; i < arrows.length; i++) {
        if (cleared[i]) continue;

        final arrow = arrows[i];
        final int dCol = _dc(arrow.direction);
        final int dRow = _dr(arrow.direction);

        bool blocked = false;
        int  c       = arrow.col + dCol;
        int  r       = arrow.row + dRow;
        outer:
        while (c >= 0 && c < size && r >= 0 && r < size) {
          for (int j = 0; j < arrows.length; j++) {
            if (!cleared[j] && arrows[j].col == c && arrows[j].row == r) {
              blocked = true;
              break outer;
            }
          }
          c += dCol;
          r += dRow;
        }

        if (!blocked) {
          cleared[i] = true;
          remaining--;
          progress   = true;
        }
      }

      if (!progress) return false;
    }

    return true;
  }

  List<Arrow> _fallbackArrows(int size) {
    final arrows = <Arrow>[];
    int id = 0;
    for (int r = 0; r < size; r++) {
      final dir = r == 0 ? ArrowDirection.up : ArrowDirection.down;
      for (int c = 0; c < size; c++) {
        arrows.add(Arrow(
          id:        id++,
          cells:     [ArrowCell(c, r)],
          direction: dir,
        ));
      }
    }
    return arrows;
  }

  int _dc(ArrowDirection d) => switch (d) {
    ArrowDirection.left  => -1,
    ArrowDirection.right =>  1,
    _                    =>  0,
  };
  int _dr(ArrowDirection d) => switch (d) {
    ArrowDirection.up   => -1,
    ArrowDirection.down =>  1,
    _                   =>  0,
  };

  // ── Tap handling ──────────────────────────────────────────────────────────

  TapResult tapArrow(int arrowId, void Function() onAnimationDone) {
    if (_isAnimating)           return TapResult.invalid;
    if (_gameOver || _levelWon) return TapResult.invalid;

    final int idx = _arrows.indexWhere((a) => a.id == arrowId);
    if (idx == -1)              return TapResult.invalid;

    final arrow = _arrows[idx];
    if (arrow.cleared || arrow.animating) return TapResult.invalid;

    final int size = _activeDifficulty.gridSize;

    final occupied = <ArrowCell>{
      for (final a in _arrows)
        if (!a.cleared && a.id != arrowId) ...a.cells,
    };

    int  c       = arrow.col + _dc(arrow.direction);
    int  r       = arrow.row + _dr(arrow.direction);
    bool blocked = false;
    while (c >= 0 && c < size && r >= 0 && r < size) {
      if (occupied.contains(ArrowCell(c, r))) { blocked = true; break; }
      c += _dc(arrow.direction);
      r += _dr(arrow.direction);
    }

    if (blocked) {
      _lives--;
      if (_lives <= 0) {
        _lives    = 0;
        _gameOver = true;
        // Persist: game-over via collision
        _storage.incrementGameOvers();
      }
      notifyListeners();
      return TapResult.collision;
    }

    _isAnimating = true;
    _arrows[idx] = arrow.copyWith(animating: true);
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 450), () {
      final int i2 = _arrows.indexWhere((a) => a.id == arrowId);
      if (i2 != -1) {
        _arrows[i2] = _arrows[i2].copyWith(animating: false, cleared: true);
      }
      _isAnimating  = false;
      _score       += 10;

      if (_arrows.every((a) => a.cleared)) {
        _levelWon  = true;
        _score    += 50 + (_level * 20);
        // Persist: level cleared
        _storage.incrementLevelClears();
      }
      notifyListeners();
      onAnimationDone();
    });

    return TapResult.cleared;
  }
}
