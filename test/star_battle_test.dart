import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_games_kit/star_battle.dart';

bool _regionsConnected(StarBattlePuzzle p) {
  final n = p.size;
  for (var id = 0; id < n; id++) {
    final cells = [
      for (var i = 0; i < n * n; i++)
        if (p.regions[i] == id) i,
    ];
    if (cells.isEmpty) return false;
    final seen = <int>{cells.first};
    final queue = [cells.first];
    while (queue.isNotEmpty) {
      final i = queue.removeLast();
      final r = i ~/ n, c = i % n;
      for (final j in [
        if (r > 0) i - n,
        if (r < n - 1) i + n,
        if (c > 0) i - 1,
        if (c < n - 1) i + 1,
      ]) {
        if (p.regions[j] == id && seen.add(j)) queue.add(j);
      }
    }
    if (seen.length != cells.length) return false;
  }
  return true;
}

void _placeSolution(StarBattleController c) {
  for (final s in c.puzzle.solutionStars) {
    c.setMark(s.row, s.col, StarBattleMark.star);
  }
}

void main() {
  const generator = StarBattleGenerator();

  group('StarBattleGenerator', () {
    for (final size in [5, 6, 7, 8, 9, 10]) {
      test('${size}x$size puzzles are unique with connected regions', () {
        for (var seed = 0; seed < 15; seed++) {
          final p = generator.generate(size: size, seed: seed);
          expect(p.size, size);
          expect(StarBattleSolver.countSolutions(size, p.regions), 1);
          expect(StarBattleSolver.solve(size, p.regions), p.solution);
          expect(_regionsConnected(p), isTrue, reason: 'seed $seed');
        }
      });
    }

    test('difficulty picks the default size', () {
      for (final d in PuzzleDifficulty.values) {
        expect(
          generator.generate(difficulty: d, seed: 1).size,
          StarBattleGenerator.defaultSize(d),
        );
      }
    });

    test('same seed gives the same puzzle', () {
      expect(generator.generate(seed: 5), generator.generate(seed: 5));
      expect(
          generator.generate(seed: 5) == generator.generate(seed: 6), isFalse);
    });

    test('output is pinned so a seed means the same puzzle everywhere', () {
      final p = generator.generate(size: 6, seed: 2026);
      expect(p.solution, StarBattleSolver.solve(6, p.regions));
      expect(p.regions.join(), _pinned6);
    });

    test('rejects sizes outside 5..10', () {
      expect(() => generator.generate(size: 4), throwsRangeError);
      expect(() => generator.generate(size: 11), throwsRangeError);
    });
  });

  group('StarBattlePuzzle', () {
    test('parse reads letter layouts', () {
      final generated = generator.generate(size: 5, seed: 3);
      final layout = [
        for (var r = 0; r < 5; r++)
          String.fromCharCodes([
            for (var c = 0; c < 5; c++) 65 + generated.regionAt(r, c),
          ]),
      ].join('\n');
      final parsed = StarBattlePuzzle.parse(layout);
      expect(parsed.regions, generated.regions);
      expect(parsed.solution, generated.solution);
    });

    test('round-trips through JSON', () {
      final p = generator.generate(seed: 8, difficulty: PuzzleDifficulty.hard);
      final restored = StarBattlePuzzle.fromJson(p.toJson());
      expect(restored, p);
      expect(restored.solution, p.solution);
      expect(restored.seed, 8);
    });

    test('rejects a solution with touching stars', () {
      expect(
        () => StarBattlePuzzle(
          size: 5,
          regions: List.generate(25, (i) => i ~/ 5),
          solution: [0, 1, 2, 3, 4],
        ),
        throwsArgumentError,
      );
    });
  });

  group('StarBattleController', () {
    late StarBattlePuzzle puzzle;
    setUp(() => puzzle = generator.generate(size: 6, seed: 21));

    test('placing the solution finishes the game', () async {
      PuzzleResult? reported;
      final c =
          StarBattleController(puzzle: puzzle, onFinished: (r) => reported = r);
      _placeSolution(c);
      expect(c.isSolved, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(reported?.solved, isTrue);
      expect(reported?.gameId, 'star_battle');
      expect(reported?.details['size'], 6);
      c.dispose();
    });

    test('tap cycles empty -> cross -> star -> empty', () {
      final c = StarBattleController(puzzle: puzzle);
      c.tap(0, 0);
      expect(c.markAt(0, 0), StarBattleMark.cross);
      c.tap(0, 0);
      expect(c.markAt(0, 0), StarBattleMark.star);
      c.tap(0, 0);
      expect(c.markAt(0, 0), StarBattleMark.empty);
      c.dispose();
    });

    test('custom tap cycle', () {
      final c = StarBattleController(
        puzzle: puzzle,
        tapCycle: const [StarBattleMark.empty, StarBattleMark.star],
      );
      c.tap(1, 1);
      expect(c.markAt(1, 1), StarBattleMark.star);
      c.dispose();
    });

    test('touching stars conflict and block neighbours', () {
      final c = StarBattleController(puzzle: puzzle)
        ..setMark(2, 2, StarBattleMark.star)
        ..setMark(3, 3, StarBattleMark.star);
      expect(c.hasConflict(2, 2), isTrue);
      expect(c.hasConflict(3, 3), isTrue);
      expect(c.isBlocked(2, 5), isTrue, reason: 'same row');
      c.dispose();
    });

    test('mistakes are off by default and can be enabled', () {
      final wrongCol = (puzzle.solution[0] + 2) % 6;
      final quiet = StarBattleController(puzzle: puzzle)
        ..setMark(0, wrongCol, StarBattleMark.star);
      expect(quiet.mistakes, 0);
      expect(quiet.isWrong(0, wrongCol), isFalse);
      quiet.dispose();

      final strict = StarBattleController(
        puzzle: puzzle,
        countMistakes: true,
        revealMistakes: true,
      )..setMark(0, wrongCol, StarBattleMark.star);
      expect(strict.mistakes, 1);
      expect(strict.isWrong(0, wrongCol), isTrue);
      strict.dispose();
    });

    test('a stroke is undone in one step', () {
      final c = StarBattleController(puzzle: puzzle)
        ..beginStroke()
        ..setMark(0, 0, StarBattleMark.cross)
        ..setMark(0, 1, StarBattleMark.cross)
        ..setMark(0, 2, StarBattleMark.cross)
        ..endStroke()
        ..undo();
      expect(c.markAt(0, 0), StarBattleMark.empty);
      expect(c.markAt(0, 2), StarBattleMark.empty);
      expect(c.canUndo, isFalse);
      c.dispose();
    });

    test('hint places a correct star and clears conflicting ones', () {
      final target = CellPosition(0, puzzle.solution[0]);
      final blocker = CellPosition(0, (target.col + 3) % 6);
      final c = StarBattleController(puzzle: puzzle)
        ..setMark(blocker.row, blocker.col, StarBattleMark.star);
      expect(c.hint(), isTrue);
      expect(c.markAt(target.row, target.col), StarBattleMark.star);
      expect(c.markAt(blocker.row, blocker.col), StarBattleMark.empty);
      expect(c.hintsUsed, 1);
      c.dispose();
    });

    test('hints solve the whole puzzle', () {
      final c = StarBattleController(puzzle: puzzle);
      while (c.hint()) {}
      expect(c.isSolved, isTrue);
      expect(c.hintsUsed, 6);
      c.dispose();
    });

    test('clearMarks empties the board and can be undone', () {
      final c = StarBattleController(puzzle: puzzle)
        ..setMark(1, 1, StarBattleMark.star)
        ..clearMarks();
      expect(c.starCount, 0);
      c.undo();
      expect(c.starCount, 1);
      c.dispose();
    });
  });

  group('Star Battle widgets', () {
    testWidgets('tapping a cell cycles its mark', (tester) async {
      final controller = StarBattleController(
        puzzle: generator.generate(size: 5, seed: 4),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StarBattleGame(controller: controller)),
      ));

      final cell = find.bySemanticsLabel(RegExp(r'^Row 1, column 1,'));
      await tester.tap(cell);
      await tester.pump();
      expect(controller.markAt(0, 0), StarBattleMark.cross);
      await tester.tap(cell);
      await tester.pump();
      expect(controller.markAt(0, 0), StarBattleMark.star);
    });

    testWidgets('dragging crosses out cells in one undo step', (tester) async {
      final controller = StarBattleController(
        puzzle: generator.generate(size: 5, seed: 4),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: StarBattleBoard(controller: controller),
            ),
          ),
        ),
      ));

      final topLeft = tester.getTopLeft(find.byType(StarBattleBoard));
      final gesture = await tester.startGesture(topLeft + const Offset(25, 25));
      for (var step = 1; step <= 4; step++) {
        await gesture.moveBy(const Offset(50, 0));
        await tester.pump();
      }
      await gesture.up();
      await tester.pump();

      for (var col = 0; col < 5; col++) {
        expect(controller.markAt(0, col), StarBattleMark.cross);
      }
      controller.undo();
      expect(controller.markAt(0, 3), StarBattleMark.empty);
    });

    testWidgets('a custom marker builder is used', (tester) async {
      final controller = StarBattleController(
        puzzle: generator.generate(size: 5, seed: 4),
      )..setMark(0, 0, StarBattleMark.star);
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StarBattleBoard(
            controller: controller,
            markerBuilder: (context, cell, theme, size) =>
                cell.mark == StarBattleMark.star
                    ? const Text('Q')
                    : const SizedBox.shrink(),
          ),
        ),
      ));
      expect(find.text('Q'), findsOneWidget);
    });
  });
}

// Verified identical on the Dart VM and compiled to JavaScript. If this
// changes, existing seeds would produce different puzzles.
const _pinned6 = '000111200111220111550111555533444433';
