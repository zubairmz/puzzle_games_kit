import 'package:flutter/material.dart';
import 'package:puzzle_games_kit/star_battle.dart';

import '../../core/settings/app_settings_scope.dart';
import '../play/play_page.dart';

/// A Star Battle whose grid size follows the difficulty.
class StarBattleScreen extends StatelessWidget {
  /// Creates a Star Battle screen.
  const StarBattleScreen({super.key, required this.difficulty, this.seed});

  /// Puzzle difficulty.
  final PuzzleDifficulty difficulty;

  /// Seed of the first puzzle, or `null` for a random one.
  final int? seed;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final rules = starBattleRules();
    return PlayPage<StarBattleController>(
      seed: seed,
      title: (c) => 'Star Battle ${c.size}×${c.size}',
      rules: settings.showRulesButton ? null : rules,
      createController: (seed, onFinished) => StarBattleController(
        puzzle: const StarBattleGenerator().generate(
          difficulty: difficulty,
          seed: seed,
        ),
        onFinished: onFinished,
      ),
      gameBuilder: (context, controller) => StarBattleGame(
        controller: controller,
        rules: rules,
        showRulesSummary: settings.showRulesSummary,
        showRulesButton: settings.showRulesButton,
      ),
    );
  }
}
