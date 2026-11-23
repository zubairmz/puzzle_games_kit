import 'package:flutter/material.dart';
import 'package:puzzle_games_kit/puzzle_games_kit.dart';

/// App-wide settings: theme, difficulty, daily puzzles and how much of the
/// rules each game shows.
///
/// A plain [ChangeNotifier], the same approach the package's game
/// controllers use, so the example needs no state management package.
class AppSettings extends ChangeNotifier {
  /// Creates settings with the given starting values.
  AppSettings({
    ThemeMode themeMode = ThemeMode.system,
    PuzzleDifficulty difficulty = PuzzleDifficulty.medium,
    bool dailyPuzzle = false,
    bool showRulesSummary = true,
    bool showRulesButton = true,
  })  : _themeMode = themeMode,
        _difficulty = difficulty,
        _dailyPuzzle = dailyPuzzle,
        _showRulesSummary = showRulesSummary,
        _showRulesButton = showRulesButton;

  ThemeMode _themeMode;
  PuzzleDifficulty _difficulty;
  bool _dailyPuzzle;
  bool _showRulesSummary;
  bool _showRulesButton;

  /// Light, dark or follow the system.
  ThemeMode get themeMode => _themeMode;

  /// Difficulty of new puzzles.
  PuzzleDifficulty get difficulty => _difficulty;

  /// Whether everyone gets the same puzzle today.
  bool get dailyPuzzle => _dailyPuzzle;

  /// Whether games show their one or two line rules summary.
  bool get showRulesSummary => _showRulesSummary;

  /// Whether games show their "How to play" button.
  bool get showRulesButton => _showRulesButton;

  /// Whether the app is in dark mode, given the platform [brightness].
  bool isDark(Brightness brightness) => switch (_themeMode) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system => brightness == Brightness.dark,
      };

  /// Switches between light and dark.
  void toggleDarkMode(Brightness platformBrightness) {
    _themeMode = isDark(platformBrightness) ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  set difficulty(PuzzleDifficulty value) =>
      _update(_difficulty != value, () => _difficulty = value);

  set dailyPuzzle(bool value) =>
      _update(_dailyPuzzle != value, () => _dailyPuzzle = value);

  set showRulesSummary(bool value) =>
      _update(_showRulesSummary != value, () => _showRulesSummary = value);

  set showRulesButton(bool value) =>
      _update(_showRulesButton != value, () => _showRulesButton = value);

  /// The seed for a new [gameId] puzzle: today's shared seed when
  /// [dailyPuzzle] is on, otherwise `null` for a random puzzle.
  ///
  /// Add a user id to the salt to give each user their own daily puzzle.
  int? seedFor(String gameId) => _dailyPuzzle
      ? SeededRandom.dailySeed(DateTime.now(), salt: gameId)
      : null;

  void _update(bool changed, VoidCallback apply) {
    if (!changed) return;
    apply();
    notifyListeners();
  }
}
