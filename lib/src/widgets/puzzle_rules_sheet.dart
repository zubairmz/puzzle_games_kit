import 'package:flutter/material.dart';

import '../core/puzzle_rules.dart';

/// Builds custom content for the rules sheet.
typedef PuzzleRulesSheetBuilder = Widget Function(
  BuildContext context,
  PuzzleRules rules,
);

/// Opens [rules] in a modal bottom sheet and completes when it closes.
///
/// The sheet scrolls when the rules are long. Pass [builder] to show your
/// own content instead of [PuzzleRulesSheet].
Future<void> showPuzzleRulesSheet(
  BuildContext context, {
  required PuzzleRules rules,
  PuzzleRulesSheetBuilder? builder,
  bool showDragHandle = true,
  bool useSafeArea = true,
  Color? backgroundColor,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: showDragHandle,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: builder?.call(context, rules) ?? PuzzleRulesSheet(rules: rules),
    ),
  );
}

/// The full rules of a game: a title, then each section's paragraph and
/// bullet points, and a close button.
///
/// Usually shown with [showPuzzleRulesSheet], but it is a plain widget, so
/// it also works on its own screen or in a dialog.
class PuzzleRulesSheet extends StatelessWidget {
  /// Creates a rules view for [rules].
  const PuzzleRulesSheet({
    super.key,
    required this.rules,
    this.showSummary = true,
    this.showCloseButton = true,
    this.header,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 16),
  });

  /// The rules to show.
  final PuzzleRules rules;

  /// Whether to repeat [PuzzleRules.summary] under the title.
  final bool showSummary;

  /// Whether to show the close button at the bottom.
  final bool showCloseButton;

  /// A widget shown above the title, for example an illustration.
  final Widget? header;

  /// Space around the content.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (header != null) ...[header!, const SizedBox(height: 16)],
                  Text(
                    rules.title,
                    style: textTheme.headlineSmall,
                    semanticsLabel: rules.title,
                  ),
                  if (showSummary && rules.summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      rules.summary,
                      style: textTheme.bodyLarge?.copyWith(color: muted),
                    ),
                  ],
                  for (final section in rules.sections)
                    _RulesSection(section: section),
                ],
              ),
            ),
          ),
          if (showCloseButton) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(rules.closeLabel),
            ),
          ],
        ],
      ),
    );
  }
}

class _RulesSection extends StatelessWidget {
  const _RulesSection({required this.section});

  final PuzzleRulesSection section;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final body = section.body;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: textTheme.titleMedium),
          if (body != null && body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(body, style: textTheme.bodyMedium),
          ],
          for (final point in section.points)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Text('•  ', style: textTheme.bodyMedium),
                  ),
                  Expanded(child: Text(point, style: textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
