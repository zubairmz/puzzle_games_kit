import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/cell_position.dart';

/// A rectangle of whole cells in a grid.
@immutable
class GridRect {
  /// Creates a rectangle from its top-left cell and size.
  const GridRect({
    required this.top,
    required this.left,
    required this.height,
    required this.width,
  })  : assert(height > 0),
        assert(width > 0);

  /// The rectangle spanning two opposite corner cells, in any order.
  factory GridRect.fromCorners(CellPosition a, CellPosition b) {
    final top = math.min(a.row, b.row);
    final left = math.min(a.col, b.col);
    return GridRect(
      top: top,
      left: left,
      height: (a.row - b.row).abs() + 1,
      width: (a.col - b.col).abs() + 1,
    );
  }

  /// Restores a rectangle from [toJson].
  factory GridRect.fromJson(Map<String, Object?> json) => GridRect(
        top: json['top']! as int,
        left: json['left']! as int,
        height: json['height']! as int,
        width: json['width']! as int,
      );

  /// First row.
  final int top;

  /// First column.
  final int left;

  /// Number of rows.
  final int height;

  /// Number of columns.
  final int width;

  /// Last row (inclusive).
  int get bottom => top + height - 1;

  /// Last column (inclusive).
  int get right => left + width - 1;

  /// Number of cells.
  int get area => height * width;

  /// Whether [row], [col] lies inside.
  bool contains(int row, int col) =>
      row >= top && row <= bottom && col >= left && col <= right;

  /// Whether this shares any cell with [other].
  bool overlaps(GridRect other) =>
      top <= other.bottom &&
      other.top <= bottom &&
      left <= other.right &&
      other.left <= right;

  /// Every cell inside, row by row.
  Iterable<CellPosition> get cells sync* {
    for (var r = top; r <= bottom; r++) {
      for (var c = left; c <= right; c++) {
        yield CellPosition(r, c);
      }
    }
  }

  /// A JSON-friendly map of this rectangle.
  Map<String, Object?> toJson() =>
      {'top': top, 'left': left, 'height': height, 'width': width};

  @override
  bool operator ==(Object other) =>
      other is GridRect &&
      other.top == top &&
      other.left == left &&
      other.height == height &&
      other.width == width;

  @override
  int get hashCode => Object.hash(top, left, height, width);

  @override
  String toString() => 'GridRect($top, $left, ${height}x$width)';
}
