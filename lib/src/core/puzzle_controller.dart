import 'package:flutter/foundation.dart';

import 'puzzle_difficulty.dart';
import 'puzzle_result.dart';

/// Base class for every game's controller.
///
/// Holds what all games share: the play clock (with pause and resume),
/// counters for moves, mistakes and hints, an undo history, and finishing
/// with a [PuzzleResult]. Controllers are [ChangeNotifier]s, so any widget
/// (the boards in this package or your own UI) can listen to them.
///
/// [S] is the game's snapshot type used for undo.
abstract class PuzzleController<P, S> extends ChangeNotifier {
  /// Creates a controller for [puzzle].
  PuzzleController({
    required this.puzzle,
    this.onFinished,
    this.maxMistakes,
    this.maxHints,
    Duration initialElapsed = Duration.zero,
    bool startClock = true,
  }) : _elapsedBefore = initialElapsed {
    if (startClock) _stopwatch.start();
  }

  /// The puzzle being played.
  final P puzzle;

  /// Called once when the game finishes, solved or not.
  final ValueChanged<PuzzleResult>? onFinished;

  /// Ends the game (unsolved) when [mistakes] reaches this. `null` means
  /// unlimited.
  final int? maxMistakes;

  /// How many hints may be used. `null` means unlimited; `0` disables hints.
  final int? maxHints;

  /// Identifier used in [PuzzleResult.gameId].
  String get gameId;

  /// Difficulty the puzzle was generated with, if any.
  PuzzleDifficulty? get difficulty;

  /// Seed the puzzle was generated from, if any.
  int? get seed;

  /// Extra values reported in [PuzzleResult.details].
  Map<String, Object?> get resultDetails => const {};

  final Stopwatch _stopwatch = Stopwatch();
  final Duration _elapsedBefore;
  final List<S> _undoStack = [];

  int _moves = 0;
  int _mistakes = 0;
  int _hintsUsed = 0;
  bool _finished = false;
  bool _solved = false;
  PuzzleResult? _result;
  bool _disposed = false;

  /// Time played so far, excluding paused time.
  Duration get elapsed => _elapsedBefore + _stopwatch.elapsed;

  /// Whether the clock is stopped by [pause] (or never started).
  bool get isPaused => !_stopwatch.isRunning && !_finished;

  /// Number of moves made.
  int get moves => _moves;

  /// Number of wrong moves made.
  int get mistakes => _mistakes;

  /// Number of hints used.
  int get hintsUsed => _hintsUsed;

  /// Hints left, or `null` when unlimited.
  int? get hintsRemaining =>
      maxHints == null ? null : (maxHints! - _hintsUsed).clamp(0, maxHints!);

  /// Whether another hint may be used now.
  bool get canHint =>
      !_finished && (maxHints == null || _hintsUsed < maxHints!);

  /// Whether the game has ended (solved or out of mistakes).
  bool get isFinished => _finished;

  /// Whether the puzzle was solved.
  bool get isSolved => _solved;

  /// The result, once [isFinished].
  PuzzleResult? get result => _result;

  /// Whether input is currently accepted.
  bool get acceptsInput => !_finished;

  /// Whether [undo] has anything to undo.
  bool get canUndo => !_finished && _undoStack.isNotEmpty;

  /// Stops the clock, e.g. when the app goes to the background.
  void pause() {
    if (_finished || !_stopwatch.isRunning) return;
    _stopwatch.stop();
    notifyListeners();
  }

  /// Restarts the clock after [pause].
  void resume() {
    if (_finished || _stopwatch.isRunning) return;
    _stopwatch.start();
    notifyListeners();
  }

  /// Reverts the last move. Counters (mistakes, hints) are not reverted.
  void undo() {
    if (!canUndo) return;
    restoreSnapshot(_undoStack.removeLast());
    notifyListeners();
  }

  /// Clears the board back to its starting state and restarts the clock.
  /// Counters are reset too.
  void restart() {
    _undoStack.clear();
    _moves = 0;
    _mistakes = 0;
    _hintsUsed = 0;
    _finished = false;
    _solved = false;
    _result = null;
    resetBoard();
    _stopwatch
      ..reset()
      ..start();
    notifyListeners();
  }

  /// A copy of the board state, for undo.
  @protected
  S takeSnapshot();

  /// Restores a state from [takeSnapshot].
  @protected
  void restoreSnapshot(S snapshot);

  /// Resets the board to the puzzle's starting state.
  @protected
  void resetBoard();

  /// Whether the current board is a complete, correct solution.
  @protected
  bool checkSolved();

  /// Records the current state for undo. Call before changing the board.
  @protected
  void pushUndo() => _undoStack.add(takeSnapshot());

  /// Counts a move.
  @protected
  void countMove() => _moves++;

  /// Counts a hint.
  @protected
  void countHint() => _hintsUsed++;

  /// Counts a mistake, ending the game if [maxMistakes] is reached.
  @protected
  void countMistake() {
    _mistakes++;
    if (maxMistakes != null && _mistakes >= maxMistakes!) {
      _finish(solved: false);
    }
  }

  /// Finishes the game if the board is solved. Call after every change,
  /// then call [notifyListeners].
  @protected
  void checkCompletion() {
    if (!_finished && checkSolved()) _finish(solved: true);
  }

  /// Ends the game now, unsolved (for example a "give up" button).
  void giveUp() {
    if (_finished) return;
    _finish(solved: false);
    notifyListeners();
  }

  void _finish({required bool solved}) {
    _finished = true;
    _solved = solved;
    _stopwatch.stop();
    _result = PuzzleResult(
      gameId: gameId,
      solved: solved,
      elapsed: elapsed,
      completedAt: DateTime.now(),
      difficulty: difficulty,
      seed: seed,
      mistakes: _mistakes,
      hintsUsed: _hintsUsed,
      moves: _moves,
      details: resultDetails,
    );
    final result = _result!;
    // Defer so listeners see a consistent state before the callback runs.
    Future.microtask(() {
      if (!_disposed) onFinished?.call(result);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _stopwatch.stop();
    super.dispose();
  }
}
