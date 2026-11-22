import 'package:flutter/foundation.dart';

import '../core/cell_position.dart';
import '../core/puzzle_difficulty.dart';
import 'grid_rect.dart';
import 'shikaku_solver.dart';

/// A number in a Shikaku grid: the area of the rectangle that covers it.
@immutable
class ShikakuClue {
  /// Creates a clue.
  const ShikakuClue(this.position, this.value) : assert(value > 0);

  /// Restores a clue from [toJson].
  factory ShikakuClue.fromJson(Map<String, Object?> json) => ShikakuClue(
        CellPosition(json['row']! as int, json['col']! as int),
        json['value']! as int,
      );

  /// Where the number is.
  final CellPosition position;

  /// The rectangle's area.
  final int value;

  /// A JSON-friendly map of this clue.
  Map<String, Object?> toJson() =>
      {'row': position.row, 'col': position.col, 'value': value};

  @override
  bool operator ==(Object other) =>
      other is ShikakuClue &&
      other.position == position &&
      other.value == value;

  @override
  int get hashCode => Object.hash(position, value);

  @override
  String toString() => 'ShikakuClue($position, $value)';
}

/// A Shikaku puzzle (also known as "Patches" or "Divide by Squares"): split
/// the grid into rectangles so that each holds exactly one number, and that
/// number equals the rectangle's area.
///
/// Puzzles are immutable; play state lives in `ShikakuController`.
@immutable
class ShikakuPuzzle {
  /// Creates a puzzle from its clues and solution ([solution] holds the
  /// rectangle for each clue, in the same order).
  ///
  /// Throws an [ArgumentError] if the solution doesn't fit the clues.
  ShikakuPuzzle({
    required this.rows,
    required this.cols,
    required List<ShikakuClue> clues,
    required List<GridRect> solution,
    this.seed,
    this.difficulty,
  })  : clues = List.unmodifiable(clues),
        solution = List.unmodifiable(solution) {
    if (rows < 2 || cols < 2) {
      throw ArgumentError('Shikaku needs a grid of at least 2x2.');
    }
    if (clues.length != solution.length || clues.isEmpty) {
      throw ArgumentError('Every clue needs exactly one solution rectangle.');
    }
    final covered = List<bool>.filled(rows * cols, false);
    for (var i = 0; i < clues.length; i++) {
      final rect = solution[i];
      final clue = clues[i];
      if (rect.top < 0 ||
          rect.left < 0 ||
          rect.bottom >= rows ||
          rect.right >= cols ||
          rect.area != clue.value ||
          !rect.contains(clue.position.row, clue.position.col)) {
        throw ArgumentError('Solution rectangle $i does not fit its clue.');
      }
      for (final cell in rect.cells) {
        final index = cell.row * cols + cell.col;
        if (covered[index]) {
          throw ArgumentError('Solution rectangles overlap at $cell.');
        }
        covered[index] = true;
      }
    }
    if (covered.contains(false)) {
      throw ArgumentError('Solution rectangles do not cover the grid.');
    }
  }

  /// Creates a puzzle from clues only, solving it for the solution.
  ///
  /// Throws an [ArgumentError] if there is no solution, or more than one
  /// when [requireUnique] is `true`.
  factory ShikakuPuzzle.fromClues({
    required int rows,
    required int cols,
    required List<ShikakuClue> clues,
    bool requireUnique = true,
    int? seed,
    PuzzleDifficulty? difficulty,
  }) {
    final found = ShikakuSolver.solutions(rows, cols, clues);
    if (found.isEmpty) throw ArgumentError('These clues have no solution.');
    if (requireUnique && found.length != 1) {
      throw ArgumentError('These clues do not have exactly one solution.');
    }
    return ShikakuPuzzle(
      rows: rows,
      cols: cols,
      clues: clues,
      solution: found.first,
      seed: seed,
      difficulty: difficulty,
    );
  }

  /// Parses a grid written one row per line, cells separated by spaces:
  /// a number for a clue, `.` for an empty cell. For example:
  ///
  /// ```text
  /// 4 . . 2
  /// . . . .
  /// . 6 . .
  /// . . 4 .
  /// ```
  factory ShikakuPuzzle.parse(String grid, {bool requireUnique = true}) {
    final lines = grid
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final clues = <ShikakuClue>[];
    int? cols;
    for (var r = 0; r < lines.length; r++) {
      final cells = lines[r].split(RegExp(r'\s+'));
      cols ??= cells.length;
      if (cells.length != cols) {
        throw FormatException('Every row needs $cols cells.', grid);
      }
      for (var c = 0; c < cells.length; c++) {
        if (cells[c] == '.') continue;
        final value = int.tryParse(cells[c]);
        if (value == null || value < 1) {
          throw FormatException('Unexpected cell "${cells[c]}".', grid);
        }
        clues.add(ShikakuClue(CellPosition(r, c), value));
      }
    }
    return ShikakuPuzzle.fromClues(
      rows: lines.length,
      cols: cols ?? 0,
      clues: clues,
      requireUnique: requireUnique,
    );
  }

  /// Restores a puzzle from [toJson].
  factory ShikakuPuzzle.fromJson(Map<String, Object?> json) {
    final difficulty = json['difficulty'] as String?;
    return ShikakuPuzzle(
      rows: json['rows']! as int,
      cols: json['cols']! as int,
      clues: [
        for (final c in json['clues']! as List)
          ShikakuClue.fromJson(Map<String, Object?>.from(c as Map)),
      ],
      solution: [
        for (final r in json['solution']! as List)
          GridRect.fromJson(Map<String, Object?>.from(r as Map)),
      ],
      seed: json['seed'] as int?,
      difficulty: difficulty == null
          ? null
          : PuzzleDifficulty.values.byName(difficulty),
    );
  }

  /// Number of rows.
  final int rows;

  /// Number of columns.
  final int cols;

  /// The numbers in the grid.
  final List<ShikakuClue> clues;

  /// The rectangle for each clue, in clue order.
  final List<GridRect> solution;

  /// Seed this puzzle was generated from, if generated.
  final int? seed;

  /// Difficulty this puzzle was generated with, if generated.
  final PuzzleDifficulty? difficulty;

  /// The index of the clue at [row], [col], or `-1`.
  int clueIndexAt(int row, int col) => clues.indexWhere(
        (c) => c.position.row == row && c.position.col == col,
      );

  /// A JSON-friendly map of this puzzle.
  Map<String, Object?> toJson() => {
        'rows': rows,
        'cols': cols,
        'clues': [for (final c in clues) c.toJson()],
        'solution': [for (final r in solution) r.toJson()],
        if (seed != null) 'seed': seed,
        if (difficulty != null) 'difficulty': difficulty!.name,
      };

  @override
  bool operator ==(Object other) =>
      other is ShikakuPuzzle &&
      other.rows == rows &&
      other.cols == cols &&
      listEquals(other.clues, clues);

  @override
  int get hashCode => Object.hash(rows, cols, Object.hashAll(clues));
}
