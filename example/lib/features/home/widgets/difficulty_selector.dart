import 'package:flutter/material.dart';
import 'package:puzzle_games/puzzle_games.dart';

/// Picks easy, medium or hard.
class DifficultySelector extends StatelessWidget {
  /// Creates a difficulty selector.
  const DifficultySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// The selected difficulty.
  final PuzzleDifficulty value;

  /// Called with the new difficulty.
  final ValueChanged<PuzzleDifficulty> onChanged;

  static String _label(PuzzleDifficulty d) => switch (d) {
        PuzzleDifficulty.easy => 'Easy',
        PuzzleDifficulty.medium => 'Medium',
        PuzzleDifficulty.hard => 'Hard',
      };

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PuzzleDifficulty>(
      segments: [
        for (final d in PuzzleDifficulty.values)
          ButtonSegment(value: d, label: Text(_label(d))),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
