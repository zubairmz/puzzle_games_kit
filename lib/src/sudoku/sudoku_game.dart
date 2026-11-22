import 'package:flutter/material.dart';

import '../core/puzzle_rules.dart';
import '../theme/puzzle_theme.dart';
import '../widgets/puzzle_rules_bar.dart';
import '../widgets/puzzle_status_bar.dart';
import 'sudoku_board.dart';
import 'sudoku_controller.dart';
import 'sudoku_input_pad.dart';
import 'sudoku_rules.dart';

/// A complete Sudoku screen body: status bar, board, a rules reminder with
/// a "How to play" button, and the input pad.
///
/// For a custom layout, use [SudokuBoard], [SudokuInputPad] and
/// [PuzzleStatusBar] directly with the same controller.
///
/// ```dart
/// final controller = SudokuController(
///   puzzle: const SudokuGenerator().generate(size: SudokuSize.six),
///   onFinished: (result) => saveResult(result.toJson()),
/// );
///
/// SudokuGame(controller: controller);
/// ```
class SudokuGame extends StatelessWidget {
  /// Creates a Sudoku game for [controller].
  const SudokuGame({
    super.key,
    required this.controller,
    this.theme,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 16,
    this.showStatusBar = true,
    this.statusBar,
    this.board,
    this.inputPad,
    this.rules,
    this.showRulesSummary = true,
    this.showRulesButton = true,
    this.rulesBar,
  });

  /// The game to show.
  final SudokuController controller;

  /// Overrides the inherited [PuzzleTheme] for all parts.
  final PuzzleTheme? theme;

  /// Space around the game.
  final EdgeInsetsGeometry padding;

  /// Space between status bar, board and pad.
  final double spacing;

  /// Whether to show the status bar.
  final bool showStatusBar;

  /// Replaces the default status bar.
  final Widget? statusBar;

  /// Replaces the default board (for example a [SudokuBoard] with other
  /// options).
  final Widget? board;

  /// Replaces the default input pad.
  final Widget? inputPad;

  /// Text for the rules summary, the "How to play" button and the rules
  /// sheet. Defaults to [sudokuRules]; change parts with [PuzzleRules.copyWith].
  final PuzzleRules? rules;

  /// Whether to show the one or two line rules summary under the board.
  final bool showRulesSummary;

  /// Whether to show the button that opens the full rules sheet.
  final bool showRulesButton;

  /// Replaces the default [PuzzleRulesBar], for example to use your own
  /// button or rules sheet.
  final Widget? rulesBar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: [
          if (showStatusBar) ...[
            statusBar ??
                PuzzleStatusBar(
                  controller: controller,
                  theme: theme,
                  showHints: controller.maxHints != null,
                ),
            SizedBox(height: spacing / 2),
          ],
          Flexible(
            child: Center(
              child: board ??
                  SudokuBoard(
                    controller: controller,
                    theme: theme,
                    autofocus: true,
                  ),
            ),
          ),
          if (rulesBar != null || showRulesSummary || showRulesButton) ...[
            SizedBox(height: spacing / 2),
            rulesBar ??
                PuzzleRulesBar(
                  rules: rules ??
                      sudokuRules(
                        boxRows: controller.puzzle.boxRows,
                        boxCols: controller.puzzle.boxCols,
                      ),
                  showSummary: showRulesSummary,
                  showButton: showRulesButton,
                ),
          ],
          SizedBox(height: spacing),
          inputPad ?? SudokuInputPad(controller: controller, theme: theme),
        ],
      ),
    );
  }
}
