import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/cell_position.dart';
import '../theme/puzzle_theme.dart';
import 'grid_rect.dart';
import 'shikaku_controller.dart';

/// How a drawn rectangle is shown, passed to a [ShikakuRectBuilder].
@immutable
class ShikakuRectData {
  /// Creates rectangle data.
  const ShikakuRectData({
    required this.rect,
    required this.clueIndex,
    required this.isValid,
    required this.isWrong,
  });

  /// The rectangle.
  final GridRect rect;

  /// Index of the clue inside, if exactly one; otherwise `null`.
  final int? clueIndex;

  /// Whether it holds exactly one clue equal to its area.
  final bool isValid;

  /// Whether it differs from the solution (only when mistakes are revealed).
  final bool isWrong;
}

/// Builds the visual for a drawn rectangle. The widget is sized to the
/// rectangle; clue numbers are drawn on top separately.
typedef ShikakuRectBuilder = Widget Function(
  BuildContext context,
  ShikakuRectData data,
  PuzzleTheme theme,
);

/// An interactive Shikaku grid for a [ShikakuController].
///
/// Drag from one cell to another to draw a rectangle (it replaces anything
/// it overlaps); tap a rectangle to remove it. With [enableKeyboard], arrows
/// move a cursor, Space marks one corner and then the other, Escape cancels,
/// Backspace removes and Ctrl/Cmd+Z undoes.
class ShikakuBoard extends StatefulWidget {
  /// Creates a board for [controller].
  const ShikakuBoard({
    super.key,
    required this.controller,
    this.theme,
    this.highlightInvalid = true,
    this.showPreviewSize = true,
    this.tapToRemove = true,
    this.enableKeyboard = true,
    this.autofocus = false,
    this.rectBuilder,
  });

  /// The game to show and control.
  final ShikakuController controller;

  /// Overrides the inherited [PuzzleTheme].
  final PuzzleTheme? theme;

  /// Outline rectangles that break the rules in the error colour.
  final bool highlightInvalid;

  /// Show the size (e.g. `2×3`) of the rectangle being drawn.
  final bool showPreviewSize;

  /// Remove a rectangle when it is tapped.
  final bool tapToRemove;

  /// Accept keyboard input (useful on desktop and web).
  final bool enableKeyboard;

  /// Focus the board for keyboard input when first shown.
  final bool autofocus;

  /// Replaces the default rectangle drawing.
  final ShikakuRectBuilder? rectBuilder;

  @override
  State<ShikakuBoard> createState() => _ShikakuBoardState();
}

class _ShikakuBoardState extends State<ShikakuBoard> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'ShikakuBoard');
  CellPosition? _anchor;
  CellPosition? _current;
  CellPosition? _cursor;
  bool _hasFocus = false;

  /// The cursor is only drawn once the keyboard is used, not after taps.
  bool _usingKeyboard = false;

  ShikakuController get _c => widget.controller;

  GridRect? get _preview => _anchor != null && _current != null
      ? GridRect.fromCorners(_anchor!, _current!)
      : null;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  CellPosition? _cellAt(Offset local, Size size) {
    final row = (local.dy / size.height * _c.puzzle.rows).floor();
    final col = (local.dx / size.width * _c.puzzle.cols).floor();
    if (row < 0 || col < 0 || row >= _c.puzzle.rows || col >= _c.puzzle.cols) {
      return null;
    }
    return CellPosition(row, col);
  }

  CellPosition _clampCell(Offset local, Size size) {
    final row = (local.dy / size.height * _c.puzzle.rows)
        .floor()
        .clamp(0, _c.puzzle.rows - 1);
    final col = (local.dx / size.width * _c.puzzle.cols)
        .floor()
        .clamp(0, _c.puzzle.cols - 1);
    return CellPosition(row, col);
  }

  void _onTapUp(Offset local, Size size) {
    final cell = _cellAt(local, size);
    if (cell == null) return;
    if (widget.enableKeyboard) _focusNode.requestFocus();
    setState(() {
      _cursor = cell;
      _usingKeyboard = false;
    });
    if (_c.rectAt(cell.row, cell.col) != null) {
      if (widget.tapToRemove) _c.removeRectAt(cell.row, cell.col);
      return;
    }
    // A tap on an empty "1" clue is a complete one-cell rectangle.
    final clue = _c.puzzle.clueIndexAt(cell.row, cell.col);
    if (clue != -1 && _c.puzzle.clues[clue].value == 1) {
      _c.addRect(GridRect.fromCorners(cell, cell));
    }
  }

  void _onPanStart(Offset local, Size size) {
    if (!_c.acceptsInput) return;
    final cell = _cellAt(local, size);
    if (cell == null) return;
    setState(() {
      _anchor = cell;
      _current = cell;
    });
  }

  void _onPanUpdate(Offset local, Size size) {
    if (_anchor == null) return;
    final cell = _clampCell(local, size);
    if (cell != _current) setState(() => _current = cell);
  }

  void _onPanEnd() {
    final rect = _preview;
    setState(() {
      _anchor = null;
      _current = null;
    });
    if (rect != null) _c.addRect(rect);
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
    final rows = _c.puzzle.rows, cols = _c.puzzle.cols;
    final cursor = _cursor ?? const CellPosition(0, 0);
    void move(int dr, int dc) {
      final next =
          CellPosition((cursor.row + dr) % rows, (cursor.col + dc) % cols);
      setState(() {
        _cursor = next;
        if (_anchor != null) _current = next;
      });
    }

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
      if (_anchor == null) {
        setState(() {
          _cursor = cursor;
          _anchor = cursor;
          _current = cursor;
        });
      } else {
        _onPanEnd();
      }
    } else if (key == LogicalKeyboardKey.escape) {
      setState(() {
        _anchor = null;
        _current = null;
      });
    } else if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _c.removeRectAt(cursor.row, cursor.col);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = PuzzleTheme.of(context, widget.theme);
    return AspectRatio(
      aspectRatio: _c.puzzle.cols / _c.puzzle.rows,
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
              // Cells live inside the frame, so leave room for it.
              final frame = theme.blockLineWidth;
              final cellSize = math.min(
                (constraints.maxWidth - frame * 2) / _c.puzzle.cols,
                (constraints.maxHeight - frame * 2) / _c.puzzle.rows,
              );
              final inner =
                  Size(cellSize * _c.puzzle.cols, cellSize * _c.puzzle.rows);
              return _buildBoard(context, theme, inner, cellSize, frame);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(
    BuildContext context,
    PuzzleTheme theme,
    Size size,
    double cellSize,
    double frame,
  ) {
    final rows = _c.puzzle.rows, cols = _c.puzzle.cols;
    // Touch positions arrive relative to the outer edge; shift them inside
    // the frame.
    final inset = Offset(frame, frame);
    final frameColor = _c.isSolved ? theme.successColor : theme.blockLineColor;
    final preview = _preview;
    final baseText = theme.textStyle ?? const TextStyle();

    Rect area(GridRect r) => Rect.fromLTWH(r.left * cellSize, r.top * cellSize,
        r.width * cellSize, r.height * cellSize);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onTapUp: (d) => _onTapUp(d.localPosition - inset, size),
      onPanStart: (d) => _onPanStart(d.localPosition - inset, size),
      onPanUpdate: (d) => _onPanUpdate(d.localPosition - inset, size),
      onPanEnd: (_) => _onPanEnd(),
      onPanCancel: _onPanEnd,
      child: Container(
        width: size.width + frame * 2,
        height: size.height + frame * 2,
        decoration: BoxDecoration(
          color: theme.cellColor,
          borderRadius: theme.boardRadius,
          border: Border.all(color: frameColor, width: frame),
        ),
        child: ClipRRect(
          borderRadius: theme.boardRadius,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(
                    rows: rows,
                    cols: cols,
                    color: theme.gridLineColor,
                    width: theme.gridLineWidth,
                  ),
                ),
              ),
              for (final rect in _c.rects)
                Positioned.fromRect(
                  rect: area(rect),
                  child: _buildRect(context, theme, rect),
                ),
              if (preview != null)
                Positioned.fromRect(
                  rect: area(preview),
                  child: _PreviewRect(
                    rect: preview,
                    theme: theme,
                    showSize: widget.showPreviewSize,
                    fontSize: cellSize * 0.32,
                  ),
                ),
              for (final clue in _c.puzzle.clues)
                Positioned(
                  left: clue.position.col * cellSize,
                  top: clue.position.row * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: IgnorePointer(
                    child: Center(
                      child: Text(
                        '${clue.value}',
                        style: baseText.copyWith(
                          fontSize: cellSize * 0.46,
                          fontWeight: FontWeight.w700,
                          color: theme.givenTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_hasFocus && _usingKeyboard && _cursor != null)
                Positioned(
                  left: _cursor!.col * cellSize,
                  top: _cursor!.row * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: theme.entryTextColor, width: 2),
                      ),
                    ),
                  ),
                ),
              // Accessibility: one labelled node per cell.
              Positioned.fill(child: _semanticsGrid(rows, cols)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _semanticsGrid(int rows, int cols) {
    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Expanded(
            child: Row(
              children: [
                for (var c = 0; c < cols; c++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Row ${r + 1}, column ${c + 1}',
                      value: _cellDescription(r, c),
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _cellDescription(int row, int col) {
    final clue = _c.puzzle.clueIndexAt(row, col);
    final rect = _c.rectAt(row, col);
    final parts = [
      if (clue != -1) 'clue ${_c.puzzle.clues[clue].value}',
      if (rect != null) 'in a ${rect.height} by ${rect.width} rectangle',
      if (clue == -1 && rect == null) 'empty',
    ];
    return parts.join(', ');
  }

  Widget _buildRect(BuildContext context, PuzzleTheme theme, GridRect rect) {
    final inside = _c.cluesIn(rect);
    final data = ShikakuRectData(
      rect: rect,
      clueIndex: inside.length == 1 ? inside.first : null,
      isValid: _c.isValid(rect),
      isWrong: _c.isWrong(rect),
    );
    final custom = widget.rectBuilder;
    if (custom != null) return custom(context, data, theme);

    final bad = data.isWrong || (widget.highlightInvalid && !data.isValid);
    final fill = data.isValid
        ? theme.regionColor(data.clueIndex!)
        : theme.markerColor.withValues(alpha: 0.10);
    return Padding(
      padding: const EdgeInsets.all(2),
      child: AnimatedContainer(
        duration: theme.animationDuration,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(math.max(theme.cellRadius, 6)),
          border: Border.all(
            color: bad ? theme.errorColor : theme.blockLineColor,
            width: bad ? 2 : theme.gridLineWidth,
          ),
        ),
      ),
    );
  }
}

class _PreviewRect extends StatelessWidget {
  const _PreviewRect({
    required this.rect,
    required this.theme,
    required this.showSize,
    required this.fontSize,
  });

  final GridRect rect;
  final PuzzleTheme theme;
  final bool showSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: theme.selectedCellColor.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(math.max(theme.cellRadius, 6)),
          border: Border.all(color: theme.entryTextColor, width: 2),
        ),
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.all(4),
        child: showSize
            ? Text(
                '${rect.width}×${rect.height}',
                style: (theme.textStyle ?? const TextStyle()).copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: theme.entryTextColor,
                ),
              )
            : null,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.rows,
    required this.cols,
    required this.color,
    required this.width,
  });

  final int rows;
  final int cols;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width;
    final step = size.width / cols;
    for (var c = 1; c < cols; c++) {
      canvas.drawLine(
          Offset(step * c, 0), Offset(step * c, size.height), paint);
    }
    for (var r = 1; r < rows; r++) {
      canvas.drawLine(Offset(0, step * r), Offset(size.width, step * r), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.rows != rows ||
      old.cols != cols ||
      old.color != color ||
      old.width != width;
}
