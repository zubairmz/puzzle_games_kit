import 'package:flutter/material.dart';

import '../core/puzzle_controller.dart';
import '../theme/puzzle_theme.dart';
import 'puzzle_clock_text.dart';

/// A compact row showing the clock, mistakes and hints of a game, with an
/// optional pause button.
///
/// Each part can be hidden; [trailing] adds your own widgets at the end.
class PuzzleStatusBar extends StatelessWidget {
  /// Creates a status bar for [controller].
  const PuzzleStatusBar({
    super.key,
    required this.controller,
    this.theme,
    this.showClock = true,
    this.showMistakes = true,
    this.showHints = false,
    this.showPauseButton = true,
    this.trailing = const [],
    this.textStyle,
  });

  /// The game to describe.
  final PuzzleController<Object?, Object?> controller;

  /// Overrides the inherited [PuzzleTheme].
  final PuzzleTheme? theme;

  /// Whether to show the play time.
  final bool showClock;

  /// Whether to show the mistake count (and limit, if any).
  final bool showMistakes;

  /// Whether to show hints used (and remaining, if limited).
  final bool showHints;

  /// Whether to show a pause / resume button next to the clock.
  final bool showPauseButton;

  /// Extra widgets placed at the end of the row.
  final List<Widget> trailing;

  /// Style for the labels; defaults to `titleSmall`.
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final puzzleTheme = PuzzleTheme.of(context, theme);
    final style = textStyle ?? Theme.of(context).textTheme.titleSmall;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final limit = controller.maxMistakes;
        final hintsLeft = controller.hintsRemaining;
        return Row(
          children: [
            if (showClock) ...[
              Icon(Icons.timer_outlined, size: 18, color: style?.color),
              const SizedBox(width: 4),
              PuzzleClockText(controller: controller, style: style),
              if (showPauseButton && !controller.isFinished)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: controller.isPaused ? 'Resume' : 'Pause',
                  icon: Icon(
                    controller.isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                  onPressed: controller.isPaused
                      ? controller.resume
                      : controller.pause,
                ),
            ],
            const Spacer(),
            if (showMistakes) ...[
              Icon(
                Icons.close_rounded,
                size: 18,
                color: controller.mistakes > 0
                    ? puzzleTheme.errorColor
                    : style?.color,
              ),
              const SizedBox(width: 2),
              Text(
                limit == null
                    ? '${controller.mistakes}'
                    : '${controller.mistakes}/$limit',
                style: style,
              ),
            ],
            if (showHints) ...[
              const SizedBox(width: 12),
              Icon(Icons.lightbulb_outline_rounded,
                  size: 18, color: style?.color),
              const SizedBox(width: 2),
              Text(
                hintsLeft == null
                    ? '${controller.hintsUsed}'
                    : '$hintsLeft left',
                style: style,
              ),
            ],
            ...trailing,
          ],
        );
      },
    );
  }
}
