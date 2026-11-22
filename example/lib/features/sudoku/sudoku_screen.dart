import 'package:flutter/material.dart';
import 'package:puzzle_games/sudoku.dart';

import '../../core/settings/app_settings_scope.dart';
import '../play/play_page.dart';

/// A Sudoku of [size], ending after three mistakes.
class SudokuScreen extends StatelessWidget {
  /// Creates a Sudoku screen.
  const SudokuScreen({
    super.key,
    required this.size,
    required this.difficulty,
    this.seed,
  });

  /// Grid size.
  final SudokuSize size;

  /// Puzzle difficulty.
  final PuzzleDifficulty difficulty;

  /// Seed of the first puzzle, or `null` for a random one.
  final int? seed;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final rules = sudokuRules(boxRows: size.boxRows, boxCols: size.boxCols);
    return PlayPage<SudokuController>(
      seed: seed,
      title: (c) => 'Sudoku ${c.size}×${c.size}',
      rules: settings.showRulesButton ? null : rules,
      createController: (seed, onFinished) => SudokuController(
        puzzle: const SudokuGenerator().generate(
          size: size,
          difficulty: difficulty,
          seed: seed,
        ),
        maxMistakes: 3,
        onFinished: onFinished,
      ),
      gameBuilder: (context, controller) => SudokuGame(
        controller: controller,
        rules: rules,
        showRulesSummary: settings.showRulesSummary,
        showRulesButton: settings.showRulesButton,
      ),
    );
  }
}
