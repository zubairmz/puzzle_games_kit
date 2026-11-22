import 'dart:async';

import 'package:flutter/material.dart';

import '../core/puzzle_controller.dart';

/// Formats [elapsed] as `m:ss`, or `h:mm:ss` from one hour.
String formatPuzzleDuration(Duration elapsed) {
  final hours = elapsed.inHours;
  final minutes = elapsed.inMinutes.remainder(60);
  final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:$seconds'
      : '$minutes:$seconds';
}

/// Shows a controller's play time, updating every second while it runs.
class PuzzleClockText extends StatefulWidget {
  /// Creates a clock for [controller].
  const PuzzleClockText({
    super.key,
    required this.controller,
    this.style,
    this.formatter = formatPuzzleDuration,
  });

  /// The game whose time is shown.
  final PuzzleController<Object?, Object?> controller;

  /// Text style; defaults to the ambient style with tabular figures.
  final TextStyle? style;

  /// Turns the elapsed time into text.
  final String Function(Duration elapsed) formatter;

  @override
  State<PuzzleClockText> createState() => _PuzzleClockTextState();
}

class _PuzzleClockTextState extends State<PuzzleClockText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _syncTimer();
  }

  @override
  void didUpdateWidget(PuzzleClockText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
      _syncTimer();
    }
  }

  void _onChanged() {
    _syncTimer();
    setState(() {});
  }

  void _syncTimer() {
    final running =
        !widget.controller.isPaused && !widget.controller.isFinished;
    if (running && _timer == null) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    } else if (!running) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = (widget.style ?? DefaultTextStyle.of(context).style)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return Text(widget.formatter(widget.controller.elapsed), style: style);
  }
}
