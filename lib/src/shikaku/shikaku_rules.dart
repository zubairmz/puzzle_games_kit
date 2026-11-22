import '../core/puzzle_rules.dart';

/// The default "how to play" text for Shikaku.
///
/// The "Keyboard" section is included when [keyboardHelp] is `true`; by
/// default only on web and desktop.
///
/// Change any part with [PuzzleRules.copyWith].
PuzzleRules shikakuRules({bool? keyboardHelp}) {
  final keyboard = keyboardHelp ?? hasKeyboardByDefault;
  return PuzzleRules(
    title: 'Shikaku',
    summary: 'Split the grid into rectangles. Each holds one number, and the '
        'number is its size.',
    sections: [
      const PuzzleRulesSection(
        title: 'Goal',
        body: 'Divide the whole grid into rectangles (squares count too). '
            'Every rectangle must contain exactly one number, and that number '
            'is how many cells the rectangle covers. When every cell is '
            'covered, the puzzle is solved.',
      ),
      const PuzzleRulesSection(
        title: 'Example',
        body: 'A 6 can be a rectangle of 1 × 6, 2 × 3, 3 × 2 or 6 × 1 cells, '
            'as long as it fits on the grid and holds no other number.',
      ),
      const PuzzleRulesSection(
        title: 'How to play',
        points: [
          'Drag from one corner of a rectangle to the opposite corner to '
              'draw it. Its size is shown while you drag.',
          'A new rectangle replaces any rectangle it overlaps.',
          'Tap a rectangle to remove it.',
          'Undo takes back your last move, and Clear empties the board.',
        ],
      ),
      const PuzzleRulesSection(
        title: 'Mistakes and hints',
        points: [
          'A rectangle with a red outline breaks a rule: it holds no number, '
              'more than one, or the wrong number of cells.',
          'A hint draws one correct rectangle for you.',
          'Every puzzle has exactly one solution, so it can always be solved '
              'by logic alone, without guessing.',
        ],
      ),
      const PuzzleRulesSection(
        title: 'Tips',
        points: [
          'Start with big numbers in tight spots and numbers near the edges: '
              'they have the fewest shapes that fit.',
          'A prime number such as 5 or 7 can only be a single straight line.',
          'Cells that only one number can reach belong to that number.',
        ],
      ),
      if (keyboard)
        const PuzzleRulesSection(
          title: 'Keyboard',
          points: [
            'Arrow keys move. Press Space or Enter on one corner, move to the '
                'opposite corner and press it again to draw.',
            'Backspace removes the rectangle under the cursor, Escape cancels. '
                'Ctrl or Cmd + Z undoes.',
          ],
        ),
    ],
  );
}
