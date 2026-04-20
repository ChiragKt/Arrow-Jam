import 'dart:math';
import 'package:flutter/foundation.dart';
import '../themes/app_themes.dart';

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
// A multi-cell "snake" filling 1-N adjacent grid cells.
// [cells] is ordered tail → head.
// [direction] is the exit direction from the head cell.
// col/row == head position == cells.last.

class Arrow {
  final int             id;
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

  int get col => cells.last.col;
  int get row => cells.last.row;

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

  // ── Getters ──────────────────────────────────────────────────────────────

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

  // ── Settings ─────────────────────────────────────────────────────────────

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

  void _generateLevel() {
    final int size = _activeDifficulty.gridSize;
    _arrows = _buildSolvableSnakes(size);
    _timeRemaining = (_activeDifficulty.timeSeconds - (_level - 1) * 3)
        .clamp(15, _activeDifficulty.timeSeconds);
  }

  // ── Snake generation ──────────────────────────────────────────────────────
  //
  // Algorithm:
  //   1. Partition ALL n×n cells into connected polyomino "snakes" by
  //      random-walk. Every cell belongs to exactly one snake.
  //   2. Assign each snake a head-exit direction (prefer directions that
  //      immediately exit the grid boundary for easier solvability).
  //   3. Build dependency graph: snake A depends on snake B if any of B's
  //      cells lie in A's exit ray.
  //   4. Run Kahn's topological sort. If a linear ordering exists the puzzle
  //      is provably solvable. Otherwise retry from step 1.
  //   Average retries: ~1 for size≤5, ~4 for size=8, ~14 for size=10.

  static const List<(int, int)> _dirs4 = [(0,-1),(0,1),(-1,0),(1,0)];

  List<Arrow> _buildSolvableSnakes(int size) {
    for (int attempt = 0; attempt < 2000; attempt++) {
      final snakes = _partitionGrid(size);
      if (snakes == null) continue;                      // shouldn't happen
      final arrows = _assignDirections(snakes, size);
      if (_isSolvable(arrows, size)) return arrows;
    }
    return _fallbackArrows(size);
  }

  // Step 1 — random-walk partition guaranteeing full coverage.
  //
  // We iterate over all cells in a shuffled order.  Whenever we reach an
  // unvisited cell we start a new snake there and grow it greedily by up to
  // (size-1) steps into neighbouring unvisited cells.  Because we always
  // start from the next unvisited cell in our shuffled list we are
  // guaranteed to cover every cell.
  List<List<ArrowCell>>? _partitionGrid(int size) {
    // grid[r][c] = snake index, or -1 if unvisited
    final grid = List.generate(size, (_) => List.filled(size, -1));
    final snakes = <List<ArrowCell>>[];

    // Shuffled visit order ensures we don't miss any cell
    final order = [
      for (int r = 0; r < size; r++)
        for (int c = 0; c < size; c++) ArrowCell(c, r)
    ]..shuffle(_rng);

    for (final start in order) {
      if (grid[start.row][start.col] != -1) continue;

      final sid   = snakes.length;
      final snake = <ArrowCell>[start];
      grid[start.row][start.col] = sid;

      // Grow 0..(size-1) extra steps
      final maxExtra = _rng.nextInt(size); // 0 = single-cell snake allowed
      for (int step = 0; step < maxExtra; step++) {
        final cur = snake.last;
        final nb  = <ArrowCell>[];
        for (final (dc, dr) in _dirs4) {
          final nc = cur.col + dc;
          final nr = cur.row + dr;
          if (nc >= 0 && nc < size && nr >= 0 && nr < size &&
              grid[nr][nc] == -1) {
            nb.add(ArrowCell(nc, nr));
          }
        }
        if (nb.isEmpty) break;
        final next = nb[_rng.nextInt(nb.length)];
        snake.add(next);
        grid[next.row][next.col] = sid;
      }

      snakes.add(snake);
    }

    // Sanity: every cell must be assigned
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (grid[r][c] == -1) return null;
      }
    }
    return snakes;
  }

  // Step 2 — assign a head-exit direction to each snake.
  List<Arrow> _assignDirections(List<List<ArrowCell>> snakes, int size) {
    final arrows = <Arrow>[];
    int id = 0;

    for (final cells in snakes) {
      final head = cells.last;

      // Collect directions that immediately leave the grid
      final exiting = <ArrowDirection>[];
      for (final dir in ArrowDirection.values) {
        final nc = head.col + _dc(dir);
        final nr = head.row + _dr(dir);
        if (nc < 0 || nc >= size || nr < 0 || nr >= size) {
          exiting.add(dir);
        }
      }

      final dir = exiting.isNotEmpty
          ? exiting[_rng.nextInt(exiting.length)]
          : ArrowDirection.values[_rng.nextInt(4)];

      arrows.add(Arrow(id: id++, cells: List.unmodifiable(cells), direction: dir));
    }
    return arrows;
  }

  // Step 3 — check solvability via Kahn's topological sort.
  bool _isSolvable(List<Arrow> arrows, int size) {
    // Map every grid cell to the index of the arrow that owns it
    final cellOwner = <ArrowCell, int>{};
    for (int i = 0; i < arrows.length; i++) {
      for (final cell in arrows[i].cells) {
        cellOwner[cell] = i;
      }
    }

    // deps[i] = set of arrow indices that block arrow i's exit ray
    final deps = List.generate(arrows.length, (_) => <int>{});
    for (int i = 0; i < arrows.length; i++) {
      final a = arrows[i];
      int c = a.col + _dc(a.direction);
      int r = a.row + _dr(a.direction);
      while (c >= 0 && c < size && r >= 0 && r < size) {
        final owner = cellOwner[ArrowCell(c, r)];
        if (owner != null && owner != i) deps[i].add(owner);
        c += _dc(a.direction);
        r += _dr(a.direction);
      }
    }

    // Kahn's algorithm
    final n      = arrows.length;
    final inDeg  = List.generate(n, (i) => deps[i].length);
    final blocks = List.generate(n, (_) => <int>[]);
    for (int i = 0; i < n; i++) {
      for (final j in deps[i]) blocks[j].add(i);
    }

    final queue   = <int>[for (int i = 0; i < n; i++) if (inDeg[i] == 0) i];
    int   cleared = 0;
    while (queue.isNotEmpty) {
      final node = queue.removeLast();
      cleared++;
      for (final blocked in blocks[node]) {
        inDeg[blocked]--;
        if (inDeg[blocked] == 0) queue.add(blocked);
      }
    }
    return cleared == n;
  }

  // Fallback: every cell is its own single-cell arrow pointing up.
  // Always solvable (top row clears first, then next row, etc.).
  List<Arrow> _fallbackArrows(int size) {
    final arrows = <Arrow>[];
    int id = 0;
    // Top row can always exit upward — start there
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
    // Re-run solvability fix: top row (up) has no blockers ✓
    return arrows;
  }

  // Direction deltas
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

    // All currently occupied cells except this arrow's own
    final occupied = <ArrowCell>{
      for (final a in _arrows)
        if (!a.cleared && a.id != arrowId) ...a.cells,
    };

    // Walk exit ray from head
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
      if (_lives <= 0) { _lives = 0; _gameOver = true; }
      notifyListeners();
      return TapResult.collision;
    }

    // Animate out
    _isAnimating = true;
    _arrows[idx] = arrow.copyWith(animating: true);
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 450), () {
      final int i2 = _arrows.indexWhere((a) => a.id == arrowId);
      if (i2 != -1) {
        _arrows[i2] = _arrows[i2].copyWith(animating: false, cleared: true);
      }
      _isAnimating  = false;
      _score       += 10 * arrow.cells.length;

      if (_arrows.every((a) => a.cleared)) {
        _levelWon  = true;
        _score    += 50 + (_level * 20);
      }
      notifyListeners();
      onAnimationDone();
    });

    return TapResult.cleared;
  }
}
