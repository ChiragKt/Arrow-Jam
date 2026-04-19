import 'dart:math';
import 'package:flutter/foundation.dart';
import '../themes/app_themes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Arrow model
//
// An Arrow is a multi-cell span:
//   • (col, row)  — the HEAD cell (where the arrowhead is drawn)
//   • direction   — which way the arrow points (and the direction it travels)
//   • length      — how many cells it occupies (≥ 1)
//
// The cells it occupies are: head + (length-1) cells in the OPPOSITE direction.
// Example: head=(3,0), direction=right, length=3  →  occupies cols 1,2,3 row 0.
//
// Clearing rule: the arrow is clearable when every cell AHEAD of the head
// (in its direction) up to the grid boundary is either empty or already cleared.
// ─────────────────────────────────────────────────────────────────────────────

class Arrow {
  final int id;
  final int col;        // head column
  final int row;        // head row
  final ArrowDirection direction;
  final int length;     // number of cells this arrow spans (≥ 1)
  bool cleared;
  bool animating;

  Arrow({
    required this.id,
    required this.col,
    required this.row,
    required this.direction,
    required this.length,
    this.cleared  = false,
    this.animating = false,
  });

  /// All grid cells occupied by this arrow (head + body).
  List<_Pos> get cells {
    final result = <_Pos>[];
    int c = col, r = row;
    for (int i = 0; i < length; i++) {
      result.add(_Pos(c, r));
      // Body extends in the direction OPPOSITE to the arrow's direction
      switch (direction) {
        case ArrowDirection.up:    r++; break;
        case ArrowDirection.down:  r--; break;
        case ArrowDirection.left:  c++; break;
        case ArrowDirection.right: c--; break;
      }
    }
    return result;
  }

  Arrow copyWith({bool? cleared, bool? animating}) => Arrow(
    id: id, col: col, row: row,
    direction: direction, length: length,
    cleared:   cleared   ?? this.cleared,
    animating: animating ?? this.animating,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Difficulty
// ─────────────────────────────────────────────────────────────────────────────

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
  Difficulty(label: 'Easy',   emoji: '🟢', gridSize: 4, lives: 5, timeSeconds: 120),
  Difficulty(label: 'Normal', emoji: '🟡', gridSize: 5, lives: 4, timeSeconds:  90),
  Difficulty(label: 'Hard',   emoji: '🔴', gridSize: 6, lives: 3, timeSeconds:  70),
  Difficulty(label: 'Expert', emoji: '💀', gridSize: 7, lives: 3, timeSeconds:  50),
];

enum TapResult { cleared, collision, invalid }

// ─────────────────────────────────────────────────────────────────────────────
// GameState
// ─────────────────────────────────────────────────────────────────────────────

class GameState extends ChangeNotifier {
  int  _difficultyIndex  = -1;
  bool _randomDifficulty = true;

  int  _lives         = 4;
  int  _level         = 1;
  int  _score         = 0;
  bool _gameOver      = false;
  bool _levelWon      = false;
  bool _isAnimating   = false;
  int  _timeRemaining = 60;

  List<Arrow> _arrows = [];
  final Random _rng   = Random();
  late Difficulty _activeDifficulty;

  // ── getters ──────────────────────────────────────────────────────────────
  int        get difficultyIndex  => _difficultyIndex;
  bool       get randomDifficulty => _randomDifficulty;
  Difficulty get difficulty       => _activeDifficulty;
  Difficulty get selectedDifficulty => _difficultyIndex < 0
      ? kDifficulties[1] : kDifficulties[_difficultyIndex];
  int        get lives         => _lives;
  int        get level         => _level;
  int        get score         => _score;
  bool       get gameOver      => _gameOver;
  bool       get levelWon      => _levelWon;
  bool       get isAnimating   => _isAnimating;
  List<Arrow> get arrows       => _arrows;
  int        get gridSize      => _activeDifficulty.gridSize;
  int        get timeRemaining => _timeRemaining;

  GameState() { _activeDifficulty = kDifficulties[1]; }

  // ── public API ───────────────────────────────────────────────────────────

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
    _level       = 1;
    _score       = 0;
    _gameOver    = false;
    _levelWon    = false;
    _isAnimating = false;
    _resolveDifficulty();
    _lives = _activeDifficulty.lives;
    _generateLevel();
    notifyListeners();
  }

  void tick() {
    if (_gameOver || _levelWon) return;
    if (_timeRemaining <= 0) {
      _lives--;
      if (_lives <= 0) { _lives = 0; _gameOver = true; }
      else { _generateLevel(); }
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

  TapResult tapArrow(int arrowId, void Function() onAnimationDone) {
    if (_isAnimating || _gameOver || _levelWon) return TapResult.invalid;

    final idx = _arrows.indexWhere((a) => a.id == arrowId);
    if (idx == -1) return TapResult.invalid;
    final arrow = _arrows[idx];
    if (arrow.cleared || arrow.animating) return TapResult.invalid;

    if (!_canClearNow(arrow)) {
      _lives--;
      if (_lives <= 0) { _lives = 0; _gameOver = true; }
      notifyListeners();
      return TapResult.collision;
    }

    _isAnimating = true;
    _arrows[idx] = arrow.copyWith(animating: true);
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 450), () {
      final i2 = _arrows.indexWhere((a) => a.id == arrowId);
      if (i2 != -1) {
        _arrows[i2] = _arrows[i2].copyWith(animating: false, cleared: true);
      }
      _isAnimating = false;
      _score += 10 * arrow.length; // longer arrows = more points

      if (_arrows.every((a) => a.cleared)) {
        _levelWon = true;
        _score += 50 + (_level * 20);
      }
      notifyListeners();
      onAnimationDone();
    });

    return TapResult.cleared;
  }

  // ── private ───────────────────────────────────────────────────────────────

  void _resolveDifficulty() {
    _activeDifficulty = _randomDifficulty
        ? kDifficulties[_rng.nextInt(kDifficulties.length)]
        : kDifficulties[_difficultyIndex.clamp(0, kDifficulties.length - 1)];
  }

  void _generateLevel() {
    final size = _activeDifficulty.gridSize;
    _arrows = _buildGrid(size);
    _timeRemaining = (_activeDifficulty.timeSeconds - (_level - 1) * 3)
        .clamp(20, _activeDifficulty.timeSeconds);
  }

  // ─── clearability (live game) ────────────────────────────────────────────
  //
  // An arrow is clearable when every cell strictly AHEAD of its head
  // (in its direction, up to the grid boundary) is empty or already cleared.

  bool _canClearNow(Arrow arrow) {
    final size = _activeDifficulty.gridSize;
    int c = arrow.col, r = arrow.row;
    while (true) {
      switch (arrow.direction) {
        case ArrowDirection.up:    r--; break;
        case ArrowDirection.down:  r++; break;
        case ArrowDirection.left:  c--; break;
        case ArrowDirection.right: c++; break;
      }
      if (c < 0 || c >= size || r < 0 || r >= size) return true;
      // Is there any uncleared arrow whose body occupies (c, r)?
      final blocked = _arrows.any(
        (a) => !a.cleared && a.id != arrow.id && a.cells.any((p) => p.c == c && p.r == r),
      );
      if (blocked) return false;
    }
  }

  // ─── Grid generation ─────────────────────────────────────────────────────
  //
  // Concept  ── matches the reference image:
  //   • Every cell of the grid is occupied by exactly one arrow.
  //   • Arrows span multiple cells (length ≥ 1) in one direction.
  //   • Arrow lengths are randomised; they partition the grid completely
  //     (total cells covered = size × size).
  //   • Arrows form interlocked chains: the head of each arrow points
  //     toward the NEXT arrow in its chain, so you must clear them in order.
  //   • The puzzle is guaranteed solvable by simulation before use.
  //
  // Algorithm:
  //   1. Randomly partition all cells into straight runs (segments).
  //      A segment is a maximal run of consecutive cells in one direction.
  //   2. Within each segment, assign the arrow direction = segment direction,
  //      head = the cell at the "tip" of the segment (the end that faces
  //      toward the direction it points).
  //   3. Verify solvability; retry up to 100× if needed.

  List<Arrow> _buildGrid(int size) {
    for (int attempt = 0; attempt < 120; attempt++) {
      final result = _tryBuildGrid(size);
      if (result != null) return result;
    }
    return _fallbackGrid(size);
  }

  List<Arrow>? _tryBuildGrid(int size) {
    // ── Step 1: partition all cells into straight segments ──────────────────
    //
    // We do a random walk that partitions the grid into axis-aligned runs:
    //   • Maintain a grid of which cells are assigned.
    //   • Pick a random unassigned cell as segment start.
    //   • Pick a random direction; extend as far as possible (up to maxLen)
    //     through unassigned cells.
    //   • Record the segment.
    //   • Repeat until all cells assigned.

    final assigned = List.generate(size, (_) => List.filled(size, false));
    final segments = <_Segment>[];

    // Shuffle the cell order so segments start from random places
    final order = [for (int r = 0; r < size; r++) for (int c = 0; c < size; c++) _Pos(c, r)];
    order.shuffle(_rng);

    // Max segment length: up to half the grid size, minimum 1
    final maxLen = (size / 2).ceil().clamp(2, size);

    for (final start in order) {
      if (assigned[start.r][start.c]) continue;

      // Try all four directions in random order
      final dirs = ArrowDirection.values.toList()..shuffle(_rng);
      bool placed = false;

      for (final d in dirs) {
        // Measure how far we can extend from start in direction d
        int len = 0;
        int c = start.c, r = start.r;
        while (len < maxLen) {
          if (c < 0 || c >= size || r < 0 || r >= size) break;
          if (assigned[r][c]) break;
          len++;
          switch (d) {
            case ArrowDirection.up:    r--; break;
            case ArrowDirection.down:  r++; break;
            case ArrowDirection.left:  c--; break;
            case ArrowDirection.right: c++; break;
          }
        }
        if (len == 0) continue;

        // Randomly shorten the segment (so lengths are varied, not always maxLen)
        // At minimum keep 1 cell.
        final segLen = len == 1 ? 1 : (1 + _rng.nextInt(len));

        // Mark those cells as assigned and record the segment.
        // The HEAD is the cell at the far end (the tip in direction d).
        int hc = start.c, hr = start.r;
        for (int i = 0; i < segLen; i++) {
          assigned[hr][hc] = true;
          if (i < segLen - 1) {
            switch (d) {
              case ArrowDirection.up:    hr--; break;
              case ArrowDirection.down:  hr++; break;
              case ArrowDirection.left:  hc--; break;
              case ArrowDirection.right: hc++; break;
            }
          }
        }
        // hc, hr is now the tip cell (the head of the arrow)
        segments.add(_Segment(headCol: hc, headRow: hr, direction: d, length: segLen));
        placed = true;
        break;
      }

      if (!placed) return null; // couldn't fit — retry
    }

    // ── Step 2: convert segments to Arrows ──────────────────────────────────
    final arrows = <Arrow>[];
    int id = 0;
    for (final seg in segments) {
      arrows.add(Arrow(
        id:        id++,
        col:       seg.headCol,
        row:       seg.headRow,
        direction: seg.direction,
        length:    seg.length,
      ));
    }

    // ── Step 3: verify all cells are covered exactly once ───────────────────
    final coverage = List.generate(size, (_) => List.filled(size, 0));
    for (final a in arrows) {
      for (final p in a.cells) {
        if (p.c < 0 || p.c >= size || p.r < 0 || p.r >= size) return null;
        coverage[p.r][p.c]++;
      }
    }
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (coverage[r][c] != 1) return null;
      }
    }

    // ── Step 4: verify solvability ───────────────────────────────────────────
    if (!_isSolvable(arrows, size)) return null;

    return arrows;
  }

  // ─── Solvability simulation ───────────────────────────────────────────────
  //
  // Repeatedly find arrows whose path-ahead is clear and "clear" them,
  // until no more progress or all cleared.  Must reach 100%.

  bool _isSolvable(List<Arrow> arrows, int size) {
    final cleared = List.filled(arrows.length, false);

    bool progress = true;
    while (progress) {
      progress = false;
      for (int i = 0; i < arrows.length; i++) {
        if (cleared[i]) continue;
        if (_canClearSim(arrows[i], arrows, cleared, size)) {
          cleared[i] = true;
          progress   = true;
        }
      }
    }
    return cleared.every((c) => c);
  }

  bool _canClearSim(Arrow arrow, List<Arrow> all, List<bool> cleared, int size) {
    int c = arrow.col, r = arrow.row;
    while (true) {
      switch (arrow.direction) {
        case ArrowDirection.up:    r--; break;
        case ArrowDirection.down:  r++; break;
        case ArrowDirection.left:  c--; break;
        case ArrowDirection.right: c++; break;
      }
      if (c < 0 || c >= size || r < 0 || r >= size) return true;
      // Any uncleared arrow body at (c, r)?
      for (int i = 0; i < all.length; i++) {
        if (cleared[i] || all[i].id == arrow.id) continue;
        if (all[i].cells.any((p) => p.c == c && p.r == r)) return false;
      }
    }
  }

  // ─── Fallback grid ────────────────────────────────────────────────────────
  //
  // Trivially solvable: each column is one vertical arrow pointing up.
  // Guarantees: all cells covered, all immediately clearable (pointing to edge).

  List<Arrow> _fallbackGrid(int size) {
    final arrows = <Arrow>[];
    for (int c = 0; c < size; c++) {
      arrows.add(Arrow(
        id:        c,
        col:       c,
        row:       0,               // head at top
        direction: ArrowDirection.up,
        length:    size,            // spans entire column
      ));
    }
    return arrows;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Pos {
  final int c, r;
  const _Pos(this.c, this.r);

  @override
  bool operator ==(Object other) => other is _Pos && other.c == c && other.r == r;

  @override
  int get hashCode => c * 1000 + r;
}

class _Segment {
  final int headCol, headRow;
  final ArrowDirection direction;
  final int length;
  const _Segment({
    required this.headCol,
    required this.headRow,
    required this.direction,
    required this.length,
  });
}
