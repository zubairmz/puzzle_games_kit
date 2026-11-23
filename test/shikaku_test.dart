import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_games_kit/shikaku.dart';

String _describe(ShikakuPuzzle p) => p.clues
    .map((c) => '${c.position.row}${c.position.col}:${c.value}')
    .join(',');

void main() {
  const generator = ShikakuGenerator();

  group('GridRect', () {
    test('fromCorners works in any order', () {
      final a = GridRect.fromCorners(
          const CellPosition(3, 1), const CellPosition(1, 4));
      expect(a, const GridRect(top: 1, left: 1, height: 3, width: 4));
      expect(a.area, 12);
      expect(a.bottom, 3);
      expect(a.right, 4);
    });

    test('contains and overlaps', () {
      const a = GridRect(top: 0, left: 0, height: 2, width: 2);
      const b = GridRect(top: 1, left: 1, height: 2, width: 2);
      const c = GridRect(top: 2, left: 2, height: 1, width: 1);
      expect(a.contains(1, 1), isTrue);
      expect(a.contains(2, 0), isFalse);
      expect(a.overlaps(b), isTrue);
      expect(a.overlaps(c), isFalse);
      expect(a.cells.length, 4);
    });
  });

  group('ShikakuGenerator', () {
    for (final size in [3, 4, 5, 6, 7, 8, 9, 10]) {
      test('${size}x$size puzzles are unique and well formed', () {
        for (var seed = 0; seed < 15; seed++) {
          final p = generator.generate(rows: size, seed: seed);
          expect(ShikakuSolver.countSolutions(size, size, p.clues), 1);
          expect(ShikakuSolver.solve(size, size, p.clues), p.solution);
          expect(p.clues.every((c) => c.value >= 2), isTrue,
              reason: 'no one-cell rectangles (seed $seed)');
          expect(
            p.clues.every(
                (c) => c.value <= ShikakuGenerator.defaultMaxArea(size, size)),
            isTrue,
          );
        }
      });
    }

    test('rectangular grids and maxArea', () {
      final p = generator.generate(rows: 5, cols: 8, maxArea: 4, seed: 9);
      expect(p.rows, 5);
      expect(p.cols, 8);
      expect(p.clues.every((c) => c.value <= 4), isTrue);
      expect(ShikakuSolver.countSolutions(5, 8, p.clues), 1);
    });

    test('difficulty picks the default size', () {
      for (final d in PuzzleDifficulty.values) {
        final p = generator.generate(difficulty: d, seed: 1);
        expect(p.rows, ShikakuGenerator.defaultSize(d));
        expect(p.cols, ShikakuGenerator.defaultSize(d));
      }
    });

    test('same seed gives the same puzzle', () {
      expect(generator.generate(seed: 5), generator.generate(seed: 5));
      expect(
          generator.generate(seed: 5) == generator.generate(seed: 6), isFalse);
    });

    test('output is pinned so a seed means the same puzzle everywhere', () {
      // Verified identical on the Dart VM and compiled to JavaScript. If
      // this changes, existing seeds would produce different puzzles.
      expect(
        _describe(generator.generate(rows: 6, seed: 2026)),
        '20:6,01:4,05:3,33:3,34:3,55:5,31:2,32:2,41:2,43:6',
      );
    });

    test('rejects sizes outside 3..10', () {
      expect(() => generator.generate(rows: 2), throwsRangeError);
      expect(() => generator.generate(rows: 11), throwsRangeError);
    });
  });

  group('ShikakuSolver', () {
    test('a grid whose clues do not add up has no solution', () {
      expect(
        ShikakuSolver.countSolutions(
            2, 2, const [ShikakuClue(CellPosition(0, 0), 3)]),
        0,
      );
    });

    test('detects multiple solutions', () {
      // A 2x2 grid with two 2s on a diagonal splits either way.
      expect(
        ShikakuSolver.countSolutions(2, 2, const [
          ShikakuClue(CellPosition(0, 0), 2),
          ShikakuClue(CellPosition(1, 1), 2),
        ]),
        2,
      );
    });
  });

  group('ShikakuPuzzle', () {
    test('parse reads a text grid', () {
      final p = ShikakuPuzzle.parse('''
        2 . 3
        . . .
        . 4 .
      ''', requireUnique: false);
      expect(p.rows, 3);
      expect(p.cols, 3);
      expect(p.clues.length, 3);
      expect(p.clueIndexAt(2, 1), 2);
    });

    test('round-trips through JSON', () {
      final p = generator.generate(seed: 12, difficulty: PuzzleDifficulty.hard);
      final restored = ShikakuPuzzle.fromJson(p.toJson());
      expect(restored, p);
      expect(restored.solution, p.solution);
      expect(restored.seed, 12);
    });

    test('rejects a solution that does not cover the grid', () {
      expect(
        () => ShikakuPuzzle(
          rows: 2,
          cols: 2,
          clues: const [ShikakuClue(CellPosition(0, 0), 2)],
          solution: const [GridRect(top: 0, left: 0, height: 1, width: 2)],
        ),
        throwsArgumentError,
      );
    });
  });

  group('ShikakuController', () {
    late ShikakuPuzzle puzzle;
    setUp(() => puzzle = generator.generate(rows: 5, seed: 31));

    test('drawing the solution finishes the game', () async {
      PuzzleResult? reported;
      final c =
          ShikakuController(puzzle: puzzle, onFinished: (r) => reported = r);
      for (final rect in puzzle.solution) {
        c.addRect(rect);
      }
      expect(c.isSolved, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(reported?.solved, isTrue);
      expect(reported?.gameId, 'shikaku');
      expect(reported?.details['rows'], 5);
      c.dispose();
    });

    test('a new rectangle replaces the ones it overlaps', () {
      final c = ShikakuController(puzzle: puzzle)
        ..addRect(const GridRect(top: 0, left: 0, height: 1, width: 2))
        ..addRect(const GridRect(top: 1, left: 0, height: 1, width: 2))
        ..addRect(const GridRect(top: 0, left: 1, height: 2, width: 1));
      expect(c.rects, [const GridRect(top: 0, left: 1, height: 2, width: 1)]);
      c.dispose();
    });

    test('validity follows the rules', () {
      final c = ShikakuController(puzzle: puzzle);
      for (final rect in puzzle.solution) {
        expect(c.isValid(rect), isTrue);
      }
      const whole = GridRect(top: 0, left: 0, height: 5, width: 5);
      expect(c.isValid(whole), isFalse, reason: 'holds several clues');
      c.dispose();
    });

    test('mistakes are off by default and can be enabled', () {
      final wrong = puzzle.solution.first.height > 1
          ? GridRect(
              top: puzzle.solution.first.top,
              left: puzzle.solution.first.left,
              height: 1,
              width: 1)
          : const GridRect(top: 0, left: 0, height: 5, width: 5);
      final quiet = ShikakuController(puzzle: puzzle)..addRect(wrong);
      expect(quiet.mistakes, 0);
      expect(quiet.isWrong(wrong), isFalse);
      quiet.dispose();

      final strict = ShikakuController(
        puzzle: puzzle,
        countMistakes: true,
        revealMistakes: true,
      )..addRect(wrong);
      expect(strict.mistakes, 1);
      expect(strict.isWrong(wrong), isTrue);
      strict.dispose();
    });

    test('remove, clear and undo', () {
      final rect = puzzle.solution.first;
      final c = ShikakuController(puzzle: puzzle)
        ..addRect(rect)
        ..removeRectAt(rect.top, rect.left);
      expect(c.rects, isEmpty);
      c.undo();
      expect(c.rects, [rect]);
      c.clearRects();
      expect(c.rects, isEmpty);
      c.undo();
      expect(c.rects, [rect]);
      c.dispose();
    });

    test('hints solve the whole puzzle', () {
      final c = ShikakuController(puzzle: puzzle);
      while (c.hint()) {}
      expect(c.isSolved, isTrue);
      expect(c.hintsUsed, puzzle.clues.length);
      c.dispose();
    });

    test('maxHints limits hints', () {
      final c = ShikakuController(puzzle: puzzle, maxHints: 1);
      expect(c.hint(), isTrue);
      expect(c.hint(), isFalse);
      c.dispose();
    });
  });

  group('Shikaku widgets', () {
    testWidgets('dragging draws a rectangle and tapping removes it',
        (tester) async {
      final controller = ShikakuController(
        puzzle: generator.generate(rows: 5, seed: 31),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: ShikakuBoard(controller: controller),
            ),
          ),
        ),
      ));

      final origin = tester.getTopLeft(find.byType(ShikakuBoard));
      // Drag from cell (0,0) to cell (1,2).
      final gesture = await tester.startGesture(origin + const Offset(25, 25));
      await gesture.moveTo(origin + const Offset(75, 75));
      await tester.pump();
      await gesture.moveTo(origin + const Offset(125, 75));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(controller.rects,
          [const GridRect(top: 0, left: 0, height: 2, width: 3)]);

      await tester.tapAt(origin + const Offset(75, 25));
      await tester.pump();
      expect(controller.rects, isEmpty);
    });

    testWidgets('keyboard draws a rectangle corner to corner', (tester) async {
      final controller = ShikakuController(
        puzzle: generator.generate(rows: 5, seed: 31),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ShikakuBoard(controller: controller, autofocus: true),
        ),
      ));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(controller.rects,
          [const GridRect(top: 0, left: 0, height: 2, width: 3)]);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      expect(controller.rects, isEmpty);
    });

    testWidgets('ShikakuGame shows every clue', (tester) async {
      final puzzle = generator.generate(rows: 5, seed: 31);
      final controller = ShikakuController(puzzle: puzzle);
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ShikakuGame(controller: controller)),
      ));
      for (final clue in puzzle.clues) {
        expect(
          find.bySemanticsLabel(
              'Row ${clue.position.row + 1}, column ${clue.position.col + 1}'),
          findsOneWidget,
        );
      }
      expect(find.text('Hint'), findsOneWidget);
    });
  });
}
