import 'package:flutter/foundation.dart';

import 'puzzle_difficulty.dart';

/// The outcome of a finished game, reported through `onFinished`.
///
/// Store it however your app likes (local storage, your backend) to build
/// streaks, personal bests or leaderboards. [toJson] and [PuzzleResult.fromJson]
/// make it easy to persist.
@immutable
class PuzzleResult {
  /// Creates a result.
  const PuzzleResult({
    required this.gameId,
    required this.solved,
    required this.elapsed,
    required this.completedAt,
    this.difficulty,
    this.seed,
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.moves = 0,
    this.details = const {},
  });

  /// Restores a result produced by [toJson].
  factory PuzzleResult.fromJson(Map<String, Object?> json) {
    final difficulty = json['difficulty'] as String?;
    return PuzzleResult(
      gameId: json['gameId']! as String,
      solved: json['solved']! as bool,
      elapsed: Duration(milliseconds: json['elapsedMs']! as int),
      completedAt: DateTime.parse(json['completedAt']! as String),
      difficulty: difficulty == null
          ? null
          : PuzzleDifficulty.values.byName(difficulty),
      seed: json['seed'] as int?,
      mistakes: json['mistakes'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      moves: json['moves'] as int? ?? 0,
      details: Map<String, Object?>.from(
        json['details'] as Map? ?? const <String, Object?>{},
      ),
    );
  }

  /// Which game produced this result, e.g. `sudoku`, `star_battle`,
  /// `shikaku`.
  final String gameId;

  /// `true` if the puzzle was solved; `false` if the game ended early
  /// (for example after reaching the mistake limit).
  final bool solved;

  /// Time spent playing, excluding time while paused.
  final Duration elapsed;

  /// When the game finished.
  final DateTime completedAt;

  /// Difficulty the puzzle was generated with, if known.
  final PuzzleDifficulty? difficulty;

  /// Seed the puzzle was generated from, if known. The same seed and
  /// settings regenerate the same puzzle.
  final int? seed;

  /// Number of wrong moves made.
  final int mistakes;

  /// Number of hints used.
  final int hintsUsed;

  /// Number of moves made (entries, marks, undo excluded).
  final int moves;

  /// Game-specific extras, such as the grid size.
  final Map<String, Object?> details;

  /// A JSON-friendly map of this result.
  Map<String, Object?> toJson() => {
        'gameId': gameId,
        'solved': solved,
        'elapsedMs': elapsed.inMilliseconds,
        'completedAt': completedAt.toIso8601String(),
        if (difficulty != null) 'difficulty': difficulty!.name,
        if (seed != null) 'seed': seed,
        'mistakes': mistakes,
        'hintsUsed': hintsUsed,
        'moves': moves,
        if (details.isNotEmpty) 'details': details,
      };

  @override
  String toString() => 'PuzzleResult(${toJson()})';
}
