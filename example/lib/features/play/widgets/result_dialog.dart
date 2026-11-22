import 'package:flutter/material.dart';
import 'package:puzzle_games/puzzle_games.dart';

/// Shows a finished game's [result].
///
/// A real app would also save `result.toJson()` here for stats, streaks
/// and leaderboards.
Future<void> showResultDialog(
  BuildContext context,
  PuzzleResult result, {
  required VoidCallback onPlayAgain,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => ResultDialog(
      result: result,
      onHome: () {
        Navigator.of(dialogContext).pop();
        Navigator.of(context).pop();
      },
      onPlayAgain: () {
        Navigator.of(dialogContext).pop();
        onPlayAgain();
      },
    ),
  );
}

/// The time, mistakes, hints and moves of a finished game.
class ResultDialog extends StatelessWidget {
  /// Creates a result dialog.
  const ResultDialog({
    super.key,
    required this.result,
    required this.onHome,
    required this.onPlayAgain,
  });

  /// The finished game.
  final PuzzleResult result;

  /// Called by the "Home" button.
  final VoidCallback onHome;

  /// Called by the "Play again" button.
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final seed = result.seed;
    return AlertDialog(
      icon: Icon(result.solved
          ? Icons.emoji_events_outlined
          : Icons.sentiment_dissatisfied_outlined),
      title: Text(result.solved ? 'Solved!' : 'Game over'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ResultRow('Time', formatPuzzleDuration(result.elapsed)),
          _ResultRow('Mistakes', '${result.mistakes}'),
          _ResultRow('Hints', '${result.hintsUsed}'),
          _ResultRow('Moves', '${result.moves}'),
          if (seed != null) _ResultRow('Seed', '$seed'),
        ],
      ),
      actions: [
        TextButton(onPressed: onHome, child: const Text('Home')),
        FilledButton(onPressed: onPlayAgain, child: const Text('Play again')),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
