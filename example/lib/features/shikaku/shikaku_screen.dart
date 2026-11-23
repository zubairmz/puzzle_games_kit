import 'package:flutter/material.dart';
import 'package:puzzle_games_kit/shikaku.dart';

import '../../core/settings/app_settings_scope.dart';
import '../play/play_page.dart';

/// A Shikaku whose grid size follows the difficulty.
class ShikakuScreen extends StatelessWidget {
  /// Creates a Shikaku screen.
  const ShikakuScreen({super.key, required this.difficulty, this.seed});

  /// Puzzle difficulty.
  final PuzzleDifficulty difficulty;

  /// Seed of the first puzzle, or `null` for a random one.
  final int? seed;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final rules = shikakuRules();
    return PlayPage<ShikakuController>(
      seed: seed,
      title: (c) => 'Shikaku ${c.puzzle.rows}×${c.puzzle.cols}',
      rules: settings.showRulesButton ? null : rules,
      createController: (seed, onFinished) => ShikakuController(
        puzzle: const ShikakuGenerator().generate(
          difficulty: difficulty,
          seed: seed,
        ),
        onFinished: onFinished,
      ),
      gameBuilder: (context, controller) => ShikakuGame(
        controller: controller,
        rules: rules,
        showRulesSummary: settings.showRulesSummary,
        showRulesButton: settings.showRulesButton,
      ),
    );
  }
}
