import '../core/cell_position.dart';
import '../core/puzzle_controller.dart';
import '../core/puzzle_difficulty.dart';
import 'star_battle_puzzle.dart';

/// What the player has put in a Star Battle cell.
enum StarBattleMark {
  /// Nothing.
  empty,

  /// A cross: the player has ruled this cell out.
  cross,

  /// A star.
  star,
}

/// Game state and rules for a [StarBattlePuzzle].
///
/// Use it with `StarBattleGame` / `StarBattleBoard`, or drive your own UI
/// with [tap], [setMark], the stroke methods and [hint].
///
/// Remember to [dispose] it when it is no longer needed.
class StarBattleController
    extends PuzzleController<StarBattlePuzzle, List<StarBattleMark>> {
  /// Creates a controller for [puzzle].
  StarBattleController({
    required super.puzzle,
    super.onFinished,
    super.maxMistakes,
    super.maxHints,
    super.initialElapsed,
    super.startClock,
    this.tapCycle = const [
      StarBattleMark.empty,
      StarBattleMark.cross,
      StarBattleMark.star,
    ],
    this.countMistakes = false,
    this.revealMistakes = false,
    this.highlightConflicts = true,
  })  : assert(tapCycle.length >= 2, 'tapCycle needs at least two marks'),
        _marks = List.filled(puzzle.size * puzzle.size, StarBattleMark.empty);

  /// The marks a tap steps through, in order. The default goes
  /// empty → cross → star → empty; use `[empty, star]` to skip crosses.
  final List<StarBattleMark> tapCycle;

  /// Whether placing a star where the solution has none counts as a
  /// mistake. Off by default, since players often try stars out.
  final bool countMistakes;

  /// Whether stars that differ from the solution are flagged (see
  /// [isWrong]).
  final bool revealMistakes;

  /// Whether stars that break a rule are flagged (see [hasConflict]). This
  /// follows the rules only and never reveals the solution.
  final bool highlightConflicts;

  List<StarBattleMark> _marks;
  bool _inStroke = false;
  bool _strokeChanged = false;

  @override
  String get gameId => 'star_battle';

  @override
  PuzzleDifficulty? get difficulty => puzzle.difficulty;

  @override
  int? get seed => puzzle.seed;

  @override
  Map<String, Object?> get resultDetails => {'size': size};

  /// Rows, columns, regions and stars.
  int get size => puzzle.size;

  int _index(int row, int col) => row * size + col;

  /// The mark at [row], [col].
  StarBattleMark markAt(int row, int col) => _marks[_index(row, col)];

  /// Positions of all placed stars.
  List<CellPosition> get stars => [
        for (var i = 0; i < _marks.length; i++)
          if (_marks[i] == StarBattleMark.star)
            CellPosition(i ~/ size, i % size),
      ];

  /// Number of placed stars.
  int get starCount => _marks.where((m) => m == StarBattleMark.star).length;

  /// Whether an empty cell can no longer hold a star because a placed star
  /// shares its row, column or region, or touches it. Handy for drawing
  /// automatic crosses; the board does this by default.
  bool isBlocked(int row, int col) {
    if (markAt(row, col) != StarBattleMark.empty) return false;
    final region = puzzle.regionAt(row, col);
    for (final s in stars) {
      if (s.row == row ||
          s.col == col ||
          puzzle.regionAt(s.row, s.col) == region ||
          s.touches(CellPosition(row, col))) {
        return true;
      }
    }
    return false;
  }

  /// Whether the star at [row], [col] breaks a rule: another star in the
  /// same row, column or region, or touching it.
  bool hasConflict(int row, int col) {
    if (!highlightConflicts || markAt(row, col) != StarBattleMark.star) {
      return false;
    }
    final here = CellPosition(row, col);
    final region = puzzle.regionAt(row, col);
    for (final s in stars) {
      if (s == here) continue;
      if (s.row == row ||
          s.col == col ||
          puzzle.regionAt(s.row, s.col) == region ||
          s.touches(here)) {
        return true;
      }
    }
    return false;
  }

  /// Whether the star at [row], [col] isn't in the solution. Always `false`
  /// when [revealMistakes] is off.
  bool isWrong(int row, int col) =>
      revealMistakes &&
      markAt(row, col) == StarBattleMark.star &&
      !puzzle.isSolutionStar(row, col);

  /// Steps [row], [col] to the next mark in [tapCycle].
  void tap(int row, int col) {
    final current = markAt(row, col);
    final at = tapCycle.indexOf(current);
    final next = tapCycle[(at + 1) % tapCycle.length];
    setMark(row, col, next);
  }

  /// Sets the mark at [row], [col].
  void setMark(int row, int col, StarBattleMark mark) {
    if (!acceptsInput) return;
    final i = _index(row, col);
    if (_marks[i] == mark) return;
    if (_inStroke) {
      if (!_strokeChanged) pushUndo();
      _strokeChanged = true;
    } else {
      pushUndo();
    }
    _marks[i] = mark;
    countMove();
    if (mark == StarBattleMark.star &&
        countMistakes &&
        !puzzle.isSolutionStar(row, col)) {
      countMistake();
    }
    checkCompletion();
    notifyListeners();
  }

  /// Starts a stroke: marks set until [endStroke] (e.g. while dragging
  /// crosses across several cells) are undone together.
  void beginStroke() {
    _inStroke = true;
    _strokeChanged = false;
  }

  /// Ends a stroke started with [beginStroke].
  void endStroke() {
    _inStroke = false;
    _strokeChanged = false;
  }

  /// Removes every mark.
  void clearMarks() {
    if (!acceptsInput || _marks.every((m) => m == StarBattleMark.empty)) {
      return;
    }
    pushUndo();
    _marks = List.filled(_marks.length, StarBattleMark.empty);
    notifyListeners();
  }

  /// Places one correct star, removing any star that conflicts with it.
  ///
  /// Returns `false` when no hint was given (limit reached, game over or
  /// already solved).
  bool hint() {
    if (!canHint) return false;
    int? row;
    for (var r = 0; r < size; r++) {
      if (markAt(r, puzzle.solution[r]) != StarBattleMark.star) {
        row = r;
        break;
      }
    }
    if (row == null) {
      // Every true star is placed; clear any extra star instead.
      final wrong = stars.where((s) => !puzzle.isSolutionStar(s.row, s.col));
      if (wrong.isEmpty) return false;
      pushUndo();
      for (final s in wrong) {
        _marks[_index(s.row, s.col)] = StarBattleMark.empty;
      }
    } else {
      pushUndo();
      final target = CellPosition(row, puzzle.solution[row]);
      final region = puzzle.regionAt(target.row, target.col);
      for (final s in stars) {
        if (s.row == target.row ||
            s.col == target.col ||
            puzzle.regionAt(s.row, s.col) == region ||
            s.touches(target)) {
          _marks[_index(s.row, s.col)] = StarBattleMark.empty;
        }
      }
      _marks[_index(target.row, target.col)] = StarBattleMark.star;
    }
    countHint();
    checkCompletion();
    notifyListeners();
    return true;
  }

  /// Saved as one number per cell: the [StarBattleMark] index.
  @override
  Object? encodeBoard() => [for (final m in _marks) m.index];

  @override
  void decodeBoard(Object? data) {
    if (data is! List || data.length != size * size) {
      throw ArgumentError.value(data, 'board', 'does not fit this puzzle');
    }
    _marks = [
      for (final v in data)
        StarBattleMark.values[
            (v as num).toInt().clamp(0, StarBattleMark.values.length - 1)],
    ];
  }

  @override
  List<StarBattleMark> takeSnapshot() => List.of(_marks);

  @override
  void restoreSnapshot(List<StarBattleMark> snapshot) =>
      _marks = List.of(snapshot);

  @override
  void resetBoard() => _marks = List.filled(size * size, StarBattleMark.empty);

  @override
  bool checkSolved() {
    final placed = stars;
    if (placed.length != size) return false;
    final rows = <int>{}, cols = <int>{}, regions = <int>{};
    for (final s in placed) {
      rows.add(s.row);
      cols.add(s.col);
      regions.add(puzzle.regionAt(s.row, s.col));
    }
    if (rows.length != size || cols.length != size || regions.length != size) {
      return false;
    }
    for (var i = 0; i < placed.length; i++) {
      for (var j = i + 1; j < placed.length; j++) {
        if (placed[i].touches(placed[j])) return false;
      }
    }
    return true;
  }
}
