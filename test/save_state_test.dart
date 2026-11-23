import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_games_kit/puzzle_games_kit.dart';

/// Round-trips [state] through JSON text, as an app storing it would.
Map<String, Object?> _viaJson(Map<String, Object?> state) =>
    Map<String, Object?>.from(jsonDecode(jsonEncode(state)) as Map);

void main() {
  group('Sudoku saveState / restoreState', () {
    final puzzle = const SudokuGenerator().generate(
      size: SudokuSize.six,
      difficulty: PuzzleDifficulty.medium,
      seed: 42,
    );

    test('restores values, notes, counters and time', () {
      final a = SudokuController(puzzle: puzzle, startClock: false);
      // Fill one empty cell correctly, one wrongly, and a note.
      final empties = [
        for (var i = 0; i < puzzle.cellCount; i++)
          if (puzzle.givens[i] == 0) i,
      ];
      final r0 = empties[0] ~/ puzzle.size, c0 = empties[0] % puzzle.size;
      final r1 = empties[1] ~/ puzzle.size, c1 = empties[1] % puzzle.size;
      final r2 = empties[2] ~/ puzzle.size, c2 = empties[2] % puzzle.size;
      a.setValue(r0, c0, puzzle.solutionAt(r0, c0));
      final wrong = puzzle.solutionAt(r1, c1) % puzzle.size + 1;
      a.setValue(r1, c1, wrong);
      a.toggleNote(r2, c2, 3);
      a.hint();

      final saved = _viaJson(a.saveState());
      final b = SudokuController(
        puzzle: puzzle,
        startClock: false,
        initialElapsed: const Duration(seconds: 99),
      )..restoreState({...saved, 'elapsedMs': 61000});

      for (var r = 0; r < puzzle.size; r++) {
        for (var c = 0; c < puzzle.size; c++) {
          expect(b.valueAt(r, c), a.valueAt(r, c));
          expect(b.notesAt(r, c), a.notesAt(r, c));
        }
      }
      expect(b.moves, a.moves);
      expect(b.mistakes, a.mistakes);
      expect(b.hintsUsed, 1);
      expect(b.elapsed, const Duration(seconds: 61));
      expect(b.canUndo, isFalse);
      a.dispose();
      b.dispose();
    });

    test('rejects a board for another puzzle', () {
      final other =
          const SudokuGenerator().generate(size: SudokuSize.four, seed: 1);
      final a = SudokuController(puzzle: other, startClock: false);
      final b = SudokuController(puzzle: puzzle, startClock: false);
      expect(() => b.restoreState(a.saveState()), throwsArgumentError);
      a.dispose();
      b.dispose();
    });

    test('a saved solved board finishes the game on restore', () {
      final a = SudokuController(puzzle: puzzle, startClock: false);
      final state = a.saveState();
      final board = Map<String, Object?>.from(state['board']! as Map);
      board['values'] = List<int>.of(puzzle.solution);
      final b = SudokuController(puzzle: puzzle, startClock: false)
        ..restoreState({...state, 'board': board});
      expect(b.isSolved, isTrue);
      a.dispose();
      b.dispose();
    });
  });

  group('Star Battle saveState / restoreState', () {
    final puzzle = const StarBattleGenerator().generate(seed: 7);

    test('restores marks', () {
      final a = StarBattleController(puzzle: puzzle, startClock: false)
        ..setMark(0, 0, StarBattleMark.cross)
        ..setMark(1, 2, StarBattleMark.star);
      final b = StarBattleController(puzzle: puzzle, startClock: false)
        ..restoreState(_viaJson(a.saveState()));
      for (var r = 0; r < puzzle.size; r++) {
        for (var c = 0; c < puzzle.size; c++) {
          expect(b.markAt(r, c), a.markAt(r, c));
        }
      }
      expect(b.moves, 2);
      a.dispose();
      b.dispose();
    });

    test('rejects state from another game', () {
      final sudoku = SudokuController(
        puzzle: const SudokuGenerator().generate(size: SudokuSize.four),
        startClock: false,
      );
      final b = StarBattleController(puzzle: puzzle, startClock: false);
      expect(() => b.restoreState(sudoku.saveState()), throwsArgumentError);
      sudoku.dispose();
      b.dispose();
    });
  });

  group('Shikaku saveState / restoreState', () {
    final puzzle = const ShikakuGenerator().generate(seed: 3);

    test('restores rectangles', () {
      final a = ShikakuController(puzzle: puzzle, startClock: false)
        ..addRect(puzzle.solution.first)
        ..addRect(puzzle.solution.last);
      final b = ShikakuController(puzzle: puzzle, startClock: false)
        ..restoreState(_viaJson(a.saveState()));
      expect(b.rects, a.rects);
      expect(b.isFinished, isFalse);
      a.dispose();
      b.dispose();
    });

    test('rejects rectangles outside the grid', () {
      final b = ShikakuController(puzzle: puzzle, startClock: false);
      expect(
        () => b.restoreState({
          'gameId': 'shikaku',
          'board': [
            {'top': 0, 'left': 0, 'height': puzzle.rows + 1, 'width': 1},
          ],
        }),
        throwsArgumentError,
      );
      b.dispose();
    });
  });

  test('restart clears time carried in from initialElapsed', () {
    final c = ShikakuController(
      puzzle: const ShikakuGenerator().generate(seed: 3),
      startClock: false,
      initialElapsed: const Duration(minutes: 5),
    )..restart();
    expect(c.elapsed < const Duration(seconds: 1), isTrue);
    c.dispose();
  });
}
