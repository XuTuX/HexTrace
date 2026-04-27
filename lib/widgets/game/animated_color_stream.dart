import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/game/game_palette.dart';
import 'package:hexor/game/hex_game_controller.dart';

part 'color_stream/animated_color_stream_view.dart';

class AnimatedColorStream extends StatefulWidget {
  const AnimatedColorStream({
    super.key,
    required this.entries,
    required this.highlightedWindows,
    this.tutorialHighlightedIndices = const {},
    this.tutorialAnimValue = 0.0,
  });

  final List<ColorBarEntry> entries;
  final List<BarWindow> highlightedWindows;
  final Set<int> tutorialHighlightedIndices;
  final double tutorialAnimValue;

  @override
  State<AnimatedColorStream> createState() => _AnimatedColorStreamState();
}

class _AnimatedColorStreamState extends State<AnimatedColorStream> {
  static const Duration _moveDuration = Duration(milliseconds: 260);

  final Map<int, _VisualBarEntry> _visualEntries = <int, _VisualBarEntry>{};

  @override
  void initState() {
    super.initState();

    for (var index = 0; index < widget.entries.length; index++) {
      final entry = widget.entries[index];
      _visualEntries[entry.id] = _VisualBarEntry(
        entry: entry,
        index: index.toDouble(),
      );
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedColorStream oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextIds = widget.entries.map((entry) => entry.id).toSet();
    final currentIds = _visualEntries.keys.toSet();
    final enteringEntries = <ColorBarEntry>[];

    var changed = false;

    for (final id in currentIds.difference(nextIds)) {
      final visual = _visualEntries[id]!;
      visual.opacity = 0;
      visual.scale = 0.68;
      visual.removing = true;
      changed = true;
    }

    for (var index = 0; index < widget.entries.length; index++) {
      final entry = widget.entries[index];
      final existing = _visualEntries[entry.id];

      if (existing != null) {
        existing.entry = entry;
        existing.index = index.toDouble();
        existing.opacity = 1;
        existing.scale = 1;
        existing.removing = false;
      } else {
        _visualEntries[entry.id] = _VisualBarEntry(
          entry: entry,
          index: widget.entries.length.toDouble() + enteringEntries.length,
          opacity: 0,
          scale: 0.84,
        );
        enteringEntries.add(entry);
      }

      changed = true;
    }

    if (oldWidget.tutorialAnimValue != widget.tutorialAnimValue && 
        widget.tutorialHighlightedIndices.isNotEmpty) {
      changed = true;
    }

    if (changed && mounted) {
      setState(() {});
    }

    if (enteringEntries.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        setState(() {
          for (final entry in enteringEntries) {
            final visual = _visualEntries[entry.id]!;
            visual.index = widget.entries
                .indexWhere((candidate) => candidate.id == entry.id)
                .toDouble();
            visual.opacity = 1;
            visual.scale = 1;
          }
        });
      });
    }

    if (currentIds.difference(nextIds).isNotEmpty) {
      Future<void>.delayed(_moveDuration, () {
        if (!mounted) {
          return;
        }

        setState(() {
          _visualEntries.removeWhere(
            (_, visual) =>
                visual.removing && !nextIds.contains(visual.entry.id),
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AnimatedColorStreamView(
      entries: widget.entries,
      highlightedWindows: widget.highlightedWindows,
      tutorialHighlightedIndices: widget.tutorialHighlightedIndices,
      tutorialAnimValue: widget.tutorialAnimValue,
      visualEntries: _visualEntries.values.toList(growable: false),
      moveDuration: _moveDuration,
    );
  }
}
