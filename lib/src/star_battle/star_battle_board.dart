import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/cell_position.dart';
import '../theme/puzzle_theme.dart';
import 'star_battle_controller.dart';

/// Everything needed to draw one Star Battle cell, passed to a
/// [StarBattleMarkerBuilder].
@immutable
class StarBattleCellData {
  /// Creates cell data.
  const StarBattleCellData({
    required this.position,
    required this.region,
    required this.mark,
    required this.isBlocked,
    required this.hasConflict,
    required this.isWrong,
  });

  /// The cell's position.
  final CellPosition position;

  /// The cell's region id.
  final int region;

  /// What the player placed here.
  final StarBattleMark mark;

  /// Empty, but ruled out by a placed star (an automatic cross).
  final bool isBlocked;

  /// A star that breaks a rule.
  final bool hasConflict;

  /// A star that isn't in the solution (only when mistakes are revealed).
  final bool isWrong;
}

/// Draws a cell's marker (star, cross, automatic cross). Return
/// `SizedBox.shrink()` for nothing. [size] is the cell's side length.
typedef StarBattleMarkerBuilder = Widget Function(
  BuildContext context,
  StarBattleCellData cell,
  PuzzleTheme theme,
  double size,
);

/// An interactive Star Battle grid for a [StarBattleController].
///
/// Tap a cell to step through [StarBattleController.tapCycle]; with
/// [enableDragToCross], drag from an empty cell to cross out several cells
/// (or from a crossed cell to clear them). With [enableKeyboard], arrows
/// move a cursor, Space/Enter taps, `S` places a star, `X` a cross,
/// Backspace clears and Ctrl/Cmd+Z undoes.
class StarBattleBoard extends StatefulWidget {
  /// Creates a board for [controller].
  const StarBattleBoard({
    super.key,
    required this.controller,
    this.theme,
    this.showAutoCrosses = true,
    this.enableDragToCross = true,
    this.enableKeyboard = true,
    this.autofocus = false,
    this.markerBuilder,
  });

  /// The game to show and control.
  final StarBattleController controller;

  /// Overrides the inherited [PuzzleTheme].
  final PuzzleTheme? theme;

  /// Show faint crosses in cells ruled out by placed stars.
  final bool showAutoCrosses;

  /// Allow dragging across cells to place or clear crosses.
  final bool enableDragToCross;

  /// Accept keyboard input (useful on desktop and web).
  final bool enableKeyboard;

  /// Focus the board for keyboard input when first shown.
  final bool autofocus;

  /// Replaces the default star and cross drawing, e.g. with a crown icon.
  final StarBattleMarkerBuilder? markerBuilder;

  @override
  State<StarBattleBoard> createState() => _StarBattleBoardState();
}

class _StarBattleBoardState extends State<StarBattleBoard> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'StarBattleBoard');
  CellPosition? _cursor;
  bool _hasFocus = false;

  /// The cursor is only drawn once the keyboard is used, not after taps.
  bool _usingKeyboard = false;
  StarBattleMark? _dragMark;
  CellPosition? _lastDragCell;

  StarBattleController get _c => widget.controller;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Maps a touch (relative to the board's outer edge, frame included) to a
  /// cell.
  CellPosition? _cellAt(Offset local, double side) {
    final n = _c.size;
    final frame = PuzzleTheme.of(context, widget.theme).blockLineWidth;
    final inner = side - frame * 2;
    final row = ((local.dy - frame) / inner * n).floor();
    final col = ((local.dx - frame) / inner * n).floor();
    if (row < 0 || col < 0 || row >= n || col >= n) return null;
    return CellPosition(row, col);
  }

  void _onTapUp(TapUpDetails details, double side) {
    final cell = _cellAt(details.localPosition, side);
    if (cell == null) return;
    if (widget.enableKeyboard) _focusNode.requestFocus();
    setState(() {
      _cursor = cell;
      _usingKeyboard = false;
    });
    _c.tap(cell.row, cell.col);
  }

  void _onPanStart(DragStartDetails details, double side) {
    final cell = _cellAt(details.localPosition, side);
    if (cell == null) return;
    final current = _c.markAt(cell.row, cell.col);
    if (current == StarBattleMark.star) return;
    _dragMark = current == StarBattleMark.cross
        ? StarBattleMark.empty
        : StarBattleMark.cross;
    _c.beginStroke();
    _paint(cell);
  }

  void _onPanUpdate(DragUpdateDetails details, double side) {
    if (_dragMark == null) return;
    final cell = _cellAt(details.localPosition, side);
    if (cell != null && cell != _lastDragCell) _paint(cell);
  }

  void _onPanEnd() {
    if (_dragMark == null) return;
    _c.endStroke();
    _dragMark = null;
    _lastDragCell = null;
  }

  void _paint(CellPosition cell) {
    _lastDragCell = cell;
    if (_c.markAt(cell.row, cell.col) != StarBattleMark.star) {
      _c.setMark(cell.row, cell.col, _dragMark!);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_usingKeyboard) setState(() => _usingKeyboard = true);
    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    if ((keyboard.isControlPressed || keyboard.isMetaPressed) &&
        key == LogicalKeyboardKey.keyZ) {
      _c.undo();
      return KeyEventResult.handled;
    }
    final n = _c.size;
    final cursor = _cursor ?? const CellPosition(0, 0);
    void move(int dr, int dc) => setState(() =>
        _cursor = CellPosition((cursor.row + dr) % n, (cursor.col + dc) % n));

    if (key == LogicalKeyboardKey.arrowUp) {
      move(-1, 0);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      move(1, 0);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      move(0, -1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      move(0, 1);
    } else if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.enter) {
      _c.tap(cursor.row, cursor.col);
    } else if (key == LogicalKeyboardKey.keyS) {
      _c.setMark(cursor.row, cursor.col, StarBattleMark.star);
    } else if (key == LogicalKeyboardKey.keyX) {
      _c.setMark(cursor.row, cursor.col, StarBattleMark.cross);
    } else if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _c.setMark(cursor.row, cursor.col, StarBattleMark.empty);
    } else {
      return KeyEventResult.ignored;
    }
    _cursor ??= cursor;
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = PuzzleTheme.of(context, widget.theme);
    return AspectRatio(
      aspectRatio: 1,
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        canRequestFocus: widget.enableKeyboard,
        onFocusChange: (focused) => setState(() => _hasFocus = focused),
        onKeyEvent: widget.enableKeyboard ? _onKey : null,
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final side =
                  math.min(constraints.maxWidth, constraints.maxHeight);
              return _buildBoard(context, theme, side);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context, PuzzleTheme theme, double side) {
    final n = _c.size;
    final cellSize = side / n;
    final frameColor = _c.isSolved ? theme.successColor : theme.blockLineColor;
    final regions = _c.puzzle.regions;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Start a drag from the cell the finger touched, not where the drag
      // was recognised a few pixels later.
      dragStartBehavior: DragStartBehavior.down,
      onTapUp: (d) => _onTapUp(d, side),
      onPanStart: widget.enableDragToCross ? (d) => _onPanStart(d, side) : null,
      onPanUpdate:
          widget.enableDragToCross ? (d) => _onPanUpdate(d, side) : null,
      onPanEnd: widget.enableDragToCross ? (_) => _onPanEnd() : null,
      onPanCancel: widget.enableDragToCross ? _onPanEnd : null,
      child: Container(
        width: side,
        height: side,
        decoration: BoxDecoration(
          borderRadius: theme.boardRadius,
          border: Border.all(color: frameColor, width: theme.blockLineWidth),
        ),
        child: ClipRRect(
          borderRadius: theme.boardRadius,
          child: Stack(
            children: [
              Column(
                children: [
                  for (var r = 0; r < n; r++)
                    Expanded(
                      child: Row(
                        children: [
                          for (var col = 0; col < n; col++)
                            Expanded(
                              child:
                                  _buildCell(context, theme, r, col, cellSize),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RegionBorderPainter(
                      size: n,
                      regions: regions,
                      thinColor: theme.gridLineColor,
                      thickColor: theme.blockLineColor,
                      thinWidth: theme.gridLineWidth,
                      thickWidth: theme.blockLineWidth,
                      cursor: _hasFocus && _usingKeyboard ? _cursor : null,
                      cursorColor: theme.entryTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    PuzzleTheme theme,
    int row,
    int col,
    double cellSize,
  ) {
    final mark = _c.markAt(row, col);
    final region = _c.puzzle.regionAt(row, col);
    final data = StarBattleCellData(
      position: CellPosition(row, col),
      region: region,
      mark: mark,
      isBlocked: widget.showAutoCrosses && _c.isBlocked(row, col),
      hasConflict: _c.hasConflict(row, col),
      isWrong: _c.isWrong(row, col),
    );
    final error = data.hasConflict || data.isWrong;
    final base = theme.regionColor(region);
    final background = error
        ? Color.alphaBlend(theme.errorColor.withValues(alpha: 0.35), base)
        : base;

    return Semantics(
      button: true,
      label: 'Row ${row + 1}, column ${col + 1}, region ${region + 1}',
      value: switch (mark) {
        StarBattleMark.star => 'star',
        StarBattleMark.cross => 'cross',
        StarBattleMark.empty => 'empty',
      },
      child: AnimatedContainer(
        duration: theme.animationDuration,
        color: background,
        alignment: Alignment.center,
        child: widget.markerBuilder?.call(context, data, theme, cellSize) ??
            _defaultMarker(data, theme, cellSize, error),
      ),
    );
  }

  Widget _defaultMarker(
    StarBattleCellData data,
    PuzzleTheme theme,
    double cellSize,
    bool error,
  ) {
    switch (data.mark) {
      case StarBattleMark.star:
        return Icon(
          Icons.star_rounded,
          size: cellSize * 0.72,
          color: error ? theme.errorColor : theme.markerColor,
        );
      case StarBattleMark.cross:
        return Icon(
          Icons.close_rounded,
          size: cellSize * 0.42,
          color: theme.markerColor.withValues(alpha: 0.7),
        );
      case StarBattleMark.empty:
        if (!data.isBlocked) return const SizedBox.shrink();
        return Icon(
          Icons.close_rounded,
          size: cellSize * 0.3,
          color: theme.markerColor.withValues(alpha: 0.22),
        );
    }
  }
}

class _RegionBorderPainter extends CustomPainter {
  _RegionBorderPainter({
    required this.size,
    required this.regions,
    required this.thinColor,
    required this.thickColor,
    required this.thinWidth,
    required this.thickWidth,
    required this.cursor,
    required this.cursorColor,
  });

  final int size;
  final List<int> regions;
  final Color thinColor;
  final Color thickColor;
  final double thinWidth;
  final double thickWidth;
  final CellPosition? cursor;
  final Color cursorColor;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final step = canvasSize.width / size;
    final thin = Paint()
      ..color = thinColor
      ..strokeWidth = thinWidth;
    final thick = Paint()
      ..color = thickColor
      ..strokeWidth = thickWidth
      ..strokeCap = StrokeCap.square;

    int region(int r, int c) => regions[r * size + c];

    // Thin lines everywhere, then thick lines where regions meet.
    for (final pass in [false, true]) {
      for (var r = 0; r < size; r++) {
        for (var c = 0; c < size; c++) {
          if (c < size - 1) {
            final border = region(r, c) != region(r, c + 1);
            if (border == pass) {
              final x = step * (c + 1);
              canvas.drawLine(Offset(x, step * r), Offset(x, step * (r + 1)),
                  pass ? thick : thin);
            }
          }
          if (r < size - 1) {
            final border = region(r, c) != region(r + 1, c);
            if (border == pass) {
              final y = step * (r + 1);
              canvas.drawLine(Offset(step * c, y), Offset(step * (c + 1), y),
                  pass ? thick : thin);
            }
          }
        }
      }
    }

    final at = cursor;
    if (at != null) {
      canvas.drawRect(
        Rect.fromLTWH(step * at.col, step * at.row, step, step).deflate(2),
        Paint()
          ..color = cursorColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_RegionBorderPainter old) =>
      old.size != size ||
      !identical(old.regions, regions) ||
      old.cursor != cursor ||
      old.thinColor != thinColor ||
      old.thickColor != thickColor ||
      old.thinWidth != thinWidth ||
      old.thickWidth != thickWidth ||
      old.cursorColor != cursorColor;
}
