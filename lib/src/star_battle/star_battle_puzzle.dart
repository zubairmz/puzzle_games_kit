import 'package:flutter/foundation.dart';

import '../core/cell_position.dart';
import '../core/puzzle_difficulty.dart';
import 'star_battle_solver.dart';

/// A Star Battle puzzle: a square grid split into
/// as many coloured regions as it has rows. Place one star in every row,
/// every column and every region so that no two stars touch, not even
/// diagonally.
///
/// Puzzles are immutable; play state lives in `StarBattleController`.
@immutable
class StarBattlePuzzle {
  /// Creates a puzzle from its regions and solution.
  ///
  /// [regions] holds a region id (0 to [size] − 1) per cell, row by row.
  /// [solution] holds the star's column for each row. Throws an
  /// [ArgumentError] if the solution breaks the rules.
  StarBattlePuzzle({
    required this.size,
    required List<int> regions,
    required List<int> solution,
    this.seed,
    this.difficulty,
  })  : regions = List.unmodifiable(regions),
        solution = List.unmodifiable(solution) {
    if (size < 4) {
      throw ArgumentError('Star Battle needs a grid of at least 4x4.');
    }
    if (regions.length != size * size || solution.length != size) {
      throw ArgumentError('Regions or solution do not match size $size.');
    }
    final columns = <int>{};
    final regionIds = <int>{};
    for (var row = 0; row < size; row++) {
      final col = solution[row];
      if (col < 0 || col >= size) {
        throw ArgumentError('Solution column $col is out of range.');
      }
      columns.add(col);
      regionIds.add(regions[row * size + col]);
      if (row > 0 && (col - solution[row - 1]).abs() <= 1) {
        throw ArgumentError('Solution stars touch in rows ${row - 1}/$row.');
      }
    }
    if (columns.length != size || regionIds.length != size) {
      throw ArgumentError('Solution must use every column and region once.');
    }
  }

  /// Creates a puzzle from regions only, solving it for the solution.
  ///
  /// Throws an [ArgumentError] if there is no solution, or more than one
  /// when [requireUnique] is `true`.
  factory StarBattlePuzzle.fromRegions({
    required int size,
    required List<int> regions,
    bool requireUnique = true,
    int? seed,
    PuzzleDifficulty? difficulty,
  }) {
    if (requireUnique && StarBattleSolver.countSolutions(size, regions) != 1) {
      throw ArgumentError('These regions do not have exactly one solution.');
    }
    final solution = StarBattleSolver.solve(size, regions);
    if (solution == null) {
      throw ArgumentError('These regions have no solution.');
    }
    return StarBattlePuzzle(
      size: size,
      regions: regions,
      solution: solution,
      seed: seed,
      difficulty: difficulty,
    );
  }

  /// Parses regions written as rows of letters (`A` = region 0, `B` = 1, …),
  /// one row per line, e.g. `'AABB\nACCB\n...'`. Spaces are ignored.
  factory StarBattlePuzzle.parse(String layout, {bool requireUnique = true}) {
    final rows = layout
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s'), ''))
        .where((line) => line.isNotEmpty)
        .toList();
    final size = rows.length;
    final regions = <int>[];
    for (final row in rows) {
      if (row.length != size) {
        throw FormatException('Every row needs $size letters.', layout);
      }
      for (final unit in row.toUpperCase().codeUnits) {
        regions.add(unit - 'A'.codeUnitAt(0));
      }
    }
    return StarBattlePuzzle.fromRegions(
      size: size,
      regions: regions,
      requireUnique: requireUnique,
    );
  }

  /// Restores a puzzle from [toJson].
  factory StarBattlePuzzle.fromJson(Map<String, Object?> json) {
    final difficulty = json['difficulty'] as String?;
    return StarBattlePuzzle(
      size: json['size']! as int,
      regions: List<int>.from(json['regions']! as List),
      solution: List<int>.from(json['solution']! as List),
      seed: json['seed'] as int?,
      difficulty: difficulty == null
          ? null
          : PuzzleDifficulty.values.byName(difficulty),
    );
  }

  /// Rows, columns, regions and stars.
  final int size;

  /// Region id of every cell, row by row.
  final List<int> regions;

  /// The star's column in each row.
  final List<int> solution;

  /// Seed this puzzle was generated from, if generated.
  final int? seed;

  /// Difficulty this puzzle was generated with, if generated.
  final PuzzleDifficulty? difficulty;

  /// Region id of [row], [col].
  int regionAt(int row, int col) => regions[row * size + col];

  /// Whether the solution has a star at [row], [col].
  bool isSolutionStar(int row, int col) => solution[row] == col;

  /// The solution's star positions.
  List<CellPosition> get solutionStars => [
        for (var row = 0; row < size; row++) CellPosition(row, solution[row]),
      ];

  /// A JSON-friendly map of this puzzle.
  Map<String, Object?> toJson() => {
        'size': size,
        'regions': regions,
        'solution': solution,
        if (seed != null) 'seed': seed,
        if (difficulty != null) 'difficulty': difficulty!.name,
      };

  @override
  bool operator ==(Object other) =>
      other is StarBattlePuzzle &&
      other.size == size &&
      listEquals(other.regions, regions);

  @override
  int get hashCode => Object.hash(size, Object.hashAll(regions));
}
