import '../core/puzzle_rules.dart';

/// The default "how to play" text for Star Battle.
///
/// The "Keyboard" section is included when [keyboardHelp] is `true`; by
/// default only on web and desktop.
///
/// Change any part with [PuzzleRules.copyWith].
PuzzleRules starBattleRules({bool? keyboardHelp}) {
  final keyboard = keyboardHelp ?? hasKeyboardByDefault;
  return PuzzleRules(
    title: 'Star Battle',
    summary: 'One star in every row, column and colour. '
        'Stars can’t touch, not even diagonally.',
    sections: [
      const PuzzleRulesSection(
        title: 'Goal',
        body: 'The grid is split into coloured regions, one for each row. '
            'Place exactly one star in every row, every column and every '
            'coloured region.',
      ),
      const PuzzleRulesSection(
        title: 'The one rule about touching',
        body: 'No two stars may touch each other, not even at the corners. '
            'Each star needs all eight cells around it to be empty.',
      ),
      const PuzzleRulesSection(
        title: 'How to play',
        points: [
          'Tap a cell to mark it with a cross, tap again to place a star, '
              'and tap once more to clear it.',
          'Use crosses for cells you know can’t hold a star.',
          'Drag across empty cells to cross out several at once.',
          'Cells that a star rules out get a faint cross automatically.',
          'Undo takes back your last move, and Clear empties the board.',
        ],
      ),
      const PuzzleRulesSection(
        title: 'Mistakes and hints',
        points: [
          'Stars that break a rule are shown in red.',
          'A hint places one correct star for you.',
          'Every puzzle has exactly one solution, so it can always be solved '
              'by logic alone, without guessing.',
        ],
      ),
      const PuzzleRulesSection(
        title: 'Tips',
        points: [
          'Start with the smallest regions: they have the fewest places for '
              'their star.',
          'When a region sits entirely in one row or column, no other region '
              'can have its star in that row or column.',
          'Cross out every cell around a star as soon as you place it.',
        ],
      ),
      if (keyboard)
        const PuzzleRulesSection(
          title: 'Keyboard',
          points: [
            'Arrow keys move, Space or Enter steps through the marks.',
            'S places a star, X a cross, Backspace clears. '
                'Ctrl or Cmd + Z undoes.',
          ],
        ),
    ],
  );
}
