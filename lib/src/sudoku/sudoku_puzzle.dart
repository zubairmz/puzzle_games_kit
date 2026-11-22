import 'package:flutter/foundation.dart';

import '../core/puzzle_difficulty.dart';
import 'sudoku_solver.dart';

/// Common Sudoku grid sizes and their box shapes.
enum SudokuSize {
  /// 4×4 grid with 2×2 boxes, a quick warm-up.
  four(2, 2),

  /// 6×6 grid with 2×3 boxes, the popular "mini" Sudoku.
  six(2, 3),

  /// 8×8 grid with 2×4 boxes.
  eight(2, 4),

  /// Classic 9×9 grid with 3×3 boxes.
  nine(3, 3);

  const SudokuSize(this.boxRows, this.boxCols);

  /// Rows in each box.
  final int boxRows;

  /// Columns in each box.
  final int boxCols;

  /// Cells per row, column and box.
  int get length => boxRows * boxCols;
}

/// A Sudoku puzzle: the starting clues and the unique solution.
///
/// Cells are stored row by row; `0` means empty. Values run from 1 to
/// [size]. Puzzles are immutable; play state lives in `SudokuController`.
@immutable
class SudokuPuzzle {
  /// Creates a puzzle from its clues and solution.
  ///
  /// Throws an [ArgumentError] if the shapes don't match or a clue differs
  /// from the solution.
  SudokuPuzzle({
    required this.boxRows,
    required this.boxCols,
    required List<int> givens,
    required List<int> solution,
    this.seed,
    this.difficulty,
  })  : givens = List.unmodifiable(givens),
        solution = List.unmodifiable(solution) {
    final cells = size * size;
    if (boxRows < 1 || boxCols < 1) {
      throw ArgumentError('Box dimensions must be positive.');
    }
    if (givens.length != cells || solution.length != cells) {
      throw ArgumentError(
        'Expected $cells cells for a ${size}x$size grid, got '
        '${givens.length} clues and ${solution.length} solution cells.',
      );
    }
    for (var i = 0; i < cells; i++) {
      final s = solution[i];
      if (s < 1 || s > size) {
        throw ArgumentError('Solution value $s at index $i is out of range.');
      }
      if (givens[i] != 0 && givens[i] != s) {
        throw ArgumentError('Clue at index $i does not match the solution.');
      }
    }
  }

  /// Creates a puzzle from clues only, solving it to find the solution.
  ///
  /// Throws an [ArgumentError] if the clues have no solution, or more than
  /// one when [requireUnique] is `true`.
  factory SudokuPuzzle.fromGivens({
    required int boxRows,
    required int boxCols,
    required List<int> givens,
    bool requireUnique = true,
    int? seed,
    PuzzleDifficulty? difficulty,
  }) {
    if (requireUnique &&
        SudokuSolver.countSolutions(givens,
                boxRows: boxRows, boxCols: boxCols) !=
            1) {
      throw ArgumentError('These clues do not have exactly one solution.');
    }
    final solution =
        SudokuSolver.solve(givens, boxRows: boxRows, boxCols: boxCols);
    if (solution == null) {
      throw ArgumentError('These clues have no solution.');
    }
    return SudokuPuzzle(
      boxRows: boxRows,
      boxCols: boxCols,
      givens: givens,
      solution: solution,
      seed: seed,
      difficulty: difficulty,
    );
  }

  /// Parses clues written as a string, one character per cell in row order:
  /// digits for clues, `0`, `.` or `-` for empty cells. Whitespace and `|`
  /// separators are ignored. See [SudokuPuzzle.fromGivens].
  factory SudokuPuzzle.parse(
    String clues, {
    SudokuSize size = SudokuSize.nine,
    bool requireUnique = true,
  }) {
    final givens = <int>[];
    for (final char in clues.split('')) {
      if (char.trim().isEmpty || char == '|') continue;
      if (char == '.' || char == '-') {
        givens.add(0);
      } else {
        final value = int.tryParse(char);
        if (value == null) {
          throw FormatException('Unexpected character "$char".', clues);
        }
        givens.add(value);
      }
    }
    return SudokuPuzzle.fromGivens(
      boxRows: size.boxRows,
      boxCols: size.boxCols,
      givens: givens,
      requireUnique: requireUnique,
    );
  }

  /// Restores a puzzle from [toJson].
  factory SudokuPuzzle.fromJson(Map<String, Object?> json) {
    final difficulty = json['difficulty'] as String?;
    return SudokuPuzzle(
      boxRows: json['boxRows']! as int,
      boxCols: json['boxCols']! as int,
      givens: List<int>.from(json['givens']! as List),
      solution: List<int>.from(json['solution']! as List),
      seed: json['seed'] as int?,
      difficulty: difficulty == null
          ? null
          : PuzzleDifficulty.values.byName(difficulty),
    );
  }

  /// Rows in each box.
  final int boxRows;

  /// Columns in each box.
  final int boxCols;

  /// Starting clues, row by row; `0` for empty cells.
  final List<int> givens;

  /// The solution, row by row.
  final List<int> solution;

  /// Seed this puzzle was generated from, if generated.
  final int? seed;

  /// Difficulty this puzzle was generated with, if generated.
  final PuzzleDifficulty? difficulty;

  /// Cells per row, column and box.
  int get size => boxRows * boxCols;

  /// Total number of cells.
  int get cellCount => size * size;

  /// Number of clues.
  int get givenCount => givens.where((v) => v != 0).length;

  /// The clue at [row], [col], or `0`.
  int givenAt(int row, int col) => givens[row * size + col];

  /// The solution value at [row], [col].
  int solutionAt(int row, int col) => solution[row * size + col];

  /// Whether [row], [col] is a starting clue.
  bool isGiven(int row, int col) => givenAt(row, col) != 0;

  /// Index of the box containing [row], [col], counted row by row.
  int boxIndex(int row, int col) =>
      (row ~/ boxRows) * (size ~/ boxCols) + (col ~/ boxCols);

  /// A JSON-friendly map of this puzzle.
  Map<String, Object?> toJson() => {
        'boxRows': boxRows,
        'boxCols': boxCols,
        'givens': givens,
        'solution': solution,
        if (seed != null) 'seed': seed,
        if (difficulty != null) 'difficulty': difficulty!.name,
      };

  @override
  bool operator ==(Object other) =>
      other is SudokuPuzzle &&
      other.boxRows == boxRows &&
      other.boxCols == boxCols &&
      listEquals(other.givens, givens) &&
      listEquals(other.solution, solution);

  @override
  int get hashCode => Object.hash(boxRows, boxCols, Object.hashAll(givens));
}
