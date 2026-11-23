import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_games_kit/puzzle_core.dart';

void main() {
  group('SeededRandom', () {
    test('same seed gives the same sequence', () {
      final a = SeededRandom(42);
      final b = SeededRandom(42);
      expect(
        List.generate(20, (_) => a.nextInt(1000)),
        List.generate(20, (_) => b.nextInt(1000)),
      );
    });

    test('different seeds diverge', () {
      final a = SeededRandom(1);
      final b = SeededRandom(2);
      expect(
        List.generate(10, (_) => a.nextInt(1 << 30)),
        isNot(List.generate(10, (_) => b.nextInt(1 << 30))),
      );
    });

    test('sequence is pinned so seeds stay stable across versions', () {
      final r = SeededRandom(2026);
      expect(List.generate(5, (_) => r.nextInt(100)), [72, 36, 29, 32, 44]);
    });

    test('nextInt stays in range and nextDouble in [0, 1)', () {
      final r = SeededRandom(7);
      for (var i = 0; i < 1000; i++) {
        expect(r.nextInt(6), inInclusiveRange(0, 5));
        final d = r.nextDouble();
        expect(d >= 0 && d < 1, isTrue);
      }
    });

    test('handles negative and very large seeds', () {
      expect(() => SeededRandom(-5).nextInt(10), returnsNormally);
      expect(() => SeededRandom(1 << 62).nextInt(10), returnsNormally);
    });

    test('dailySeed ignores time of day and varies by salt', () {
      final morning = DateTime(2026, 11, 22, 8);
      final night = DateTime(2026, 11, 22, 23, 59);
      expect(SeededRandom.dailySeed(morning), SeededRandom.dailySeed(night));
      expect(
        SeededRandom.dailySeed(morning, salt: 'user-1'),
        isNot(SeededRandom.dailySeed(morning, salt: 'user-2')),
      );
      expect(
        SeededRandom.dailySeed(DateTime(2026, 11, 23)),
        isNot(SeededRandom.dailySeed(morning)),
      );
    });

    test('hashString is stable', () {
      expect(SeededRandom.hashString(''), 5381);
      expect(
          SeededRandom.hashString('sudoku'), SeededRandom.hashString('sudoku'));
    });
  });

  group('PuzzleResult', () {
    test('round-trips through JSON', () {
      final result = PuzzleResult(
        gameId: 'sudoku',
        solved: true,
        elapsed: const Duration(seconds: 95),
        completedAt: DateTime.utc(2026, 11, 22, 10),
        difficulty: PuzzleDifficulty.hard,
        seed: 123,
        mistakes: 2,
        hintsUsed: 1,
        moves: 30,
        details: const {'size': 6},
      );
      final restored = PuzzleResult.fromJson(result.toJson());
      expect(restored.toJson(), result.toJson());
    });
  });

  test('formatPuzzleDuration', () {
    expect(formatPuzzleDuration(const Duration(seconds: 5)), '0:05');
    expect(
        formatPuzzleDuration(const Duration(minutes: 3, seconds: 9)), '3:09');
    expect(
      formatPuzzleDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
  });

  test('CellPosition equality and touching', () {
    expect(const CellPosition(1, 2), const CellPosition(1, 2));
    expect(const CellPosition(1, 1).touches(const CellPosition(2, 2)), isTrue);
    expect(const CellPosition(1, 1).touches(const CellPosition(3, 1)), isFalse);
    expect(const CellPosition(1, 1).touches(const CellPosition(1, 1)), isFalse);
  });
}
