import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Colours, line widths and text styles used by every puzzle widget.
///
/// Resolution order for a widget's theme:
/// 1. the `theme` argument passed to the widget, if any;
/// 2. a [PuzzleTheme] registered in `ThemeData.extensions`;
/// 3. [PuzzleTheme.fromColorScheme] of the ambient `ColorScheme`.
///
/// So with no setup at all, puzzles follow your app's colours, including
/// dark mode. To customise globally, register an extension:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [PuzzleTheme.fromColorScheme(scheme).copyWith(
///       selectedCellColor: Colors.amber.shade100,
///     )],
///   ),
/// );
/// ```
@immutable
class PuzzleTheme extends ThemeExtension<PuzzleTheme> {
  /// Creates a theme with every value given explicitly. Most apps start from
  /// [PuzzleTheme.fromColorScheme] and use [copyWith] instead.
  const PuzzleTheme({
    required this.boardColor,
    required this.cellColor,
    required this.gridLineColor,
    required this.blockLineColor,
    required this.selectedCellColor,
    required this.highlightColor,
    required this.sameValueColor,
    required this.givenTextColor,
    required this.entryTextColor,
    required this.noteTextColor,
    required this.errorColor,
    required this.successColor,
    required this.markerColor,
    required this.regionColors,
    this.gridLineWidth = 1,
    this.blockLineWidth = 2.5,
    this.boardRadius = const BorderRadius.all(Radius.circular(12)),
    this.cellRadius = 0,
    this.textStyle,
    this.animationDuration = const Duration(milliseconds: 180),
  });

  /// Derives a theme from [scheme] that suits both light and dark modes.
  factory PuzzleTheme.fromColorScheme(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    final base = dark ? _regionPaletteDark : _regionPaletteLight;
    return PuzzleTheme(
      boardColor: scheme.outline,
      cellColor: scheme.surface,
      gridLineColor: scheme.outlineVariant,
      blockLineColor: scheme.onSurface,
      selectedCellColor: scheme.primaryContainer,
      highlightColor: scheme.primary.withValues(alpha: dark ? 0.16 : 0.08),
      sameValueColor: scheme.primary.withValues(alpha: dark ? 0.30 : 0.18),
      givenTextColor: scheme.onSurface,
      entryTextColor: scheme.primary,
      noteTextColor: scheme.onSurfaceVariant,
      errorColor: scheme.error,
      successColor: dark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32),
      markerColor: scheme.onSurface,
      regionColors: base,
    );
  }

  /// The theme for [context], following the resolution order above.
  static PuzzleTheme of(BuildContext context, [PuzzleTheme? override]) {
    if (override != null) return override;
    final theme = Theme.of(context);
    return theme.extension<PuzzleTheme>() ??
        PuzzleTheme.fromColorScheme(theme.colorScheme);
  }

  /// Colour of the board frame and the gaps behind cells.
  final Color boardColor;

  /// Background of an ordinary cell.
  final Color cellColor;

  /// Thin lines between cells.
  final Color gridLineColor;

  /// Thick lines: Sudoku boxes, region and rectangle borders.
  final Color blockLineColor;

  /// Background of the selected cell.
  final Color selectedCellColor;

  /// Background of cells related to the selection (same row, column, box).
  final Color highlightColor;

  /// Background of cells holding the same value as the selection.
  final Color sameValueColor;

  /// Text colour of the puzzle's starting clues.
  final Color givenTextColor;

  /// Text colour of the player's entries.
  final Color entryTextColor;

  /// Text colour of pencil notes.
  final Color noteTextColor;

  /// Colour for mistakes and rule conflicts.
  final Color errorColor;

  /// Accent shown when a puzzle is solved.
  final Color successColor;

  /// Colour of markers such as stars and crosses.
  final Color markerColor;

  /// Fill colours for regions (Star Battle) and rectangles (Shikaku),
  /// used in order and repeated if there are more regions than colours.
  final List<Color> regionColors;

  /// Width of the thin grid lines.
  final double gridLineWidth;

  /// Width of the thick block lines.
  final double blockLineWidth;

  /// Rounding of the board's outer corners.
  final BorderRadius boardRadius;

  /// Rounding of individual cells (0 for a classic grid).
  final double cellRadius;

  /// Base text style (font family, weight). Sizes are computed per cell.
  final TextStyle? textStyle;

  /// Duration of cell colour transitions. Use [Duration.zero] to disable.
  final Duration animationDuration;

  /// The region colour for region [index].
  Color regionColor(int index) => regionColors[index % regionColors.length];

  @override
  PuzzleTheme copyWith({
    Color? boardColor,
    Color? cellColor,
    Color? gridLineColor,
    Color? blockLineColor,
    Color? selectedCellColor,
    Color? highlightColor,
    Color? sameValueColor,
    Color? givenTextColor,
    Color? entryTextColor,
    Color? noteTextColor,
    Color? errorColor,
    Color? successColor,
    Color? markerColor,
    List<Color>? regionColors,
    double? gridLineWidth,
    double? blockLineWidth,
    BorderRadius? boardRadius,
    double? cellRadius,
    TextStyle? textStyle,
    Duration? animationDuration,
  }) {
    return PuzzleTheme(
      boardColor: boardColor ?? this.boardColor,
      cellColor: cellColor ?? this.cellColor,
      gridLineColor: gridLineColor ?? this.gridLineColor,
      blockLineColor: blockLineColor ?? this.blockLineColor,
      selectedCellColor: selectedCellColor ?? this.selectedCellColor,
      highlightColor: highlightColor ?? this.highlightColor,
      sameValueColor: sameValueColor ?? this.sameValueColor,
      givenTextColor: givenTextColor ?? this.givenTextColor,
      entryTextColor: entryTextColor ?? this.entryTextColor,
      noteTextColor: noteTextColor ?? this.noteTextColor,
      errorColor: errorColor ?? this.errorColor,
      successColor: successColor ?? this.successColor,
      markerColor: markerColor ?? this.markerColor,
      regionColors: regionColors ?? this.regionColors,
      gridLineWidth: gridLineWidth ?? this.gridLineWidth,
      blockLineWidth: blockLineWidth ?? this.blockLineWidth,
      boardRadius: boardRadius ?? this.boardRadius,
      cellRadius: cellRadius ?? this.cellRadius,
      textStyle: textStyle ?? this.textStyle,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }

  @override
  PuzzleTheme lerp(covariant PuzzleTheme? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    final regions = t < 0.5 ? regionColors : other.regionColors;
    return PuzzleTheme(
      boardColor: c(boardColor, other.boardColor),
      cellColor: c(cellColor, other.cellColor),
      gridLineColor: c(gridLineColor, other.gridLineColor),
      blockLineColor: c(blockLineColor, other.blockLineColor),
      selectedCellColor: c(selectedCellColor, other.selectedCellColor),
      highlightColor: c(highlightColor, other.highlightColor),
      sameValueColor: c(sameValueColor, other.sameValueColor),
      givenTextColor: c(givenTextColor, other.givenTextColor),
      entryTextColor: c(entryTextColor, other.entryTextColor),
      noteTextColor: c(noteTextColor, other.noteTextColor),
      errorColor: c(errorColor, other.errorColor),
      successColor: c(successColor, other.successColor),
      markerColor: c(markerColor, other.markerColor),
      regionColors: regions,
      gridLineWidth: lerpDouble(gridLineWidth, other.gridLineWidth, t)!,
      blockLineWidth: lerpDouble(blockLineWidth, other.blockLineWidth, t)!,
      boardRadius: BorderRadius.lerp(boardRadius, other.boardRadius, t)!,
      cellRadius: lerpDouble(cellRadius, other.cellRadius, t)!,
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      animationDuration: t < 0.5 ? animationDuration : other.animationDuration,
    );
  }
}

const List<Color> _regionPaletteLight = [
  Color(0xFFFFD6A5),
  Color(0xFFCAFFBF),
  Color(0xFF9BF6FF),
  Color(0xFFBDB2FF),
  Color(0xFFFFADAD),
  Color(0xFFFDFFB6),
  Color(0xFFA0C4FF),
  Color(0xFFFFC6FF),
  Color(0xFFD4E09B),
  Color(0xFFB8E0D2),
  Color(0xFFF6BD60),
  Color(0xFFE2CFC4),
];

const List<Color> _regionPaletteDark = [
  Color(0xFF7A5A2E),
  Color(0xFF3F6B37),
  Color(0xFF2E6670),
  Color(0xFF4E4682),
  Color(0xFF7A3B3B),
  Color(0xFF6E6F2E),
  Color(0xFF34507A),
  Color(0xFF6E3B6E),
  Color(0xFF55602F),
  Color(0xFF3B6356),
  Color(0xFF7A5A1C),
  Color(0xFF5E4C42),
];
