import 'package:flutter/material.dart';
import 'package:puzzle_games/puzzle_games.dart';

import '../../shikaku/shikaku_screen.dart';
import '../../star_battle/star_battle_screen.dart';
import '../../sudoku/sudoku_screen.dart';
import '../models/game_entry.dart';

/// Every game the example offers, in the order shown on the home page.
///
/// Adding a game is one more entry here.
abstract final class GameCatalog {
  /// All games.
  static final List<GameEntry> all = List.unmodifiable([
    GameEntry(
      id: 'sudoku6',
      title: 'Mini Sudoku',
      subtitle: '6×6, every row, column and box holds 1 to 6',
      icon: Icons.grid_on_rounded,
      screenBuilder: (difficulty, seed) => SudokuScreen(
        size: SudokuSize.six,
        difficulty: difficulty,
        seed: seed,
      ),
    ),
    GameEntry(
      id: 'star_battle',
      title: 'Star Battle',
      subtitle: 'One star per row, column and colour, no touching',
      icon: Icons.star_outline_rounded,
      screenBuilder: (difficulty, seed) =>
          StarBattleScreen(difficulty: difficulty, seed: seed),
    ),
    GameEntry(
      id: 'shikaku',
      title: 'Shikaku',
      subtitle: 'Split the grid into rectangles of the given sizes',
      icon: Icons.dashboard_outlined,
      screenBuilder: (difficulty, seed) =>
          ShikakuScreen(difficulty: difficulty, seed: seed),
    ),
    GameEntry(
      id: 'sudoku9',
      title: 'Classic Sudoku',
      subtitle: '9×9, the original',
      icon: Icons.grid_4x4_rounded,
      screenBuilder: (difficulty, seed) => SudokuScreen(
        size: SudokuSize.nine,
        difficulty: difficulty,
        seed: seed,
      ),
    ),
  ]);
}
