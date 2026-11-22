import 'package:flutter/material.dart';
import 'package:puzzle_games/puzzle_games.dart';

/// Light and dark themes for the example app.
///
/// The game widgets follow the app's [ColorScheme] on their own. The
/// [PuzzleTheme] extension shows where to tweak them.
abstract final class AppTheme {
  static const Color _seed = Colors.indigo;

  /// The light theme.
  static final ThemeData light = _build(Brightness.light);

  /// The dark theme.
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      extensions: [
        PuzzleTheme.fromColorScheme(scheme).copyWith(
          boardRadius: BorderRadius.circular(12),
        ),
      ],
    );
  }
}
