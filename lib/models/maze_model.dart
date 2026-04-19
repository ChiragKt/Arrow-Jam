import 'dart:math';

class MazeCell {
  bool top = true;
  bool right = true;
  bool bottom = true;
  bool left = true;
  bool visited = false;
}

class MazeModel {
  final int cols;
  final int rows;
  late List<List<MazeCell>> grid;
  final Random _rng;

  MazeModel({required this.cols, required this.rows, int? seed})
      : _rng = Random(seed) {
    grid = List.generate(rows, (_) => List.generate(cols, (_) => MazeCell()));
    _carve(0, 0);
  }

  MazeCell cell(int col, int row) => grid[row][col];

  void _carve(int col, int row) {
    grid[row][col].visited = true;
    final dirs = [0, 1, 2, 3]..shuffle(_rng);
    for (final d in dirs) {
      final nc = col + [0, 1, 0, -1][d];
      final nr = row + [-1, 0, 1, 0][d];
      if (nc < 0 || nc >= cols || nr < 0 || nr >= rows) continue;
      if (grid[nr][nc].visited) continue;
      // Remove wall between current and neighbour
      switch (d) {
        case 0: // up
          grid[row][col].top = false;
          grid[nr][nc].bottom = false;
          break;
        case 1: // right
          grid[row][col].right = false;
          grid[nr][nc].left = false;
          break;
        case 2: // down
          grid[row][col].bottom = false;
          grid[nr][nc].top = false;
          break;
        case 3: // left
          grid[row][col].left = false;
          grid[nr][nc].right = false;
          break;
      }
      _carve(nc, nr);
    }
  }

  bool canMove(int col, int row, String direction) {
    final c = grid[row][col];
    switch (direction) {
      case 'up':    return !c.top;
      case 'down':  return !c.bottom;
      case 'left':  return !c.left;
      case 'right': return !c.right;
      default:      return false;
    }
  }
}
