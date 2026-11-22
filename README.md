# puzzle_games

Logic puzzle games for Flutter, ready to drop into any app.

Every game comes with a **puzzle generator** (each puzzle has exactly one
solution), **difficulty levels**, **ready-made widgets** that follow your app's
theme, and a **results callback** with time, mistakes, hints and moves, so you
can build your own stats, streaks and leaderboards.

## Games

| Game | Rules | Library |
|---|---|---|
| **Sudoku** | Fill the grid so every row, column and box holds each number once. 4×4, 6×6 (mini), 8×8 and 9×9. | `package:puzzle_games/sudoku.dart` |

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
- **Results** as a `PuzzleResult`, with `toJson()` for saving.
- **Keyboard support** on desktop and web, and screen-reader labels.
- Pure Dart logic, no platform code: works on Android, iOS, web, macOS,
  Windows and Linux.

## Getting started

```yaml
dependencies:
  puzzle_games: ^0.1.0
```

```dart
import 'package:puzzle_games/sudoku.dart'; // or puzzle_games.dart for all games
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
give `SudokuBoard` a `cellBuilder`.

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
puzzles, dark mode and a results dialog.

## License

MIT. See [LICENSE](LICENSE).
