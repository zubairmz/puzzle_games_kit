import 'package:flutter/widgets.dart';
import 'package:puzzle_games_kit/puzzle_games_kit.dart';

/// Builds a game screen for a difficulty and an optional daily seed.
typedef GameScreenBuilder = Widget Function(
  PuzzleDifficulty difficulty,
  int? seed,
);

/// A game listed on the home page.
@immutable
class GameEntry {
  /// Creates a game entry.
  const GameEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.screenBuilder,
  });

  /// Stable id, also used as the daily seed salt.
  final String id;

  /// Name shown on the home page.
  final String title;

  /// One line about the game.
  final String subtitle;

  /// Icon shown on the home page.
  final IconData icon;

  /// Builds the screen that plays this game.
  final GameScreenBuilder screenBuilder;
}
