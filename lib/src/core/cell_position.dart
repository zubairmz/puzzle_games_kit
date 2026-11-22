import 'package:flutter/foundation.dart';

/// A cell in a puzzle grid, addressed by zero-based [row] and [col].
@immutable
class CellPosition {
  /// Creates a position.
  const CellPosition(this.row, this.col);

  /// Zero-based row index.
  final int row;

  /// Zero-based column index.
  final int col;

  /// The row-major index of this cell in a grid with [columns] columns.
  int indexIn(int columns) => row * columns + col;

  /// Whether [other] touches this cell, including diagonally.
  bool touches(CellPosition other) =>
      this != other &&
      (row - other.row).abs() <= 1 &&
      (col - other.col).abs() <= 1;

  @override
  bool operator ==(Object other) =>
      other is CellPosition && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'CellPosition($row, $col)';
}
