import 'package:flutter/material.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/app_settings_scope.dart';
import 'data/game_catalog.dart';
import 'models/game_entry.dart';
import 'widgets/difficulty_selector.dart';
import 'widgets/game_tile.dart';
import 'widgets/settings_card.dart';

/// Lists the games with the difficulty and settings above them.
class HomePage extends StatelessWidget {
  /// Creates the home page.
  const HomePage({super.key});

  void _open(BuildContext context, AppSettings settings, GameEntry game) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => game.screenBuilder(
          settings.difficulty,
          settings.seedFor(game.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final brightness = MediaQuery.platformBrightnessOf(context);
    final dark = settings.isDark(brightness);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle games'),
        actions: [
          IconButton(
            tooltip: dark ? 'Light mode' : 'Dark mode',
            icon: Icon(
              dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () => settings.toggleDarkMode(brightness),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Difficulty', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          DifficultySelector(
            value: settings.difficulty,
            onChanged: (value) => settings.difficulty = value,
          ),
          const SizedBox(height: 16),
          SettingsCard(settings: settings),
          const SizedBox(height: 16),
          Text('Games', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final game in GameCatalog.all)
            GameTile(game: game, onTap: () => _open(context, settings, game)),
        ],
      ),
    );
  }
}
