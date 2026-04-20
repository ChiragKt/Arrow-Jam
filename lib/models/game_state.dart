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
// Every arrow occupies exactly ONE cell.
// [direction] is the exit direction the arrow must fire in.

class Arrow {
  final int            id;
  final List<ArrowCell> cells; // always length 1
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
    _arrows = _buildSolvablePuzzle(size);
    _timeRemaining = (_activeDifficulty.timeSeconds - (_level - 1) * 3)
        .clamp(15, _activeDifficulty.timeSeconds);
  }

  // ── Puzzle generation — one cell per arrow, backtracking ─────────────────
  //
  // Every cell in the n×n grid gets exactly one arrow.
  // We assign directions via backtracking over a randomised cell order so
  // the resulting dependency graph is a DAG (i.e. the puzzle is solvable).
  //
  // A direction assignment is valid iff:
  //   • It does not create a cycle in the dependency graph built so far.
  //
  // We detect cycles incrementally with a lightweight DFS after each
  // assignment rather than running the full topological sort every time.

  List<Arrow> _buildSolvablePuzzle(int size) {
    final n = size * size;

    // Cells in a random order — this is our backtracking variable order.
    final cells = [
      for (int r = 0; r < size; r++)
        for (int c = 0; c < size; c++) ArrowCell(c, r),
    ]..shuffle(_rng);

    // assignment[i] = direction chosen for cells[i], or null if unassigned.
    final assignment = List<ArrowDirection?>.filled(n, null);

    // cellIndex maps ArrowCell → index in [cells].
    final cellIndex = <ArrowCell, int>{};
    for (int i = 0; i < n; i++) cellIndex[cells[i]] = i;

    // Direction delta helpers (inlined for speed).
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

    // Build adjacency: adj[i] = list of cell indices that cell i BLOCKS
    // (i.e. lie on i's exit ray) given direction d.
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

    // adj[i] = set of nodes that i points TO (i must fire after them).
    // Edge i→j means "i depends on j" (j must be cleared before i can fire).
    // Cycle check: after assigning direction to node [idx] we add edges
    // idx → each target in its ray, then check the graph is still a DAG.
    final adj = List.generate(n, (_) => <int>{});

    // DFS-based cycle detection on partial graph.
    // Returns true if there is a cycle reachable from [start].
    bool hasCycle(int start) {
      // Simple DFS with colour marking (0=white,1=grey,2=black).
      final colour = List.filled(n, 0);
      final stack  = <(int, bool)>[(start, false)]; // (node, returning)
      while (stack.isNotEmpty) {
        final (node, returning) = stack.removeLast();
        if (returning) {
          colour[node] = 2; // black — fully explored
          continue;
        }
        if (colour[node] == 2) continue; // already done
        if (colour[node] == 1) return true; // back-edge → cycle
        colour[node] = 1; // grey — in stack
        stack.add((node, true)); // schedule blackening
        for (final nb in adj[node]) {
          if (colour[nb] != 2) stack.add((nb, false));
        }
      }
      return false;
    }

    // Backtracking search.
    bool backtrack(int idx) {
      if (idx == n) return true; // all cells assigned

      // Try directions in random order.
      final dirs = ArrowDirection.values.toList()..shuffle(_rng);

      for (final dir in dirs) {
        final targets = rayTargets(idx, dir);

        // Tentatively add edges idx → each target.
        for (final t in targets) adj[idx].add(t);

        // Check for cycle starting from idx (only need to check from idx
        // because new edges all originate there).
        if (!hasCycle(idx)) {
          assignment[idx] = dir;
          if (backtrack(idx + 1)) return true;
        }

        // Undo.
        for (final t in targets) adj[idx].remove(t);
        assignment[idx] = null;
      }

      return false; // no direction works — trigger backtrack
    }

    final solved = backtrack(0);

    if (!solved) {
      // Extremely unlikely but fall back to a trivially solvable layout.
      return _fallbackArrows(size);
    }

    // Build Arrow list from assignments.
    final arrows = <Arrow>[];
    for (int i = 0; i < n; i++) {
      arrows.add(Arrow(
        id:        i,
        cells:     [cells[i]],
        direction: assignment[i]!,
      ));
    }
    return arrows;
  }

  // Fallback: top row fires up (always unblocked), rest fire down.
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

  // Direction deltas (used by tapArrow)
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

    // Walk exit ray from this cell
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
      _score       += 10;

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
