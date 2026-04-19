import 'dart:math';

enum ArrowDir { up, down, left, right }

extension ArrowDirExt on ArrowDir {
  String get label {
    switch (this) {
      case ArrowDir.up: return '↑';
      case ArrowDir.down: return '↓';
      case ArrowDir.left: return '←';
      case ArrowDir.right: return '→';
    }
  }

  int get dr {
    if (this == ArrowDir.up) return -1;
    if (this == ArrowDir.down) return 1;
    return 0;
  }

  int get dc {
    if (this == ArrowDir.left) return -1;
    if (this == ArrowDir.right) return 1;
    return 0;
  }
}

class ArrowCell {
  final int id;
  int row;
  int col;
  final ArrowDir dir;
  bool freed;       // has been successfully released
  bool sliding;     // currently animating out
  bool blocked;     // currently showing blocked flash

  ArrowCell({
    required this.id,
    required this.row,
    required this.col,
    required this.dir,
    this.freed = false,
    this.sliding = false,
    this.blocked = false,
  });

  ArrowCell copyWith({
    int? row, int? col, ArrowDir? dir,
    bool? freed, bool? sliding, bool? blocked,
  }) => ArrowCell(
    id: id,
    row: row ?? this.row,
    col: col ?? this.col,
    dir: dir ?? this.dir,
    freed: freed ?? this.freed,
    sliding: sliding ?? this.sliding,
    blocked: blocked ?? this.blocked,
  );
}

class PuzzleGrid {
  final int size;
  final List<ArrowCell> arrows;

  PuzzleGrid({required this.size, required this.arrows});

  /// Returns true if cell (r,c) is occupied by a non-freed arrow (excluding [excludeId])
  bool isOccupied(int r, int c, {int excludeId = -1}) {
    return arrows.any((a) =>
        !a.freed && !a.sliding && a.id != excludeId && a.row == r && a.col == c);
  }

  /// Returns whether arrow [a] can be freed (path is clear to edge)
  bool canFree(ArrowCell a) {
    int r = a.row + a.dir.dr;
    int c = a.col + a.dir.dc;
    while (r >= 0 && r < size && c >= 0 && c < size) {
      if (isOccupied(r, c, excludeId: a.id)) return false;
      r += a.dir.dr;
      c += a.dir.dc;
    }
    return true;
  }

  List<ArrowCell> get active => arrows.where((a) => !a.freed).toList();
  bool get isSolved => arrows.every((a) => a.freed);
}

/// Generates a solvable puzzle by reverse simulation:
/// Start empty, repeatedly place an arrow that has a clear exit path,
/// building a stack. The stack reversed is the solution order.
PuzzleGrid generatePuzzle(int size, int arrowCount, {int seed = 0}) {
  final rng = Random(seed);
  final grid = List.generate(size, (_) => List.filled(size, false));
  final placed = <ArrowCell>[];
  int idCounter = 0;

  // All four directions
  const dirs = ArrowDir.values;

  int attempts = 0;
  while (placed.length < arrowCount && attempts < 2000) {
    attempts++;

    // Pick a random empty cell
    final empties = <List<int>>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (!grid[r][c]) empties.add([r, c]);
      }
    }
    if (empties.isEmpty) break;

    final cell = empties[rng.nextInt(empties.length)];
    final r = cell[0], c = cell[1];

    // Try a random direction that has a clear exit (no placed arrow in the way)
    final shuffledDirs = [...dirs]..shuffle(rng);
    ArrowDir? chosen;
    for (final d in shuffledDirs) {
      bool clear = true;
      int nr = r + d.dr, nc = c + d.dc;
      while (nr >= 0 && nr < size && nc >= 0 && nc < size) {
        if (grid[nr][nc]) { clear = false; break; }
        nr += d.dr;
        nc += d.dc;
      }
      if (clear) { chosen = d; break; }
    }
    if (chosen == null) continue;

    grid[r][c] = true;
    placed.add(ArrowCell(id: idCounter++, row: r, col: c, dir: chosen));
  }

  // Shuffle so solution order isn't obvious
  placed.shuffle(rng);

  return PuzzleGrid(size: size, arrows: placed);
}
