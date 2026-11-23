import '../core/puzzle_controller.dart';
import '../core/puzzle_difficulty.dart';
import 'grid_rect.dart';
import 'shikaku_puzzle.dart';

/// Game state and rules for a [ShikakuPuzzle].
///
/// Use it with `ShikakuGame` / `ShikakuBoard`, or drive your own UI with
/// [addRect], [removeRectAt], [clearRects] and [hint].
///
/// Remember to [dispose] it when it is no longer needed.
class ShikakuController
    extends PuzzleController<ShikakuPuzzle, List<GridRect>> {
  /// Creates a controller for [puzzle].
  ShikakuController({
    required super.puzzle,
    super.onFinished,
    super.maxMistakes,
    super.maxHints,
    super.initialElapsed,
    super.startClock,
    this.countMistakes = false,
    this.revealMistakes = false,
  });

  /// Whether drawing a rectangle that isn't in the solution counts as a
  /// mistake. Off by default, since players often try shapes out.
  final bool countMistakes;

  /// Whether rectangles that aren't in the solution are flagged (see
  /// [isWrong]).
  final bool revealMistakes;

  List<GridRect> _rects = [];

  @override
  String get gameId => 'shikaku';

  @override
  PuzzleDifficulty? get difficulty => puzzle.difficulty;

  @override
  int? get seed => puzzle.seed;

  @override
  Map<String, Object?> get resultDetails => {
        'rows': puzzle.rows,
        'cols': puzzle.cols,
        'clues': puzzle.clues.length,
      };

  /// The rectangles drawn so far.
  List<GridRect> get rects => List.unmodifiable(_rects);

  /// The rectangle covering [row], [col], if any.
  GridRect? rectAt(int row, int col) {
    for (final rect in _rects) {
      if (rect.contains(row, col)) return rect;
    }
    return null;
  }

  /// Indices of the clues inside [rect].
  List<int> cluesIn(GridRect rect) => [
        for (var i = 0; i < puzzle.clues.length; i++)
          if (rect.contains(
              puzzle.clues[i].position.row, puzzle.clues[i].position.col))
            i,
      ];

  /// Whether [rect] follows the rules: exactly one clue inside, equal to its
  /// area. (It may still differ from the solution.)
  bool isValid(GridRect rect) {
    final inside = cluesIn(rect);
    return inside.length == 1 && puzzle.clues[inside.first].value == rect.area;
  }

  /// Whether [rect] differs from the solution. Always `false` when
  /// [revealMistakes] is off.
  bool isWrong(GridRect rect) =>
      revealMistakes && !puzzle.solution.contains(rect);

  /// Number of cells covered by rectangles.
  int get coveredCells => _rects.fold(0, (sum, r) => sum + r.area);

  /// Draws [rect], replacing any rectangles it overlaps.
  void addRect(GridRect rect) {
    if (!acceptsInput) return;
    if (rect.top < 0 ||
        rect.left < 0 ||
        rect.bottom >= puzzle.rows ||
        rect.right >= puzzle.cols) {
      throw RangeError('$rect lies outside the grid.');
    }
    if (_rects.contains(rect)) return;
    pushUndo();
    _rects = [
      for (final r in _rects)
        if (!r.overlaps(rect)) r,
      rect,
    ];
    countMove();
    if (countMistakes && !puzzle.solution.contains(rect)) countMistake();
    checkCompletion();
    notifyListeners();
  }

  /// Removes the rectangle covering [row], [col], if any.
  void removeRectAt(int row, int col) {
    final rect = rectAt(row, col);
    if (rect == null || !acceptsInput) return;
    pushUndo();
    _rects = [
      for (final r in _rects)
        if (r != rect) r,
    ];
    countMove();
    notifyListeners();
  }

  /// Removes every rectangle.
  void clearRects() {
    if (!acceptsInput || _rects.isEmpty) return;
    pushUndo();
    _rects = [];
    notifyListeners();
  }

  /// Draws one correct rectangle, replacing anything in its way.
  ///
  /// Returns `false` when no hint was given (limit reached, game over or
  /// already solved).
  bool hint() {
    if (!canHint) return false;
    GridRect? target;
    for (final rect in puzzle.solution) {
      if (!_rects.contains(rect)) {
        target = rect;
        break;
      }
    }
    if (target == null) return false;
    pushUndo();
    _rects = [
      for (final r in _rects)
        if (!r.overlaps(target)) r,
      target,
    ];
    countHint();
    checkCompletion();
    notifyListeners();
    return true;
  }

  @override
  Object? encodeBoard() => [for (final r in _rects) r.toJson()];

  @override
  void decodeBoard(Object? data) {
    if (data is! List) throw ArgumentError.value(data, 'board');
    final rects = [
      for (final r in data)
        GridRect.fromJson(Map<String, Object?>.from(r as Map)),
    ];
    for (final r in rects) {
      if (r.top < 0 ||
          r.left < 0 ||
          r.bottom >= puzzle.rows ||
          r.right >= puzzle.cols) {
        throw ArgumentError.value(data, 'board', 'does not fit this puzzle');
      }
    }
    _rects = rects;
  }

  @override
  List<GridRect> takeSnapshot() => List.of(_rects);

  @override
  void restoreSnapshot(List<GridRect> snapshot) => _rects = List.of(snapshot);

  @override
  void resetBoard() => _rects = [];

  @override
  bool checkSolved() =>
      coveredCells == puzzle.rows * puzzle.cols && _rects.every(isValid);
}
