import '../core/cell_position.dart';
import 'grid_rect.dart';
import 'shikaku_puzzle.dart';

/// Solves Shikaku grids: split the grid into rectangles, each holding
/// exactly one clue whose number is the rectangle's area.
///
/// The search places the most constrained clue first and prunes as soon as
/// a cell can no longer be covered, so grids up to 10×10 solve in
/// milliseconds.
abstract final class ShikakuSolver {
  /// Counts solutions, stopping once [limit] are found.
  static int countSolutions(
    int rows,
    int cols,
    List<ShikakuClue> clues, {
    int limit = 2,
  }) =>
      solutions(rows, cols, clues, limit: limit).length;

  /// One solution (a rectangle per clue, in clue order), or `null`.
  static List<GridRect>? solve(int rows, int cols, List<ShikakuClue> clues) {
    final found = solutions(rows, cols, clues, limit: 1);
    return found.isEmpty ? null : found.first;
  }

  /// Up to [limit] solutions, each a rectangle per clue in clue order.
  static List<List<GridRect>> solutions(
    int rows,
    int cols,
    List<ShikakuClue> clues, {
    int limit = 2,
  }) {
    final search = _ShikakuSearch(rows, cols, clues);
    search.run(limit);
    return search.found;
  }

  /// Every rectangle that could belong to [clueIndex]: the right area,
  /// containing the clue, inside the grid, and holding no other clue.
  static List<GridRect> candidatesFor(
    int rows,
    int cols,
    List<ShikakuClue> clues,
    int clueIndex,
  ) {
    final clue = clues[clueIndex];
    final others = <CellPosition>{
      for (var i = 0; i < clues.length; i++)
        if (i != clueIndex) clues[i].position,
    };
    final result = <GridRect>[];
    for (var h = 1; h <= clue.value; h++) {
      if (clue.value % h != 0) continue;
      final w = clue.value ~/ h;
      if (h > rows || w > cols) continue;
      for (var top = clue.position.row - h + 1;
          top <= clue.position.row;
          top++) {
        if (top < 0 || top + h > rows) continue;
        for (var left = clue.position.col - w + 1;
            left <= clue.position.col;
            left++) {
          if (left < 0 || left + w > cols) continue;
          final rect = GridRect(top: top, left: left, height: h, width: w);
          if (others.any((p) => rect.contains(p.row, p.col))) continue;
          result.add(rect);
        }
      }
    }
    return result;
  }
}

class _ShikakuSearch {
  _ShikakuSearch(this.rows, this.cols, this.clues)
      : owner = List<int>.filled(rows * cols, -1),
        placed = List<GridRect?>.filled(clues.length, null) {
    final total = clues.fold<int>(0, (sum, c) => sum + c.value);
    if (total != rows * cols || clues.isEmpty) {
      valid = false;
      return;
    }
    candidates = [
      for (var i = 0; i < clues.length; i++)
        ShikakuSolver.candidatesFor(rows, cols, clues, i),
    ];
  }

  final int rows;
  final int cols;
  final List<ShikakuClue> clues;
  final List<int> owner;
  final List<GridRect?> placed;
  late final List<List<GridRect>> candidates;
  bool valid = true;
  final List<List<GridRect>> found = [];

  void run(int limit) {
    if (valid) _search(limit, 0);
  }

  bool _fits(GridRect rect) {
    for (var r = rect.top; r <= rect.bottom; r++) {
      for (var c = rect.left; c <= rect.right; c++) {
        if (owner[r * cols + c] != -1) return false;
      }
    }
    return true;
  }

  void _mark(GridRect rect, int value) {
    for (var r = rect.top; r <= rect.bottom; r++) {
      for (var c = rect.left; c <= rect.right; c++) {
        owner[r * cols + c] = value;
      }
    }
  }

  void _search(int limit, int placedCount) {
    if (found.length >= limit) return;
    if (placedCount == clues.length) {
      // Areas add up to the grid and nothing overlaps, so it's all covered.
      found.add([for (final r in placed) r!]);
      return;
    }

    // Most constrained clue first.
    var best = -1;
    List<GridRect>? bestOptions;
    for (var i = 0; i < clues.length; i++) {
      if (placed[i] != null) continue;
      final options = [
        for (final rect in candidates[i])
          if (_fits(rect)) rect,
      ];
      if (options.isEmpty) return;
      if (bestOptions == null || options.length < bestOptions.length) {
        best = i;
        bestOptions = options;
        if (options.length == 1) break;
      }
    }

    for (final rect in bestOptions!) {
      placed[best] = rect;
      _mark(rect, best);
      if (_everyEmptyCellReachable()) _search(limit, placedCount + 1);
      _mark(rect, -1);
      placed[best] = null;
      if (found.length >= limit) return;
    }
  }

  /// Prunes branches where some empty cell can't be covered by any
  /// remaining clue's rectangle.
  bool _everyEmptyCellReachable() {
    final reachable = List<bool>.filled(owner.length, false);
    for (var i = 0; i < clues.length; i++) {
      if (placed[i] != null) continue;
      for (final rect in candidates[i]) {
        if (!_fits(rect)) continue;
        for (var r = rect.top; r <= rect.bottom; r++) {
          for (var c = rect.left; c <= rect.right; c++) {
            reachable[r * cols + c] = true;
          }
        }
      }
    }
    for (var i = 0; i < owner.length; i++) {
      if (owner[i] == -1 && !reachable[i]) return false;
    }
    return true;
  }
}
