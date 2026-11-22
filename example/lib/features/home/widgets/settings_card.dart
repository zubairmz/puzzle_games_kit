import 'package:flutter/material.dart';

import '../../../core/settings/app_settings.dart';

/// Switches for daily puzzles and the rules shown in each game.
class SettingsCard extends StatelessWidget {
  /// Creates the settings card for [settings].
  const SettingsCard({super.key, required this.settings});

  /// The settings to edit.
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Daily puzzle'),
            subtitle: const Text('Same puzzle for everyone today'),
            value: settings.dailyPuzzle,
            onChanged: (value) => settings.dailyPuzzle = value,
          ),
          SwitchListTile(
            title: const Text('Rules summary'),
            subtitle: const Text('One or two lines under the board'),
            value: settings.showRulesSummary,
            onChanged: (value) => settings.showRulesSummary = value,
          ),
          SwitchListTile(
            title: const Text('“How to play” button'),
            subtitle: const Text('Opens the full rules in a bottom sheet'),
            value: settings.showRulesButton,
            onChanged: (value) => settings.showRulesButton = value,
          ),
        ],
      ),
    );
  }
}
