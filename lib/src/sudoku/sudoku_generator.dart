import '../core/puzzle_difficulty.dart';
import '../core/seeded_random.dart';
import 'sudoku_puzzle.dart';
import 'sudoku_solver.dart';

/// Generates Sudoku puzzles with exactly one solution.
///
/// ```dart
/// final puzzle = const SudokuGenerator().generate(
///   size: SudokuSize.six,
///   difficulty: PuzzleDifficulty.medium,
///   seed: SeededRandom.dailySeed(DateTime.now(), salt: userId),
/// );
/// ```
///
/// The same seed and settings always produce the same puzzle. Generation is
/// fast (milliseconds for 6×6, well under a second for 9×9); to keep the UI
/// perfectly smooth on 9×9 you can run it with Flutter's `compute`.
class SudokuGenerator {
  /// Creates a generator.
  const SudokuGenerator();

  /// How many clues a puzzle of [size] keeps by default for [difficulty].
  ///
  /// The generator never removes a clue that would allow a second solution,
  /// so a puzzle may keep a few more clues than this.
  static int defaultGivens(SudokuSize size, PuzzleDifficulty difficulty) {
    return switch ((size, difficulty)) {
      (SudokuSize.four, PuzzleDifficulty.easy) => 8,
      (SudokuSize.four, PuzzleDifficulty.medium) => 6,
      (SudokuSize.four, PuzzleDifficulty.hard) => 5,
      (SudokuSize.six, PuzzleDifficulty.easy) => 18,
      (SudokuSize.six, PuzzleDifficulty.medium) => 14,
      (SudokuSize.six, PuzzleDifficulty.hard) => 11,
      (SudokuSize.eight, PuzzleDifficulty.easy) => 34,
      (SudokuSize.eight, PuzzleDifficulty.medium) => 27,
      (SudokuSize.eight, PuzzleDifficulty.hard) => 22,
      (SudokuSize.nine, PuzzleDifficulty.easy) => 40,
      (SudokuSize.nine, PuzzleDifficulty.medium) => 32,
      (SudokuSize.nine, PuzzleDifficulty.hard) => 26,
    };
  }

  /// Generates a puzzle.
  ///
  /// [givens] overrides the clue count from [defaultGivens]. Without a
  /// [seed] a random one is used; it is stored in [SudokuPuzzle.seed].
  SudokuPuzzle generate({
    SudokuSize size = SudokuSize.six,
    PuzzleDifficulty difficulty = PuzzleDifficulty.medium,
    int? seed,
    int? givens,
  }) {
    final usedSeed = seed ?? SeededRandom.randomSeed();
    final random = SeededRandom(usedSeed);
    final n = size.length;
    final target = (givens ?? defaultGivens(size, difficulty)).clamp(0, n * n);

    final solution = SudokuSolver.solve(
      List.filled(n * n, 0),
      boxRows: size.boxRows,
      boxCols: size.boxCols,
      random: random,
    )!;

    final grid = List<int>.of(solution);
    var remaining = n * n;
    final order = random.shuffle(List<int>.generate(n * n, (i) => i));
    for (final index in order) {
      if (remaining <= target) break;
      final value = grid[index];
      grid[index] = 0;
      final unique = SudokuSolver.countSolutions(
            grid,
            boxRows: size.boxRows,
            boxCols: size.boxCols,
          ) ==
          1;
      if (unique) {
        remaining--;
      } else {
        grid[index] = value;
      }
    }

    return SudokuPuzzle(
      boxRows: size.boxRows,
      boxCols: size.boxCols,
      givens: grid,
      solution: solution,
      seed: usedSeed,
      difficulty: difficulty,
    );
  }
}
