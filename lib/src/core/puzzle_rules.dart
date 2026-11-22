import 'package:flutter/foundation.dart';

/// One titled part of a game's rules, such as "Goal" or "Controls".
@immutable
class PuzzleRulesSection {
  /// Creates a section with an optional paragraph and bullet points.
  const PuzzleRulesSection({
    required this.title,
    this.body,
    this.points = const [],
  });

  /// The section heading.
  final String title;

  /// A paragraph shown under the heading, if any.
  final String? body;

  /// Bullet points shown after [body].
  final List<String> points;

  /// Returns a copy with the given fields replaced.
  PuzzleRulesSection copyWith({
    String? title,
    String? body,
    List<String>? points,
  }) {
    return PuzzleRulesSection(
      title: title ?? this.title,
      body: body ?? this.body,
      points: points ?? this.points,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PuzzleRulesSection &&
      other.title == title &&
      other.body == body &&
      listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(title, body, Object.hashAll(points));
}

/// Every piece of "how to play" text a game shows: a one or two line
/// [summary] on the game screen, the [buttonLabel] of the button that opens
/// the full rules, and the [sections] of the rules sheet itself.
///
/// Each game ships defaults (`sudokuRules`, `starBattleRules`,
/// `shikakuRules`). Change any part with [copyWith], or build your own, for
/// example to translate it:
///
/// ```dart
/// StarBattleGame(
///   controller: controller,
///   rules: starBattleRules().copyWith(
///     summary: 'One crown per row, column and colour.',
///     buttonLabel: 'Rules',
///   ),
/// );
/// ```
@immutable
class PuzzleRules {
  /// Creates a set of rules.
  const PuzzleRules({
    required this.title,
    required this.summary,
    this.sections = const [],
    this.buttonLabel = 'How to play',
    this.closeLabel = 'Got it',
  });

  /// Heading of the rules sheet, usually the game's name.
  final String title;

  /// The short reminder shown on the game screen.
  final String summary;

  /// The full rules, shown in the rules sheet.
  final List<PuzzleRulesSection> sections;

  /// Text of the button that opens the rules sheet.
  final String buttonLabel;

  /// Text of the button that closes the rules sheet.
  final String closeLabel;

  /// Returns a copy with the given fields replaced.
  PuzzleRules copyWith({
    String? title,
    String? summary,
    List<PuzzleRulesSection>? sections,
    String? buttonLabel,
    String? closeLabel,
  }) {
    return PuzzleRules(
      title: title ?? this.title,
      summary: summary ?? this.summary,
      sections: sections ?? this.sections,
      buttonLabel: buttonLabel ?? this.buttonLabel,
      closeLabel: closeLabel ?? this.closeLabel,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PuzzleRules &&
      other.title == title &&
      other.summary == summary &&
      other.buttonLabel == buttonLabel &&
      other.closeLabel == closeLabel &&
      listEquals(other.sections, sections);

  @override
  int get hashCode => Object.hash(
      title, summary, buttonLabel, closeLabel, Object.hashAll(sections));
}

/// Whether the default rules include keyboard controls: `true` on web and
/// desktop, where a keyboard is usually present.
bool get hasKeyboardByDefault =>
    kIsWeb ||
    switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux =>
        true,
      _ => false,
    };
