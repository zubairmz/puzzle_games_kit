import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/cell_position.dart';
import '../theme/puzzle_theme.dart';
import 'sudoku_controller.dart';

/// Everything needed to draw one Sudoku cell, passed to a
/// [SudokuCellBuilder].
@immutable
class SudokuCellData {
  /// Creates cell data.
  const SudokuCellData({
    required this.position,
    required this.value,
    required this.notes,
    required this.size,
    required this.boxRows,
    required this.boxCols,
    required this.isGiven,
    required this.isSelected,
    required this.isRelated,
    required this.isSameValue,
    required this.isWrong,
    required this.hasConflict,
  });

  /// The cell's position.
  final CellPosition position;

  /// The value, or `0` if empty.
  final int value;

  /// Pencil notes (empty when the cell has a value).
  final Set<int> notes;

  /// Cells per row (also the highest value).
  final int size;

  /// Rows in each box.
  final int boxRows;

  /// Columns in each box.
  final int boxCols;

  /// Whether this is a starting clue.
  final bool isGiven;

  /// Whether this cell is selected.
  final bool isSelected;

  /// Whether this cell shares a row, column or box with the selection.
  final bool isRelated;

  /// Whether this cell holds the same value as the selection.
  final bool isSameValue;

  /// Whether the value differs from the solution (if mistakes are revealed).
  final bool isWrong;

  /// Whether the value repeats in its row, column or box.
  final bool hasConflict;
}

/// Builds a cell's content and background. Return any widget; it is sized
/// to the cell and receives taps through the board.
typedef SudokuCellBuilder = Widget Function(
  BuildContext context,
  SudokuCellData cell,
  PuzzleTheme theme,
);

/// An interactive Sudoku grid for a [SudokuController].
///
/// Tap a cell to select it. With [enableKeyboard], arrow keys move the
/// selection, digits enter values, Backspace/Delete erases, `N` toggles notes
/// and Ctrl/Cmd+Z undoes. The board is square and fills the available width
/// (or height, whichever is smaller).
class SudokuBoard extends StatefulWidget {
  /// Creates a board for [controller].
  const SudokuBoard({
    super.key,
    required this.controller,
    this.theme,
    this.highlightRelated = true,
    this.highlightSameValue = true,
    this.showNotes = true,
    this.enableKeyboard = true,
    this.autofocus = false,
    this.cellBuilder,
  });

  /// The game to show and control.
  final SudokuController controller;

  /// Overrides the inherited [PuzzleTheme].
  final PuzzleTheme? theme;

  /// Shade the selected cell's row, column and box.
  final bool highlightRelated;

  /// Shade cells holding the same value as the selected cell.
  final bool highlightSameValue;

  /// Draw pencil notes.
  final bool showNotes;

  /// Accept keyboard input (useful on desktop and web).
  final bool enableKeyboard;

  /// Focus the board for keyboard input when first shown.
  final bool autofocus;

  /// Replaces the default cell drawing. See [SudokuCellData].
  final SudokuCellBuilder? cellBuilder;

  @override
  State<SudokuBoard> createState() => _SudokuBoardState();
}

class _SudokuBoardState extends State<SudokuBoard> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'SudokuBoard');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final c = widget.controller;
    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    if ((keyboard.isControlPressed || keyboard.isMetaPressed) &&
        key == LogicalKeyboardKey.keyZ) {
      c.undo();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      c.moveSelection(-1, 0);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      c.moveSelection(1, 0);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      c.moveSelection(0, -1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      c.moveSelection(0, 1);
    } else if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      c.erase();
    } else if (key == LogicalKeyboardKey.keyN) {
      c.toggleNotesMode();
    } else {
      final digit = int.tryParse(event.character ?? '');
      if (digit == null || digit < 1 || digit > c.size) {
        return KeyEventResult.ignored;
      }
      c.input(digit);
    }
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
        onKeyEvent: widget.enableKeyboard ? _onKey : null,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => _buildBoard(context, theme),
        ),
      ),
    );
  }

  Widget _buildBoard(BuildContext context, PuzzleTheme theme) {
    final c = widget.controller;
    final n = c.size;
    final selectedValue = c.selectedValue;
    final frameColor = c.isSolved ? theme.successColor : theme.blockLineColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final cellSize = side / n;
        return Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            color: theme.cellColor,
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
                                child: _buildCell(
                                  context,
                                  theme,
                                  r,
                                  col,
                                  cellSize,
                                  selectedValue,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SudokuGridPainter(
                        size: n,
                        boxRows: c.puzzle.boxRows,
                        boxCols: c.puzzle.boxCols,
                        thinColor: theme.gridLineColor,
                        thickColor: theme.blockLineColor,
                        thinWidth: theme.gridLineWidth,
                        thickWidth: theme.blockLineWidth,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(
    BuildContext context,
    PuzzleTheme theme,
    int row,
    int col,
    double cellSize,
    int selectedValue,
  ) {
    final c = widget.controller;
    final value = c.valueAt(row, col);
    final position = CellPosition(row, col);
    final data = SudokuCellData(
      position: position,
      value: value,
      notes: value == 0 && widget.showNotes ? c.notesAt(row, col) : const {},
      size: c.size,
      boxRows: c.puzzle.boxRows,
      boxCols: c.puzzle.boxCols,
      isGiven: c.isGiven(row, col),
      isSelected: c.selected == position,
      isRelated: widget.highlightRelated && c.isRelatedToSelection(row, col),
      isSameValue: widget.highlightSameValue &&
          selectedValue != 0 &&
          value == selectedValue,
      isWrong: c.isWrong(row, col),
      hasConflict: c.hasConflict(row, col),
    );

    final content = widget.cellBuilder?.call(context, data, theme) ??
        _DefaultSudokuCell(data: data, theme: theme, cellSize: cellSize);

    return Semantics(
      button: true,
      selected: data.isSelected,
      label: 'Row ${row + 1}, column ${col + 1}',
      value: value == 0 ? 'empty' : '$value${data.isGiven ? ', clue' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.enableKeyboard) _focusNode.requestFocus();
          c.select(position);
        },
        child: content,
      ),
    );
  }
}

class _DefaultSudokuCell extends StatelessWidget {
  const _DefaultSudokuCell({
    required this.data,
    required this.theme,
    required this.cellSize,
  });

  final SudokuCellData data;
  final PuzzleTheme theme;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final error = data.isWrong || data.hasConflict;
    final Color background;
    if (data.isSelected) {
      background = theme.selectedCellColor;
    } else if (error) {
      background = Color.alphaBlend(
        theme.errorColor.withValues(alpha: 0.12),
        theme.cellColor,
      );
    } else if (data.isSameValue) {
      background = Color.alphaBlend(theme.sameValueColor, theme.cellColor);
    } else if (data.isRelated) {
      background = Color.alphaBlend(theme.highlightColor, theme.cellColor);
    } else {
      background = theme.cellColor;
    }

    final base = (theme.textStyle ?? const TextStyle()).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget child;
    if (data.value != 0) {
      child = Text(
        '${data.value}',
        style: base.copyWith(
          fontSize: cellSize * 0.56,
          fontWeight: data.isGiven ? FontWeight.w700 : FontWeight.w500,
          color: error
              ? theme.errorColor
              : data.isGiven
                  ? theme.givenTextColor
                  : theme.entryTextColor,
        ),
      );
    } else if (data.notes.isNotEmpty) {
      child = _NotesGrid(
        notes: data.notes,
        columns: data.boxCols,
        rows: data.boxRows,
        style: base.copyWith(
          fontSize: cellSize / (math.max(data.boxRows, data.boxCols) + 1.2),
          color: theme.noteTextColor,
          height: 1,
        ),
      );
    } else {
      child = const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: theme.animationDuration,
      decoration: BoxDecoration(
        color: background,
        borderRadius: theme.cellRadius > 0
            ? BorderRadius.circular(theme.cellRadius)
            : null,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _NotesGrid extends StatelessWidget {
  const _NotesGrid({
    required this.notes,
    required this.columns,
    required this.rows,
    required this.style,
  });

  final Set<int> notes;
  final int columns;
  final int rows;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          for (var r = 0; r < rows; r++)
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < columns; c++)
                    Expanded(
                      child: Center(
                        child: Text(
                          notes.contains(r * columns + c + 1)
                              ? '${r * columns + c + 1}'
                              : '',
                          style: style,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SudokuGridPainter extends CustomPainter {
  _SudokuGridPainter({
    required this.size,
    required this.boxRows,
    required this.boxCols,
    required this.thinColor,
    required this.thickColor,
    required this.thinWidth,
    required this.thickWidth,
  });

  final int size;
  final int boxRows;
  final int boxCols;
  final Color thinColor;
  final Color thickColor;
  final double thinWidth;
  final double thickWidth;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final step = canvasSize.width / size;
    final thin = Paint()
      ..color = thinColor
      ..strokeWidth = thinWidth;
    final thick = Paint()
      ..color = thickColor
      ..strokeWidth = thickWidth;

    // Thin lines first so the thick box lines sit on top.
    for (final pass in [false, true]) {
      for (var i = 1; i < size; i++) {
        final offset = step * i;
        final vertical = i % boxCols == 0;
        final horizontal = i % boxRows == 0;
        if (vertical == pass) {
          canvas.drawLine(Offset(offset, 0), Offset(offset, canvasSize.height),
              pass ? thick : thin);
        }
        if (horizontal == pass) {
          canvas.drawLine(Offset(0, offset), Offset(canvasSize.width, offset),
              pass ? thick : thin);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_SudokuGridPainter old) =>
      old.size != size ||
      old.boxRows != boxRows ||
      old.boxCols != boxCols ||
      old.thinColor != thinColor ||
      old.thickColor != thickColor ||
      old.thinWidth != thinWidth ||
      old.thickWidth != thickWidth;
}
