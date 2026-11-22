import 'package:flutter/material.dart';
import 'package:puzzle_games/puzzle_games.dart';

import 'widgets/result_dialog.dart';

/// Creates a game controller for [seed] that reports to [onFinished].
typedef PuzzleControllerFactory<C> = C Function(
  int? seed,
  ValueChanged<PuzzleResult> onFinished,
);

/// One screen for every game: owns the controller, shows the result when
/// the game ends and starts a fresh puzzle on "Play again".
///
/// Each game screen only says how to create its controller and which game
/// widget to show, so the lifecycle code lives in one place.
class PlayPage<C extends PuzzleController<Object?, Object?>>
    extends StatefulWidget {
  /// Creates a play page.
  const PlayPage({
    super.key,
    required this.title,
    required this.createController,
    required this.gameBuilder,
    this.seed,
    this.rules,
  });

  /// The app bar title for the current controller.
  final String Function(C controller) title;

  /// Creates the controller for each new puzzle.
  final PuzzleControllerFactory<C> createController;

  /// Builds the game for the current controller.
  final Widget Function(BuildContext context, C controller) gameBuilder;

  /// Seed of the first puzzle (a daily puzzle), or `null` for a random one.
  final int? seed;

  /// When set, a help button in the app bar opens these rules. Useful when
  /// the game itself hides its "How to play" button.
  final PuzzleRules? rules;

  @override
  State<PlayPage<C>> createState() => _PlayPageState<C>();
}

class _PlayPageState<C extends PuzzleController<Object?, Object?>>
    extends State<PlayPage<C>> {
  late C _controller = widget.createController(widget.seed, _onFinished);

  void _onFinished(PuzzleResult result) {
    if (!mounted) return;
    showResultDialog(context, result, onPlayAgain: _playAgain);
  }

  /// "Play again" always starts a new random puzzle.
  void _playAgain() {
    final previous = _controller;
    setState(() => _controller = widget.createController(null, _onFinished));
    previous.dispose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rules = widget.rules;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title(_controller)),
        actions: [
          if (rules != null) PuzzleRulesButton(rules: rules, iconOnly: true),
          IconButton(
            tooltip: 'Restart',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _controller.restart,
          ),
        ],
      ),
      body: SafeArea(
        child: KeyedSubtree(
          key: ObjectKey(_controller),
          child: widget.gameBuilder(context, _controller),
        ),
      ),
    );
  }
}
