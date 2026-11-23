## 0.2.0

* `saveState()` and `restoreState()` on every controller: save a game in
  progress (board, time played, moves, mistakes, hints) as JSON and carry on
  later, even on another device.
* Custom controllers must implement `encodeBoard()` and `decodeBoard()`.
* `restart()` now also clears time passed in as `initialElapsed`.

## 0.1.1

* README and pub.dev page: animated previews of every game and of the How to
  play sheet.

## 0.1.0

* Sudoku: 4×4, 6×6, 8×8 and 9×9 grids with a unique-solution generator,
  solver, controller (notes, undo, hints, mistake limits, pause/resume) and
  widgets (`SudokuGame`, `SudokuBoard`, `SudokuInputPad`).
* Star Battle: 5×5 to 10×10 grids with a unique-solution generator that
  keeps regions at least three cells, solver, controller (custom tap cycle,
  drag-to-cross strokes, undo, hints, optional mistakes) and widgets
  (`StarBattleGame`, `StarBattleBoard`) with automatic crosses, custom
  markers and keyboard support.
* Shikaku: 3×3 to 10×10 grids, square or not, with a unique-solution
  generator (no one-cell rectangles), solver, controller (undo, hints,
  optional mistakes) and widgets (`ShikakuGame`, `ShikakuBoard`) with
  drag-to-draw, a live size preview, rule highlighting, custom rectangles
  and keyboard support.
* How to play: every game shows a short rules summary and a "How to play"
  button that opens the full rules in a bottom sheet. Each part can be
  hidden, and all text (summary, button, sheet) can be changed through
  `PuzzleRules` (`sudokuRules`, `starBattleRules`, `shikakuRules`,
  `PuzzleRulesBar`, `PuzzleRulesButton`, `PuzzleRulesSheet`,
  `showPuzzleRulesSheet`).
* Shared core: `SeededRandom` (identical on every platform),
  `PuzzleDifficulty`, `PuzzleResult`, `PuzzleTheme`, `PuzzleStatusBar` and
  `PuzzleClockText`.
