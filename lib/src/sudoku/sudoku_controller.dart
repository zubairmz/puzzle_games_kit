import '../core/cell_position.dart';
import '../core/puzzle_controller.dart';
import '../core/puzzle_difficulty.dart';
import 'sudoku_puzzle.dart';

/// The board state saved for undo: cell values and note bit masks.
typedef SudokuSnapshot = ({List<int> values, List<int> notes});

/// Game state and rules for a [SudokuPuzzle].
///
/// Use it with the widgets in this package (`SudokuGame`, `SudokuBoard`,
/// `SudokuInputPad`) or drive your own UI: listen for changes and call
/// [select], [input], [erase], [undo] and [hint].
///
/// Remember to [dispose] it when it is no longer needed.
class SudokuController extends PuzzleController<SudokuPuzzle, SudokuSnapshot> {
  /// Creates a controller for [puzzle].
  SudokuController({
    required super.puzzle,
    super.onFinished,
    super.maxMistakes,
    super.maxHints,
    super.initialElapsed,
    super.startClock,
    this.countMistakes = true,
    this.revealMistakes = true,
    this.highlightConflicts = true,
    this.autoRemoveNotes = true,
    this.allowNotes = true,
    this.clearOnSameValue = false,
  })  : _values = List<int>.of(puzzle.givens),
        _notes = List<int>.filled(puzzle.cellCount, 0);

  /// Whether entering a value that differs from the solution counts as a
  /// mistake (and can end the game via `maxMistakes`).
  final bool countMistakes;

  /// Whether entries that differ from the solution are flagged as wrong
  /// (see [isWrong]). Turn off for a harder game without feedback.
  final bool revealMistakes;

  /// Whether duplicate values in a row, column or box are flagged (see
  /// [hasConflict]). This follows the rules only and never reveals the
  /// solution.
  final bool highlightConflicts;

  /// Whether entering a value removes that value from the notes of every
  /// cell in the same row, column and box.
  final bool autoRemoveNotes;

  /// Whether pencil notes are available.
  final bool allowNotes;

  /// Whether entering the value a cell already holds clears it.
  final bool clearOnSameValue;

  List<int> _values;
  List<int> _notes;
  CellPosition? _selected;
  bool _notesMode = false;

  @override
  String get gameId => 'sudoku';

  @override
  PuzzleDifficulty? get difficulty => puzzle.difficulty;

  @override
  int? get seed => puzzle.seed;

  @override
  Map<String, Object?> get resultDetails => {
        'size': size,
        'boxRows': puzzle.boxRows,
        'boxCols': puzzle.boxCols,
        'givens': puzzle.givenCount,
      };

  /// Cells per row, column and box.
  int get size => puzzle.size;

  /// The selected cell, if any.
  CellPosition? get selected => _selected;

  /// Whether [input] writes notes instead of values.
  bool get notesMode => _notesMode;

  set notesMode(bool value) {
    if (!allowNotes || _notesMode == value) return;
    _notesMode = value;
    notifyListeners();
  }

  /// Switches between entering values and notes.
  void toggleNotesMode() => notesMode = !_notesMode;

  int _index(int row, int col) => row * size + col;

  /// The value at [row], [col], or `0` if empty.
  int valueAt(int row, int col) => _values[_index(row, col)];

  /// The pencil notes at [row], [col].
  Set<int> notesAt(int row, int col) {
    final mask = _notes[_index(row, col)];
    return {
      for (var v = 1; v <= size; v++)
        if (mask & (1 << v) != 0) v,
    };
  }

  /// Whether [row], [col] has note [value].
  bool hasNote(int row, int col, int value) =>
      _notes[_index(row, col)] & (1 << value) != 0;

  /// Whether [row], [col] is a starting clue (not editable).
  bool isGiven(int row, int col) => puzzle.isGiven(row, col);

  /// Whether [row], [col] holds a value that differs from the solution.
  /// Always `false` when [revealMistakes] is off.
  bool isWrong(int row, int col) {
    if (!revealMistakes || isGiven(row, col)) return false;
    final value = valueAt(row, col);
    return value != 0 && value != puzzle.solutionAt(row, col);
  }

  /// Whether the value at [row], [col] repeats in its row, column or box.
  /// Always `false` when [highlightConflicts] is off.
  bool hasConflict(int row, int col) {
    if (!highlightConflicts) return false;
    final value = valueAt(row, col);
    if (value == 0) return false;
    for (final peer in peersOf(row, col)) {
      if (valueAt(peer.row, peer.col) == value) return true;
    }
    return false;
  }

  /// Whether [row], [col] shares a row, column or box with the selection.
  bool isRelatedToSelection(int row, int col) {
    final s = _selected;
    if (s == null) return false;
    return s.row == row ||
        s.col == col ||
        puzzle.boxIndex(s.row, s.col) == puzzle.boxIndex(row, col);
  }

  /// The value in the selected cell, or `0`.
  int get selectedValue =>
      _selected == null ? 0 : valueAt(_selected!.row, _selected!.col);

  /// How many times [value] appears on the board.
  int countOf(int value) => _values.where((v) => v == value).length;

  /// Whether all [size] copies of [value] are placed correctly.
  bool isValueComplete(int value) {
    var count = 0;
    for (var i = 0; i < _values.length; i++) {
      if (_values[i] == value && puzzle.solution[i] == value) count++;
    }
    return count == size;
  }

  /// Every cell sharing a row, column or box with [row], [col].
  Iterable<CellPosition> peersOf(int row, int col) sync* {
    final box = puzzle.boxIndex(row, col);
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (r == row && c == col) continue;
        if (r == row || c == col || puzzle.boxIndex(r, c) == box) {
          yield CellPosition(r, c);
        }
      }
    }
  }

  /// Selects [cell], or clears the selection with `null`.
  void select(CellPosition? cell) {
    if (cell == _selected) return;
    _selected = cell;
    notifyListeners();
  }

  /// Moves the selection by [rows] and [cols], wrapping at the edges.
  void moveSelection(int rows, int cols) {
    final from = _selected ?? const CellPosition(0, 0);
    select(CellPosition(
      (from.row + rows) % size,
      (from.col + cols) % size,
    ));
  }

  /// Enters [value] into the selected cell: a note in [notesMode], otherwise
  /// the cell's value. Does nothing without a selection.
  void input(int value) {
    final cell = _selected;
    if (cell == null) return;
    if (_notesMode) {
      toggleNote(cell.row, cell.col, value);
    } else {
      setValue(cell.row, cell.col, value);
    }
  }

  /// Sets the value of [row], [col]; `0` clears it. Clues can't be changed.
  void setValue(int row, int col, int value) {
    if (!acceptsInput || isGiven(row, col)) return;
    RangeError.checkValueInInterval(value, 0, size, 'value');
    final i = _index(row, col);
    if (_values[i] == value) {
      if (!clearOnSameValue || value == 0) return;
      value = 0;
    }
    pushUndo();
    _values[i] = value;
    _notes[i] = 0;
    if (value != 0) {
      if (autoRemoveNotes) _removeNoteFromPeers(row, col, value);
      countMove();
      if (countMistakes && value != puzzle.solutionAt(row, col)) {
        countMistake();
      }
    }
    checkCompletion();
    notifyListeners();
  }

  /// Adds or removes note [value] at [row], [col]. Only empty cells take
  /// notes.
  void toggleNote(int row, int col, int value) {
    if (!acceptsInput || !allowNotes || isGiven(row, col)) return;
    RangeError.checkValueInInterval(value, 1, size, 'value');
    final i = _index(row, col);
    if (_values[i] != 0) return;
    pushUndo();
    _notes[i] ^= 1 << value;
    notifyListeners();
  }

  /// Clears the value and notes of the selected cell.
  void erase() {
    final cell = _selected;
    if (cell == null || !acceptsInput || isGiven(cell.row, cell.col)) return;
    final i = _index(cell.row, cell.col);
    if (_values[i] == 0 && _notes[i] == 0) return;
    pushUndo();
    _values[i] = 0;
    _notes[i] = 0;
    notifyListeners();
  }

  /// Fills one cell with its solution value and selects it.
  ///
  /// Uses the selected cell if it is empty or wrong, otherwise the first
  /// such cell. Returns `false` when no hint was given (limit reached,
  /// game over, or nothing left to fix).
  bool hint() {
    if (!canHint) return false;
    CellPosition? target;
    final s = _selected;
    if (s != null && _needsHint(s.row, s.col)) {
      target = s;
    } else {
      for (var i = 0; i < _values.length && target == null; i++) {
        final r = i ~/ size, c = i % size;
        if (_needsHint(r, c)) target = CellPosition(r, c);
      }
    }
    if (target == null) return false;

    pushUndo();
    final value = puzzle.solutionAt(target.row, target.col);
    final i = _index(target.row, target.col);
    _values[i] = value;
    _notes[i] = 0;
    if (autoRemoveNotes) _removeNoteFromPeers(target.row, target.col, value);
    _selected = target;
    countHint();
    checkCompletion();
    notifyListeners();
    return true;
  }

  bool _needsHint(int row, int col) =>
      !isGiven(row, col) && valueAt(row, col) != puzzle.solutionAt(row, col);

  void _removeNoteFromPeers(int row, int col, int value) {
    final bit = 1 << value;
    for (final peer in peersOf(row, col)) {
      _notes[_index(peer.row, peer.col)] &= ~bit;
    }
  }

  @override
  SudokuSnapshot takeSnapshot() =>
      (values: List<int>.of(_values), notes: List<int>.of(_notes));

  @override
  void restoreSnapshot(SudokuSnapshot snapshot) {
    _values = List<int>.of(snapshot.values);
    _notes = List<int>.of(snapshot.notes);
  }

  @override
  void resetBoard() {
    _values = List<int>.of(puzzle.givens);
    _notes = List<int>.filled(puzzle.cellCount, 0);
    _notesMode = false;
  }

  @override
  bool checkSolved() {
    for (var i = 0; i < _values.length; i++) {
      if (_values[i] != puzzle.solution[i]) return false;
    }
    return true;
  }
}
