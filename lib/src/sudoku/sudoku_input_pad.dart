import 'package:flutter/material.dart';

import '../theme/puzzle_theme.dart';
import 'sudoku_controller.dart';

/// Number buttons and actions (undo, erase, notes, hint) for a
/// [SudokuController].
///
/// Every action can be hidden. [numberButtonBuilder] replaces the number
/// buttons entirely if you want your own design.
class SudokuInputPad extends StatelessWidget {
  /// Creates an input pad for [controller].
  const SudokuInputPad({
    super.key,
    required this.controller,
    this.theme,
    this.showUndo = true,
    this.showErase = true,
    this.showNotes = true,
    this.showHint = true,
    this.showRemainingCounts = true,
    this.hideCompletedNumbers = false,
    this.spacing = 8,
    this.numberButtonBuilder,
  });

  /// The game to control.
  final SudokuController controller;

  /// Overrides the inherited [PuzzleTheme].
  final PuzzleTheme? theme;

  /// Show the undo action.
  final bool showUndo;

  /// Show the erase action.
  final bool showErase;

  /// Show the notes toggle (also needs `allowNotes` on the controller).
  final bool showNotes;

  /// Show the hint action (hidden automatically when `maxHints` is 0).
  final bool showHint;

  /// Show how many of each number are still to be placed.
  final bool showRemainingCounts;

  /// Disable a number once all its copies are placed correctly.
  final bool hideCompletedNumbers;

  /// Gap between buttons.
  final double spacing;

  /// Builds a custom number button. `onPressed` is `null` when disabled.
  final Widget Function(
    BuildContext context,
    int value,
    int remaining,
    VoidCallback? onPressed,
  )? numberButtonBuilder;

  @override
  Widget build(BuildContext context) {
    final puzzleTheme = PuzzleTheme.of(context, theme);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final enabled = c.acceptsInput;
        final actions = <Widget>[
          if (showUndo)
            _ActionButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              onPressed: c.canUndo ? c.undo : null,
            ),
          if (showErase)
            _ActionButton(
              icon: Icons.backspace_outlined,
              label: 'Erase',
              onPressed: enabled && c.selected != null ? c.erase : null,
            ),
          if (showNotes && c.allowNotes)
            _ActionButton(
              icon: Icons.edit_note_rounded,
              label: c.notesMode ? 'Notes on' : 'Notes',
              active: c.notesMode,
              activeColor: puzzleTheme.entryTextColor,
              onPressed: enabled ? c.toggleNotesMode : null,
            ),
          if (showHint && c.maxHints != 0)
            _ActionButton(
              icon: Icons.lightbulb_outline_rounded,
              label: c.hintsRemaining == null
                  ? 'Hint'
                  : 'Hint (${c.hintsRemaining})',
              onPressed: c.canHint ? c.hint : null,
            ),
        ];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (actions.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: actions,
              ),
            if (actions.isNotEmpty) SizedBox(height: spacing),
            Row(
              children: [
                for (var v = 1; v <= c.size; v++) ...[
                  if (v > 1) SizedBox(width: spacing / 2),
                  Expanded(child: _numberButton(context, puzzleTheme, v)),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _numberButton(BuildContext context, PuzzleTheme theme, int value) {
    final c = controller;
    final remaining = (c.size - c.countOf(value)).clamp(0, c.size);
    final complete = hideCompletedNumbers && c.isValueComplete(value);
    final onPressed = c.acceptsInput && !complete ? () => c.input(value) : null;

    final custom = numberButtonBuilder;
    if (custom != null) return custom(context, value, remaining, onPressed);

    final textTheme = Theme.of(context).textTheme;
    final color = c.notesMode ? theme.noteTextColor : theme.entryTextColor;
    return Semantics(
      button: true,
      label: c.notesMode ? 'Note $value' : 'Enter $value',
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 10),
          minimumSize: const Size(0, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: theme.highlightColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: (theme.textStyle ?? textTheme.headlineSmall)?.copyWith(
                fontSize: textTheme.headlineSmall?.fontSize,
                fontWeight: FontWeight.w600,
                color: onPressed == null ? color.withValues(alpha: 0.3) : color,
              ),
            ),
            if (showRemainingCounts)
              Text(
                '$remaining',
                style: textTheme.labelSmall?.copyWith(
                  color: theme.noteTextColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.activeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : null;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: color),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
