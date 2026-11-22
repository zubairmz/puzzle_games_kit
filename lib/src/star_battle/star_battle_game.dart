import 'package:flutter/material.dart';

import '../core/puzzle_rules.dart';
import '../theme/puzzle_theme.dart';
import '../widgets/puzzle_rules_bar.dart';
import '../widgets/puzzle_status_bar.dart';
import 'star_battle_board.dart';
import 'star_battle_controller.dart';
import 'star_battle_rules.dart';

/// A complete Star Battle screen body: status bar, board, a rules
/// reminder with a "How to play" button, and actions (undo, clear, hint).
///
/// For a custom layout, use [StarBattleBoard] and [PuzzleStatusBar]
/// directly with the same controller.
///
/// ```dart
/// final controller = StarBattleController(
///   puzzle: const StarBattleGenerator().generate(),
///   onFinished: (result) => saveResult(result.toJson()),
/// );
///
/// StarBattleGame(controller: controller);
/// ```
class StarBattleGame extends StatelessWidget {
  /// Creates a Star Battle game for [controller].
  const StarBattleGame({
    super.key,
    required this.controller,
    this.theme,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 16,
    this.showStatusBar = true,
    this.showActions = true,
    this.statusBar,
    this.board,
    this.rules,
    this.showRulesSummary = true,
    this.showRulesButton = true,
    this.rulesBar,
  });

  /// The game to show.
  final StarBattleController controller;

  /// Overrides the inherited [PuzzleTheme] for all parts.
  final PuzzleTheme? theme;

  /// Space around the game.
  final EdgeInsetsGeometry padding;

  /// Space between the parts.
  final double spacing;

  /// Whether to show the status bar.
  final bool showStatusBar;

  /// Whether to show the undo / clear / hint buttons.
  final bool showActions;

  /// Replaces the default status bar.
  final Widget? statusBar;

  /// Replaces the default board.
  final Widget? board;

  /// Text for the rules summary, the "How to play" button and the rules
  /// sheet. Defaults to [starBattleRules]; change parts with [PuzzleRules.copyWith].
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
                  showMistakes: controller.countMistakes,
                  showHints: controller.maxHints != null,
                ),
            SizedBox(height: spacing / 2),
          ],
          Flexible(
            child: Center(
              child: board ??
                  StarBattleBoard(
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
                  rules: rules ?? starBattleRules(),
                  showSummary: showRulesSummary,
                  showButton: showRulesButton,
                ),
          ],
          if (showActions) ...[
            SizedBox(height: spacing),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: controller.canUndo ? controller.undo : null,
                    icon: const Icon(Icons.undo_rounded),
                    label: const Text('Undo'),
                  ),
                  TextButton.icon(
                    onPressed:
                        controller.acceptsInput ? controller.clearMarks : null,
                    icon: const Icon(Icons.layers_clear_outlined),
                    label: const Text('Clear'),
                  ),
                  if (controller.maxHints != 0)
                    TextButton.icon(
                      onPressed: controller.canHint ? controller.hint : null,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: Text(controller.hintsRemaining == null
                          ? 'Hint'
                          : 'Hint (${controller.hintsRemaining})'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
