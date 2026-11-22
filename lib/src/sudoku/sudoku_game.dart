import 'package:flutter/material.dart';

import '../theme/puzzle_theme.dart';
import '../widgets/puzzle_status_bar.dart';
import 'sudoku_board.dart';
import 'sudoku_controller.dart';
import 'sudoku_input_pad.dart';

/// A complete Sudoku screen body: status bar, board and input pad.
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
          SizedBox(height: spacing),
          inputPad ?? SudokuInputPad(controller: controller, theme: theme),
        ],
      ),
    );
  }
}
