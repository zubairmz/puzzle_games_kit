import '../core/puzzle_rules.dart';

/// The default "how to play" text for a Sudoku with boxes of
/// [boxRows] × [boxCols] cells (3 × 3 for the classic 9×9 grid).
///
/// The "Keyboard" section is included when [keyboardHelp] is `true`; by
/// default only on web and desktop.
///
/// Change any part with [PuzzleRules.copyWith].
PuzzleRules sudokuRules(
    {int boxRows = 3, int boxCols = 3, bool? keyboardHelp}) {
  final keyboard = keyboardHelp ?? hasKeyboardByDefault;
  final n = boxRows * boxCols;
  return PuzzleRules(
    title: 'Sudoku',
    summary: 'Fill every row, column and box with the numbers 1 to $n, '
        'each exactly once.',
    sections: [
      PuzzleRulesSection(
        title: 'Goal',
        body: 'The grid has $n rows, $n columns and $n boxes of '
            '$boxRows × $boxCols cells, marked by the thicker lines. '
            'Fill every empty cell so that each row, each column and each '
            'box holds every number from 1 to $n exactly once.',
      ),
      const PuzzleRulesSection(
        title: 'How to play',
        points: [
          'Tap a cell to select it, then tap a number on the pad to fill it.',
          'Numbers that are printed in bold are part of the puzzle and '
              'can’t be changed.',
          'Tap Erase to clear the selected cell.',
          'Turn on Notes to pencil in small candidate numbers. Tap a number '
              'again to remove its note.',
          'Undo takes back your last move.',
        ],
      ),
      const PuzzleRulesSection(
        title: 'Mistakes and hints',
        points: [
          'Depending on the game, wrong numbers may be shown in red and '
              'counted as mistakes. Some games end after a set number of '
              'mistakes.',
          'A hint fills in the selected cell, or the next empty one, with '
              'the right number.',
          'Every puzzle has exactly one solution, so it can always be solved '
              'by logic alone, without guessing.',
        ],
      ),
      const PuzzleRulesSection(
        title: 'Tips',
        points: [
          'Start with the rows, columns and boxes that are almost full.',
          'For each number, look at where it can still go in a box. If only '
              'one cell is left, it must go there.',
          'Use notes when a cell has two or three possible numbers.',
        ],
      ),
      if (keyboard)
        const PuzzleRulesSection(
          title: 'Keyboard',
          points: [
            'Arrow keys move, number keys fill, Backspace erases.',
            'N turns notes on or off. Ctrl or Cmd + Z undoes.',
          ],
        ),
    ],
  );
}
