import '../core/seeded_random.dart';

/// Solves Sudoku grids of any box shape.
///
/// Grids are lists of cells in row order with `0` for empty. The search uses
/// bit masks and always branches on the cell with the fewest candidates, so
/// grids up to 9×9 solve in milliseconds.
abstract final class SudokuSolver {
  /// Counts solutions of [grid], stopping once [limit] are found.
  ///
  /// Returns 0 for contradictory clues. `countSolutions(g) == 1` checks that
  /// a puzzle is uniquely solvable.
  static int countSolutions(
    List<int> grid, {
    required int boxRows,
    required int boxCols,
    int limit = 2,
  }) {
    final search = _SudokuSearch(grid, boxRows, boxCols, null);
    if (!search.consistent) return 0;
    search.run(limit);
    return search.solutions;
  }

  /// One solution of [grid], or `null` if it has none.
  ///
  /// With a [random] generator the search explores candidates in a random
  /// order, which is how full grids are generated.
  static List<int>? solve(
    List<int> grid, {
    required int boxRows,
    required int boxCols,
    SeededRandom? random,
  }) {
    final search = _SudokuSearch(grid, boxRows, boxCols, random);
    if (!search.consistent) return null;
    search.run(1);
    return search.firstSolution;
  }
}

class _SudokuSearch {
  _SudokuSearch(List<int> grid, this.boxRows, this.boxCols, this.random)
      : n = boxRows * boxCols,
        cells = List<int>.of(grid) {
    if (cells.length != n * n) {
      throw ArgumentError('Expected ${n * n} cells, got ${cells.length}.');
    }
    full = ((1 << n) - 1) << 1;
    rowMask = List.filled(n, 0);
    colMask = List.filled(n, 0);
    boxMask = List.filled(n, 0);
    for (var i = 0; i < cells.length; i++) {
      final v = cells[i];
      if (v == 0) continue;
      if (v < 0 || v > n) {
        consistent = false;
        return;
      }
      final bit = 1 << v;
      final r = i ~/ n, c = i % n, b = box(r, c);
      if ((rowMask[r] | colMask[c] | boxMask[b]) & bit != 0) {
        consistent = false;
        return;
      }
      rowMask[r] |= bit;
      colMask[c] |= bit;
      boxMask[b] |= bit;
    }
  }

  final int boxRows;
  final int boxCols;
  final int n;
  final List<int> cells;
  final SeededRandom? random;

  late final int full;
  late final List<int> rowMask;
  late final List<int> colMask;
  late final List<int> boxMask;
  bool consistent = true;
  int solutions = 0;
  List<int>? firstSolution;

  int box(int r, int c) => (r ~/ boxRows) * (n ~/ boxCols) + (c ~/ boxCols);

  void run(int limit) => _search(limit);

  void _search(int limit) {
    if (solutions >= limit) return;

    // Pick the empty cell with the fewest candidates.
    var best = -1;
    var bestMask = 0;
    var bestCount = n + 1;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != 0) continue;
      final r = i ~/ n, c = i % n;
      final mask = full & ~(rowMask[r] | colMask[c] | boxMask[box(r, c)]);
      final count = _bitCount(mask);
      if (count < bestCount) {
        best = i;
        bestMask = mask;
        bestCount = count;
        if (count <= 1) break;
      }
    }

    if (best == -1) {
      solutions++;
      firstSolution ??= List<int>.of(cells);
      return;
    }
    if (bestCount == 0) return;

    final values = <int>[
      for (var v = 1; v <= n; v++)
        if (bestMask & (1 << v) != 0) v,
    ];
    random?.shuffle(values);

    final r = best ~/ n, c = best % n, b = box(r, c);
    for (final v in values) {
      final bit = 1 << v;
      cells[best] = v;
      rowMask[r] |= bit;
      colMask[c] |= bit;
      boxMask[b] |= bit;
      _search(limit);
      rowMask[r] &= ~bit;
      colMask[c] &= ~bit;
      boxMask[b] &= ~bit;
      cells[best] = 0;
      if (solutions >= limit) return;
    }
  }

  static int _bitCount(int mask) {
    var count = 0;
    while (mask != 0) {
      mask &= mask - 1;
      count++;
    }
    return count;
  }
}
