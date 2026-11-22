import 'dart:math' as math;

import '../core/cell_position.dart';
import '../core/puzzle_difficulty.dart';
import '../core/seeded_random.dart';
import 'grid_rect.dart';
import 'shikaku_puzzle.dart';
import 'shikaku_solver.dart';

/// Generates Shikaku puzzles with exactly one solution.
///
/// It splits the grid into random rectangles, puts each one's area in one of
/// its cells, and moves numbers around until no other split fits. The same
/// seed and settings always produce the same puzzle.
class ShikakuGenerator {
  /// Creates a generator.
  const ShikakuGenerator();

  /// Default grid side for [difficulty].
  static int defaultSize(PuzzleDifficulty difficulty) => switch (difficulty) {
        PuzzleDifficulty.easy => 5,
        PuzzleDifficulty.medium => 6,
        PuzzleDifficulty.hard => 8,
      };

  /// Default largest rectangle area for a grid of [rows] × [cols].
  static int defaultMaxArea(int rows, int cols) =>
      math.max(4, (rows * cols / 5).round()).clamp(4, 12);

  /// Generates a puzzle.
  ///
  /// [rows] and [cols] (3 to 10) override the square size from
  /// [defaultSize]. [maxArea] caps rectangle sizes (default
  /// [defaultMaxArea]); smaller values give more, smaller rectangles. Without
  /// a [seed] a random one is used; it is stored in [ShikakuPuzzle.seed].
  ShikakuPuzzle generate({
    PuzzleDifficulty difficulty = PuzzleDifficulty.medium,
    int? rows,
    int? cols,
    int? maxArea,
    int? seed,
  }) {
    final r = rows ?? defaultSize(difficulty);
    final c = cols ?? r;
    RangeError.checkValueInInterval(r, 3, 10, 'rows');
    RangeError.checkValueInInterval(c, 3, 10, 'cols');
    final limit = maxArea ?? defaultMaxArea(r, c);
    RangeError.checkValueInInterval(limit, 2, r * c, 'maxArea');
    final usedSeed = seed ?? SeededRandom.randomSeed();
    final random = SeededRandom(usedSeed);

    for (var attempt = 0; attempt < 1000; attempt++) {
      final rects = _partition(r, c, limit, random);
      // A one-cell rectangle is a free answer; retry unless it keeps
      // happening (possible with a very small maxArea).
      if (attempt < 500 && rects.any((rect) => rect.area == 1)) continue;
      final clues = [
        for (final rect in rects)
          ShikakuClue(random.pick(rect.cells.toList()), rect.area),
      ];
      if (_repairUntilUnique(r, c, clues, rects, random)) {
        return ShikakuPuzzle(
          rows: r,
          cols: c,
          clues: clues,
          solution: rects,
          seed: usedSeed,
          difficulty: difficulty,
        );
      }
    }
    throw StateError('Could not generate a ${r}x$c puzzle from seed '
        '$usedSeed.');
  }

  /// Splits the grid into rectangles of area 2..[maxArea] (1 only where
  /// nothing else fits), filling it in reading order.
  List<GridRect> _partition(
    int rows,
    int cols,
    int maxArea,
    SeededRandom random,
  ) {
    final taken = List<bool>.filled(rows * cols, false);
    final rects = <GridRect>[];
    for (var i = 0; i < taken.length; i++) {
      if (taken[i]) continue;
      final top = i ~/ cols, left = i % cols;

      final options = <GridRect>[];
      var maxWidth = 0;
      while (left + maxWidth < cols && !taken[top * cols + left + maxWidth]) {
        maxWidth++;
      }
      for (var w = 1; w <= maxWidth; w++) {
        for (var h = 1; top + h <= rows && w * h <= maxArea; h++) {
          final rect = GridRect(top: top, left: left, height: h, width: w);
          if (rect.area >= 2 && _isFree(rect, taken, cols)) options.add(rect);
        }
      }
      final rect = options.isEmpty
          ? GridRect(top: top, left: left, height: 1, width: 1)
          : random.pick(options);
      for (final cell in rect.cells) {
        taken[cell.row * cols + cell.col] = true;
      }
      rects.add(rect);
    }
    return rects;
  }

  static bool _isFree(GridRect rect, List<bool> taken, int cols) {
    for (final cell in rect.cells) {
      if (taken[cell.row * cols + cell.col]) return false;
    }
    return true;
  }

  /// Moves clues inside their own rectangles until [rects] is the only
  /// solution. Each round finds another solution and moves one clue to a
  /// cell outside its alternative rectangle, which rules that one out while
  /// keeping the intended solution valid.
  bool _repairUntilUnique(
    int rows,
    int cols,
    List<ShikakuClue> clues,
    List<GridRect> rects,
    SeededRandom random,
  ) {
    for (var round = 0; round < clues.length * 4; round++) {
      final found = ShikakuSolver.solutions(rows, cols, clues);
      final other = found.where((s) => !_same(s, rects)).firstOrNull;
      if (other == null) return found.isNotEmpty;

      final moves = <(int, CellPosition)>[];
      for (var i = 0; i < clues.length; i++) {
        if (other[i] == rects[i]) continue;
        for (final cell in rects[i].cells) {
          if (!other[i].contains(cell.row, cell.col)) moves.add((i, cell));
        }
      }
      if (moves.isEmpty) return false;
      final (index, cell) = random.pick(moves);
      clues[index] = ShikakuClue(cell, clues[index].value);
    }
    return false;
  }

  static bool _same(List<GridRect> a, List<GridRect> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
