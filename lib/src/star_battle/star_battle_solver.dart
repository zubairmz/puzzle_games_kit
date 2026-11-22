/// Solves Star Battle grids with one star per row, column and region, where
/// no two stars touch (not even diagonally).
///
/// `regions` lists a region id (0 to size − 1) for every cell, row by row.
abstract final class StarBattleSolver {
  /// Counts solutions, stopping once [limit] are found.
  static int countSolutions(int size, List<int> regions, {int limit = 2}) {
    final search = _StarSearch(size, regions);
    search.run(limit);
    return search.solutions;
  }

  /// One solution as the star's column in each row, or `null` if none.
  static List<int>? solve(int size, List<int> regions) {
    final found = solutions(size, regions, limit: 1);
    return found.isEmpty ? null : found.first;
  }

  /// Up to [limit] solutions, each as the star's column in each row.
  static List<List<int>> solutions(
    int size,
    List<int> regions, {
    int limit = 2,
  }) {
    final search = _StarSearch(size, regions, collect: true);
    search.run(limit);
    return search.found;
  }
}

class _StarSearch {
  _StarSearch(this.n, this.regions, {this.collect = false}) {
    if (regions.length != n * n) {
      throw ArgumentError('Expected ${n * n} region ids, got '
          '${regions.length}.');
    }
    // A region whose last row has been passed without a star is a dead end;
    // precompute, for each row, the regions that end on it.
    final lastRow = List<int>.filled(n, -1);
    for (var i = 0; i < regions.length; i++) {
      final id = regions[i];
      if (id < 0 || id >= n) {
        throw ArgumentError('Region id $id is out of range 0..${n - 1}.');
      }
      lastRow[id] = i ~/ n;
    }
    endingAt = List<int>.filled(n, 0);
    for (var id = 0; id < n; id++) {
      if (lastRow[id] < 0) {
        valid = false; // A region with no cells can never get its star.
        return;
      }
      endingAt[lastRow[id]] |= 1 << id;
    }
  }

  final int n;
  final List<int> regions;
  final bool collect;
  late final List<int> endingAt;
  bool valid = true;
  int solutions = 0;
  final List<List<int>> found = [];
  late final List<int> _cols = List<int>.filled(n, -1);

  void run(int limit) {
    if (valid) _place(0, 0, 0, limit);
  }

  void _place(int row, int usedCols, int usedRegions, int limit) {
    if (row == n) {
      solutions++;
      if (collect) found.add(List<int>.of(_cols));
      return;
    }
    final previous = row > 0 ? _cols[row - 1] : -10;
    for (var col = 0; col < n; col++) {
      if (usedCols & (1 << col) != 0) continue;
      if ((col - previous).abs() <= 1) continue;
      final region = regions[row * n + col];
      if (usedRegions & (1 << region) != 0) continue;
      final regionsAfter = usedRegions | (1 << region);
      // Every region ending on this row must have its star by now.
      if (endingAt[row] & ~regionsAfter != 0) continue;
      _cols[row] = col;
      _place(row + 1, usedCols | (1 << col), regionsAfter, limit);
      if (solutions >= limit) return;
    }
    _cols[row] = -1;
  }
}
