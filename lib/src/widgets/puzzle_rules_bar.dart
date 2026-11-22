import 'package:flutter/material.dart';

import '../core/puzzle_rules.dart';
import 'puzzle_rules_button.dart';
import 'puzzle_rules_sheet.dart';

/// The rules reminder on a game screen: the one or two line
/// [PuzzleRules.summary] and a [PuzzleRulesButton] that opens the full
/// rules.
///
/// Either part can be hidden. When both are hidden it takes no space.
class PuzzleRulesBar extends StatelessWidget {
  /// Creates a rules bar for [rules].
  const PuzzleRulesBar({
    super.key,
    required this.rules,
    this.showSummary = true,
    this.showButton = true,
    this.summaryStyle,
    this.textAlign = TextAlign.center,
    this.maxLines = 2,
    this.button,
    this.sheetBuilder,
  });

  /// The text to show.
  final PuzzleRules rules;

  /// Whether to show [PuzzleRules.summary].
  final bool showSummary;

  /// Whether to show the button that opens the full rules.
  final bool showButton;

  /// Style of the summary; defaults to `bodyMedium` in a muted colour.
  final TextStyle? summaryStyle;

  /// Alignment of the summary.
  final TextAlign textAlign;

  /// Lines the summary may take before it is cut off.
  final int maxLines;

  /// Replaces the default [PuzzleRulesButton].
  final Widget? button;

  /// Custom content for the rules sheet opened by the default button.
  final PuzzleRulesSheetBuilder? sheetBuilder;

  @override
  Widget build(BuildContext context) {
    final summary = showSummary && rules.summary.isNotEmpty;
    if (!summary && !showButton) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (summary)
          Text(
            rules.summary,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: summaryStyle ??
                theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        if (showButton)
          button ??
              PuzzleRulesButton(
                rules: rules,
                sheetBuilder: sheetBuilder,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
      ],
    );
  }
}
