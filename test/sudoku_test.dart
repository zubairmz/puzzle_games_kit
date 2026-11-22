import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_games/sudoku.dart';

bool _isValidSolution(SudokuPuzzle p) {
  final n = p.size;
  for (var i = 0; i < n; i++) {
    final row = <int>{}, col = <int>{}, box = <int>{};
    for (var j = 0; j < n; j++) {
      row.add(p.solutionAt(i, j));
      col.add(p.solutionAt(j, i));
    }
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (p.boxIndex(r, c) == i) box.add(p.solutionAt(r, c));
      }
    }
    if (row.length != n || col.length != n || box.length != n) return false;
  }
  return true;
}

void _fillAllCorrectly(SudokuController c) {
  final p = c.puzzle;
  for (var r = 0; r < p.size; r++) {
    for (var col = 0; col < p.size; col++) {
      if (!p.isGiven(r, col)) c.setValue(r, col, p.solutionAt(r, col));
    }
  }
}

void main() {
  const generator = SudokuGenerator();

  group('SudokuGenerator', () {
    for (final size in SudokuSize.values) {
      for (final difficulty in PuzzleDifficulty.values) {
        test('${size.name} ${difficulty.name} is valid and unique', () {
          final puzzle = generator.generate(
            size: size,
            difficulty: difficulty,
            seed: 1000 + size.index * 10 + difficulty.index,
          );
          expect(puzzle.size, size.length);
          expect(_isValidSolution(puzzle), isTrue);
          expect(
            SudokuSolver.countSolutions(
              puzzle.givens,
              boxRows: puzzle.boxRows,
              boxCols: puzzle.boxCols,
            ),
            1,
          );
          expect(
            puzzle.givenCount,
            greaterThanOrEqualTo(
                SudokuGenerator.defaultGivens(size, difficulty)),
          );
        });
      }
    }

    test('same seed gives the same puzzle', () {
      final a = generator.generate(seed: 99);
      final b = generator.generate(seed: 99);
      final c = generator.generate(seed: 100);
      expect(a, b);
      expect(a.seed, 99);
      expect(a == c, isFalse);
    });

    test('output is pinned so a seed means the same puzzle everywhere', () {
      // Verified identical on the Dart VM and compiled to JavaScript. If
      // this changes, existing seeds would produce different puzzles.
      final p = generator.generate(size: SudokuSize.six, seed: 2026);
      expect(p.givens.join(), '402050050000610045020006005001000504');
      expect(p.solution.join(), '462153351462613245524316245631136524');
    });

    test('explicit givens override the difficulty', () {
      final p = generator.generate(size: SudokuSize.six, givens: 20, seed: 5);
      expect(p.givenCount, 20);
    });
  });

  group('SudokuSolver', () {
    test('solves a known puzzle', () {
      final puzzle = SudokuPuzzle.parse(
        '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79',
      );
      expect(puzzle.solutionAt(0, 2), 4);
      expect(_isValidSolution(puzzle), isTrue);
    });

    test('rejects contradictory clues', () {
      final grid = List.filled(16, 0)
        ..[0] = 1
        ..[1] = 1;
      expect(SudokuSolver.countSolutions(grid, boxRows: 2, boxCols: 2), 0);
      expect(SudokuSolver.solve(grid, boxRows: 2, boxCols: 2), isNull);
    });

    test('detects multiple solutions', () {
      expect(
        SudokuSolver.countSolutions(List.filled(16, 0), boxRows: 2, boxCols: 2),
        2,
      );
    });
  });

  group('SudokuPuzzle', () {
    test('round-trips through JSON', () {
      final p = generator.generate(seed: 3, difficulty: PuzzleDifficulty.hard);
      final restored = SudokuPuzzle.fromJson(p.toJson());
      expect(restored, p);
      expect(restored.seed, 3);
      expect(restored.difficulty, PuzzleDifficulty.hard);
    });

    test('fromGivens rejects puzzles without a unique solution', () {
      expect(
        () => SudokuPuzzle.fromGivens(
            boxRows: 2, boxCols: 2, givens: List.filled(16, 0)),
        throwsArgumentError,
      );
    });

    test('constructor rejects clues that contradict the solution', () {
      final p = generator.generate(size: SudokuSize.four, seed: 1);
      final givens = List<int>.of(p.solution);
      givens[0] = givens[0] % 4 + 1;
      expect(
        () => SudokuPuzzle(
            boxRows: 2, boxCols: 2, givens: givens, solution: p.solution),
        throwsArgumentError,
      );
    });
  });

  group('SudokuController', () {
    late SudokuPuzzle puzzle;
    late CellPosition empty;
    late int wrongValue;

    setUp(() {
      puzzle = generator.generate(size: SudokuSize.six, seed: 11);
      final i = puzzle.givens.indexOf(0);
      empty = CellPosition(i ~/ 6, i % 6);
      wrongValue = puzzle.solutionAt(empty.row, empty.col) % 6 + 1;
    });

    test('solving finishes with a solved result', () async {
      PuzzleResult? reported;
      final c =
          SudokuController(puzzle: puzzle, onFinished: (r) => reported = r);
      _fillAllCorrectly(c);
      expect(c.isSolved, isTrue);
      expect(c.isFinished, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(reported?.solved, isTrue);
      expect(reported?.gameId, 'sudoku');
      expect(reported?.seed, 11);
      expect(reported?.mistakes, 0);
      c.dispose();
    });

    test('wrong entries count as mistakes and are flagged', () {
      final c = SudokuController(puzzle: puzzle);
      c.setValue(empty.row, empty.col, wrongValue);
      expect(c.mistakes, 1);
      expect(c.isWrong(empty.row, empty.col), isTrue);
      c.dispose();
    });

    test('revealMistakes and countMistakes can be turned off', () {
      final c = SudokuController(
        puzzle: puzzle,
        revealMistakes: false,
        countMistakes: false,
      );
      c.setValue(empty.row, empty.col, wrongValue);
      expect(c.mistakes, 0);
      expect(c.isWrong(empty.row, empty.col), isFalse);
      c.dispose();
    });

    test('reaching maxMistakes ends the game unsolved', () async {
      PuzzleResult? reported;
      final c = SudokuController(
        puzzle: puzzle,
        maxMistakes: 1,
        onFinished: (r) => reported = r,
      );
      c.setValue(empty.row, empty.col, wrongValue);
      expect(c.isFinished, isTrue);
      expect(c.isSolved, isFalse);
      c.setValue(empty.row, empty.col, 1);
      expect(c.valueAt(empty.row, empty.col), wrongValue,
          reason: 'input is ignored after the game ends');
      await Future<void>.delayed(Duration.zero);
      expect(reported?.solved, isFalse);
      c.dispose();
    });

    test('clues cannot be changed', () {
      final c = SudokuController(puzzle: puzzle);
      final i = puzzle.givens.indexWhere((v) => v != 0);
      final given = puzzle.givens[i];
      c.setValue(i ~/ 6, i % 6, given % 6 + 1);
      expect(c.valueAt(i ~/ 6, i % 6), given);
      c.dispose();
    });

    test('undo restores the previous board', () {
      final c = SudokuController(puzzle: puzzle);
      expect(c.canUndo, isFalse);
      c.setValue(empty.row, empty.col, wrongValue);
      expect(c.canUndo, isTrue);
      c.undo();
      expect(c.valueAt(empty.row, empty.col), 0);
      expect(c.mistakes, 1, reason: 'counters are not reverted');
      c.dispose();
    });

    test('notes toggle and are cleared by peer entries', () {
      final c = SudokuController(puzzle: puzzle);
      final value = puzzle.solutionAt(empty.row, empty.col);
      // Find another empty cell in the same row to hold the note.
      final noteCol = List.generate(6, (c) => c).firstWhere(
        (col) => col != empty.col && !puzzle.isGiven(empty.row, col),
        orElse: () => -1,
      );
      if (noteCol == -1) return; // Row has a single empty cell.
      c.toggleNote(empty.row, noteCol, value);
      expect(c.hasNote(empty.row, noteCol, value), isTrue);
      c.setValue(empty.row, empty.col, value);
      expect(c.hasNote(empty.row, noteCol, value), isFalse);
      c.dispose();
    });

    test('notes mode routes input to notes', () {
      final c = SudokuController(puzzle: puzzle)
        ..select(empty)
        ..toggleNotesMode()
        ..input(2);
      expect(c.valueAt(empty.row, empty.col), 0);
      expect(c.notesAt(empty.row, empty.col), {2});
      c.dispose();
    });

    test('hint fills a correct value and respects maxHints', () {
      final c = SudokuController(puzzle: puzzle, maxHints: 1);
      c.select(empty);
      expect(c.hint(), isTrue);
      expect(c.valueAt(empty.row, empty.col),
          puzzle.solutionAt(empty.row, empty.col));
      expect(c.hintsUsed, 1);
      expect(c.hintsRemaining, 0);
      expect(c.hint(), isFalse);
      c.dispose();
    });

    test('conflicts follow the rules only', () {
      final c = SudokuController(puzzle: puzzle, revealMistakes: false);
      final givenCol = List.generate(6, (c) => c).firstWhere(
          (col) => puzzle.isGiven(empty.row, col),
          orElse: () => -1);
      if (givenCol == -1) return;
      c.setValue(empty.row, empty.col, puzzle.givenAt(empty.row, givenCol));
      expect(c.hasConflict(empty.row, empty.col), isTrue);
      c.dispose();
    });

    test('restart clears the board and counters', () {
      final c = SudokuController(puzzle: puzzle)
        ..setValue(empty.row, empty.col, wrongValue)
        ..restart();
      expect(c.valueAt(empty.row, empty.col), 0);
      expect(c.mistakes, 0);
      expect(c.moves, 0);
      expect(c.canUndo, isFalse);
      c.dispose();
    });

    test('pause stops the clock', () async {
      final c = SudokuController(puzzle: puzzle)..pause();
      expect(c.isPaused, isTrue);
      final before = c.elapsed;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.elapsed, before);
      c.resume();
      expect(c.isPaused, isFalse);
      c.dispose();
    });
  });

  group('Sudoku widgets', () {
    testWidgets('tapping a cell and a number enters it', (tester) async {
      final puzzle = generator.generate(size: SudokuSize.four, seed: 8);
      final controller = SudokuController(puzzle: puzzle);
      addTearDown(controller.dispose);
      final i = puzzle.givens.indexOf(0);
      final row = i ~/ 4, col = i % 4;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SudokuGame(controller: controller)),
      ));

      await tester
          .tap(find.bySemanticsLabel('Row ${row + 1}, column ${col + 1}'));
      await tester.pump();
      expect(controller.selected, CellPosition(row, col));

      await tester.tap(find.bySemanticsLabel('Enter 3'));
      await tester.pump();
      expect(controller.valueAt(row, col), 3);
    });

    testWidgets('keyboard enters digits and moves the selection',
        (tester) async {
      final puzzle = generator.generate(size: SudokuSize.four, seed: 8);
      final controller = SudokuController(puzzle: puzzle);
      addTearDown(controller.dispose);
      final i = puzzle.givens.indexOf(0);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SudokuBoard(controller: controller, autofocus: true),
        ),
      ));
      controller.select(CellPosition(i ~/ 4, i % 4));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      expect(controller.valueAt(i ~/ 4, i % 4), 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      expect(controller.valueAt(i ~/ 4, i % 4), 0);
    });

    testWidgets('uses a theme extension when provided', (tester) async {
      final puzzle = generator.generate(size: SudokuSize.four, seed: 8);
      final controller = SudokuController(puzzle: puzzle);
      addTearDown(controller.dispose);
      final custom = PuzzleTheme.fromColorScheme(
        ColorScheme.fromSeed(seedColor: Colors.teal),
      ).copyWith(cellColor: const Color(0xFF123456));

      late PuzzleTheme resolved;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: [custom]),
        home: Builder(builder: (context) {
          resolved = PuzzleTheme.of(context);
          return Scaffold(body: SudokuBoard(controller: controller));
        }),
      ));
      expect(resolved.cellColor, const Color(0xFF123456));
    });
  });
}
