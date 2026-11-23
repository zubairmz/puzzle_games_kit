# puzzle_games_kit

Logic puzzle games for Flutter, ready to drop into any app.

Every game comes with a **puzzle generator** (each puzzle has exactly one
solution), **difficulty levels**, **ready-made widgets** that follow your app's
theme, and a **results callback** with time, mistakes, hints and moves, so you
can build your own stats, streaks and leaderboards.

## Games

| Game | Rules | Library |
|---|---|---|
| **Sudoku** | Fill the grid so every row, column and box holds each number once. 4×4, 6×6 (mini), 8×8 and 9×9. | `package:puzzle_games_kit/sudoku.dart` |
| **Star Battle** | Place one star in every row, column and coloured region. Stars can't touch, not even diagonally. 5×5 to 10×10. | `package:puzzle_games_kit/star_battle.dart` |
| **Shikaku** | Split the grid into rectangles; each holds exactly one number, and that number is its area. 3×3 to 10×10, square or not. | `package:puzzle_games_kit/shikaku.dart` |

More games are on the way.

## Features

- **Generators with unique solutions**, checked by a built-in solver.
- **Seeds**: the same seed always gives the same puzzle, on every platform. Give
  everyone the same daily puzzle, or each user their own.
- **Difficulty levels** (`easy`, `medium`, `hard`), with every parameter
  overridable.
- **Themeable widgets** that follow your `ColorScheme` (light and dark) out of
  the box, customisable through `PuzzleTheme`.
- **Controllers** that hold all game logic: undo, hints, notes, mistake limits,
  pause/resume. Use the included widgets or build your own UI.
- **How to play** built in: a short rules line on every game screen and a
  button that opens the full rules in a bottom sheet. Show or hide each part,
  and change or translate every word.
- **Results** as a `PuzzleResult`, with `toJson()` for saving.
- **Keyboard support** on desktop and web, and screen-reader labels.
- Pure Dart logic, no platform code: works on Android, iOS, web, macOS,
  Windows and Linux.

## Getting started

```yaml
dependencies:
  puzzle_games_kit: ^0.1.0
```

```dart
import 'package:puzzle_games_kit/sudoku.dart'; // or puzzle_games_kit.dart for all games
```

## Usage

### A complete game in a few lines

```dart
class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  late final controller = SudokuController(
    puzzle: const SudokuGenerator().generate(
      size: SudokuSize.six,
      difficulty: PuzzleDifficulty.medium,
    ),
    maxMistakes: 3,
    onFinished: (result) {
      // result.solved, result.elapsed, result.mistakes, result.hintsUsed…
      saveResult(result.toJson());
    },
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: SudokuGame(controller: controller)));
  }
}
```

### Daily puzzles

```dart
// The same puzzle for everyone today:
final seed = SeededRandom.dailySeed(DateTime.now(), salt: 'sudoku');

// A different daily puzzle for each user:
final seed = SeededRandom.dailySeed(DateTime.now(), salt: 'sudoku-$userId');

final puzzle = const SudokuGenerator().generate(seed: seed);
```

The seed is stored on the puzzle (`puzzle.seed`) and in every result, so a game
can always be regenerated later.

### Your own layout

`SudokuGame` is just a convenience. Combine the parts however you like:

```dart
Column(
  children: [
    PuzzleStatusBar(controller: controller, showHints: true),
    Expanded(child: SudokuBoard(controller: controller)),
    SudokuInputPad(controller: controller, showHint: false),
  ],
);
```

Or skip the widgets entirely and drive your own UI from the controller:
`select`, `input`, `setValue`, `toggleNote`, `erase`, `undo`, `hint`,
`pause`, `resume`, `restart`, `giveUp`.

### Game options

```dart
SudokuController(
  puzzle: puzzle,
  maxMistakes: 3,          // end the game after 3 mistakes (null = unlimited)
  maxHints: 2,             // null = unlimited, 0 = no hints
  countMistakes: true,     // count wrong entries
  revealMistakes: true,    // show wrong entries in red
  highlightConflicts: true,// flag repeats in a row, column or box
  autoRemoveNotes: true,   // entering a number clears it from related notes
  allowNotes: true,
  clearOnSameValue: false, // entering the same number again clears the cell
);
```

### Star Battle

```dart
final controller = StarBattleController(
  puzzle: const StarBattleGenerator().generate(
    difficulty: PuzzleDifficulty.medium, // 6×6, 7×7 or 8×8 — or pass size:
  ),
  onFinished: (result) => saveResult(result.toJson()),
);

StarBattleGame(controller: controller);
```

Tap a cell to step through empty → cross → star. Drag from an empty cell to
cross out several cells at once. Cells ruled out by a star get a faint cross
automatically.

```dart
StarBattleController(
  puzzle: puzzle,
  tapCycle: const [StarBattleMark.empty, StarBattleMark.star], // no crosses
  countMistakes: false,     // count stars placed off the solution
  revealMistakes: false,    // flag those stars in red
  highlightConflicts: true, // flag stars that break a rule
  maxHints: 3,
);

StarBattleBoard(
  controller: controller,
  showAutoCrosses: true,
  enableDragToCross: true,
  // Any marker you like, e.g. a crown:
  markerBuilder: (context, cell, theme, size) => switch (cell.mark) {
    StarBattleMark.star => Icon(Icons.emoji_events, size: size * 0.7),
    StarBattleMark.cross => Icon(Icons.close, size: size * 0.4),
    StarBattleMark.empty => const SizedBox.shrink(),
  },
);
```

Region colours come from `PuzzleTheme.regionColors`.

### Shikaku

```dart
final controller = ShikakuController(
  puzzle: const ShikakuGenerator().generate(
    difficulty: PuzzleDifficulty.medium, // 5×5, 6×6 or 8×8
    // or: rows: 6, cols: 8, maxArea: 6,
  ),
  onFinished: (result) => saveResult(result.toJson()),
);

ShikakuGame(controller: controller);
```

Drag from one corner to the other to draw a rectangle (it shows its size
while you drag and replaces anything it overlaps). Tap a rectangle to remove
it. Rectangles that break the rules get a red outline.

```dart
ShikakuBoard(
  controller: controller,
  highlightInvalid: true,
  showPreviewSize: true,
  tapToRemove: true,
  rectBuilder: (context, data, theme) => DecoratedBox(
    decoration: BoxDecoration(
      color: data.isValid ? theme.regionColor(data.clueIndex!) : Colors.grey,
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);
```

### How to play

Every game shows a one or two line rules summary under the board and a
**How to play** button that opens the full rules (goal, controls, mistakes
and hints, tips, keyboard) in a bottom sheet.

```dart
StarBattleGame(
  controller: controller,
  showRulesSummary: true, // the short line under the board
  showRulesButton: true,  // the "How to play" button
);
```

All text lives in a `PuzzleRules` object. Start from a game's defaults
(`sudokuRules()`, `starBattleRules()`, `shikakuRules()`) and change what you
need, or build your own, for example to translate it:

```dart
StarBattleGame(
  controller: controller,
  rules: starBattleRules().copyWith(
    summary: 'One crown in every row, column and colour.',
    buttonLabel: 'Rules',
    closeLabel: 'Let’s play',
    sections: const [
      PuzzleRulesSection(
        title: 'Goal',
        body: 'Place one crown in every row, column and colour.',
        points: ['Crowns can’t touch, not even diagonally.'],
      ),
    ],
  ),
);
```

The pieces work on their own too:

```dart
// Summary and button anywhere in your layout:
PuzzleRulesBar(rules: shikakuRules());

// Just the button, e.g. as an app bar icon:
PuzzleRulesButton(rules: sudokuRules(), iconOnly: true);

// Open the sheet yourself, or show your own content in it:
showPuzzleRulesSheet(context, rules: shikakuRules());
showPuzzleRulesSheet(
  context,
  rules: shikakuRules(),
  builder: (context, rules) => MyRulesView(rules: rules),
);

// Or put the rules on a full screen:
Scaffold(body: SafeArea(child: PuzzleRulesSheet(rules: starBattleRules())));
```

To replace the bar under the board completely, pass `rulesBar:` to any game
widget.

### Theming

Widgets follow your app's `ColorScheme` automatically. To customise, register a
`PuzzleTheme` once:

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: scheme,
    extensions: [
      PuzzleTheme.fromColorScheme(scheme).copyWith(
        selectedCellColor: Colors.amber.shade100,
        blockLineWidth: 3,
        boardRadius: BorderRadius.circular(20),
        textStyle: const TextStyle(fontFamily: 'Nunito'),
      ),
    ],
  ),
);
```

or pass `theme:` to any single widget. For full control of how cells look,
give `SudokuBoard` a `cellBuilder`, `StarBattleBoard` a `markerBuilder` or
`ShikakuBoard` a `rectBuilder`.

### Results

`onFinished` is called once, when the puzzle is solved or the game ends early:

```dart
PuzzleResult(
  gameId: 'sudoku',
  solved: true,
  elapsed: Duration(minutes: 2, seconds: 31),
  difficulty: PuzzleDifficulty.medium,
  seed: 20261122,
  mistakes: 1,
  hintsUsed: 0,
  moves: 22,
  details: {'size': 6, ...},
)
```

The package never stores or sends anything itself; where results go is up to
your app.

### Your own puzzles

```dart
final puzzle = SudokuPuzzle.parse(
  '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79',
);
```

## Example

The [example](example) app shows every game with difficulty selection, daily
puzzles, dark mode, rules settings and a results dialog. It is organised by
feature (`app/`, `core/`, `features/`), with one shared play page for every
game.

## License

MIT. See [LICENSE](LICENSE).
