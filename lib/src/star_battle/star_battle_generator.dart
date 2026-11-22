import '../core/puzzle_difficulty.dart';
import '../core/seeded_random.dart';
import 'star_battle_puzzle.dart';
import 'star_battle_solver.dart';

/// Generates Star Battle puzzles with exactly one solution.
///
/// It places a valid set of stars, grows a region around each star, and
/// repairs the regions until no other arrangement of stars fits. The same
/// seed and settings always produce the same puzzle.
class StarBattleGenerator {
  /// Creates a generator.
  const StarBattleGenerator();

  /// Default grid size for [difficulty].
  static int defaultSize(PuzzleDifficulty difficulty) => switch (difficulty) {
        PuzzleDifficulty.easy => 6,
        PuzzleDifficulty.medium => 7,
        PuzzleDifficulty.hard => 8,
      };

  /// Generates a puzzle.
  ///
  /// [size] overrides the size from [defaultSize] and may be 5 to 10.
  /// Without a [seed] a random one is used; it is stored in
  /// [StarBattlePuzzle.seed].
  StarBattlePuzzle generate({
    PuzzleDifficulty difficulty = PuzzleDifficulty.medium,
    int? size,
    int? seed,
  }) {
    final n = size ?? defaultSize(difficulty);
    RangeError.checkValueInInterval(n, 5, 10, 'size');
    final usedSeed = seed ?? SeededRandom.randomSeed();
    final random = SeededRandom(usedSeed);

    for (var attempt = 0; attempt < 1000; attempt++) {
      final stars = _placeStars(n, random);
      final regions = _growRegions(n, stars, random);
      if (_smallestRegion(n, regions) < _minRegionSize) continue;
      if (_repairUntilUnique(n, regions, stars, random)) {
        return StarBattlePuzzle(
          size: n,
          regions: regions,
          solution: stars,
          seed: usedSeed,
          difficulty: difficulty,
        );
      }
    }
    throw StateError(
        'Could not generate a $n x $n puzzle from seed $usedSeed.');
  }

  /// A random valid star arrangement: one per row and column, none touching.
  List<int> _placeStars(int n, SeededRandom random) {
    final cols = List<int>.filled(n, -1);
    bool place(int row, int used) {
      if (row == n) return true;
      final options = random.shuffle(List<int>.generate(n, (c) => c));
      for (final col in options) {
        if (used & (1 << col) != 0) continue;
        if (row > 0 && (col - cols[row - 1]).abs() <= 1) continue;
        cols[row] = col;
        if (place(row + 1, used | (1 << col))) return true;
      }
      return false;
    }

    place(0, 0);
    return cols;
  }

  /// Grows one region from each star, one cell at a time, giving irregular
  /// shapes. Each step compares two random regions that can still grow and
  /// extends the smaller one, which keeps region sizes fairly even (a
  /// one-cell region would give its star away).
  List<int> _growRegions(int n, List<int> stars, SeededRandom random) {
    final owner = List<int>.filled(n * n, -1);
    final sizes = List<int>.filled(n, 1);
    final ids = random.shuffle(List<int>.generate(n, (i) => i));
    for (var row = 0; row < n; row++) {
      owner[row * n + stars[row]] = ids[row];
    }
    var unassigned = n * n - n;
    while (unassigned > 0) {
      final frontier = <int, List<int>>{};
      for (var i = 0; i < owner.length; i++) {
        if (owner[i] != -1) continue;
        for (final j in _neighbours(n, i)) {
          if (owner[j] != -1) (frontier[owner[j]] ??= []).add(i);
        }
      }
      final growable = frontier.keys.toList()..sort();
      var region = random.pick(growable);
      final rival = random.pick(growable);
      if (sizes[rival] < sizes[region]) region = rival;
      final cell = random.pick(frontier[region]!);
      owner[cell] = region;
      sizes[region]++;
      unassigned--;
    }
    return owner;
  }

  /// Moves cells between regions until [stars] is the only solution.
  ///
  /// Each round finds another solution and hands one of its stars' cells
  /// (one that isn't a true star) to a neighbouring region, which breaks
  /// that alternative while keeping the true solution valid.
  bool _repairUntilUnique(
    int n,
    List<int> regions,
    List<int> stars,
    SeededRandom random,
  ) {
    final starCells = {for (var r = 0; r < n; r++) r * n + stars[r]};
    final sizes = List<int>.filled(n, 0);
    for (final id in regions) {
      sizes[id]++;
    }
    for (var round = 0; round < n * n * 2; round++) {
      final other = _otherSolution(n, regions, stars);
      if (other == null) return true;

      final candidates = <(int, int)>[];
      for (var row = 0; row < n; row++) {
        final cell = row * n + other[row];
        final from = regions[cell];
        // Never shrink a region below the minimum size.
        if (starCells.contains(cell) || sizes[from] <= _minRegionSize) {
          continue;
        }
        for (final j in _neighbours(n, cell)) {
          final target = regions[j];
          if (target != from && _staysConnected(n, regions, cell, from)) {
            candidates.add((cell, target));
          }
        }
      }
      if (candidates.isEmpty) return false;
      final (cell, target) = random.pick(candidates);
      sizes[regions[cell]]--;
      sizes[target]++;
      regions[cell] = target;
    }
    return false;
  }

  /// Smallest region the generator produces. Tiny regions give their star
  /// away; three cells keeps every region a real decision.
  static const int _minRegionSize = 3;

  static int _smallestRegion(int n, List<int> regions) {
    final sizes = List<int>.filled(n, 0);
    for (final id in regions) {
      sizes[id]++;
    }
    return sizes.reduce((a, b) => a < b ? a : b);
  }

  /// A solution different from [stars], or `null` if [stars] is unique.
  List<int>? _otherSolution(int n, List<int> regions, List<int> stars) {
    for (final solution in StarBattleSolver.solutions(n, regions)) {
      if (!_sameStars(solution, stars)) return solution;
    }
    return null;
  }

  static bool _sameStars(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Whether [region] stays in one piece after giving away [cell].
  bool _staysConnected(int n, List<int> regions, int cell, int region) {
    final members = <int>[
      for (var i = 0; i < regions.length; i++)
        if (regions[i] == region && i != cell) i,
    ];
    if (members.isEmpty) return false;
    final seen = <int>{members.first};
    final queue = [members.first];
    while (queue.isNotEmpty) {
      final i = queue.removeLast();
      for (final j in _neighbours(n, i)) {
        if (j != cell && regions[j] == region && seen.add(j)) queue.add(j);
      }
    }
    return seen.length == members.length;
  }

  static Iterable<int> _neighbours(int n, int i) sync* {
    final row = i ~/ n, col = i % n;
    if (row > 0) yield i - n;
    if (row < n - 1) yield i + n;
    if (col > 0) yield i - 1;
    if (col < n - 1) yield i + 1;
  }
}
