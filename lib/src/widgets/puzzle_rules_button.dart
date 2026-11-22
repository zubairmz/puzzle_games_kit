import 'package:flutter/material.dart';

import '../core/puzzle_rules.dart';
import 'puzzle_rules_sheet.dart';

/// A button that opens a game's full rules.
///
/// Shows [PuzzleRules.buttonLabel] next to a help icon, or only the icon
/// when [iconOnly] is set (the label becomes its tooltip). Tapping it opens
/// [showPuzzleRulesSheet] unless you pass [onPressed], for example to open
/// your own rules screen.
class PuzzleRulesButton extends StatelessWidget {
  /// Creates a rules button for [rules].
  const PuzzleRulesButton({
    super.key,
    required this.rules,
    this.icon = const Icon(Icons.help_outline_rounded),
    this.iconOnly = false,
    this.style,
    this.onPressed,
    this.sheetBuilder,
  });

  /// The rules to open.
  final PuzzleRules rules;

  /// The button's icon; `null` shows the label only.
  final Widget? icon;

  /// Shows only [icon], with the label as a tooltip.
  final bool iconOnly;

  /// Style of the button.
  final ButtonStyle? style;

  /// Replaces opening the rules sheet.
  final VoidCallback? onPressed;

  /// Custom content for the rules sheet.
  final PuzzleRulesSheetBuilder? sheetBuilder;

  void _open(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
      return;
    }
    showPuzzleRulesSheet(context, rules: rules, builder: sheetBuilder);
  }

  @override
  Widget build(BuildContext context) {
    final label = Text(rules.buttonLabel);
    if (iconOnly) {
      return IconButton(
        tooltip: rules.buttonLabel,
        style: style,
        icon: icon ?? const Icon(Icons.help_outline_rounded),
        onPressed: () => _open(context),
      );
    }
    if (icon == null) {
      return TextButton(
        style: style,
        onPressed: () => _open(context),
        child: label,
      );
    }
    return TextButton.icon(
      style: style,
      icon: icon,
      label: label,
      onPressed: () => _open(context),
    );
  }
}
