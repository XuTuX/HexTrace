import 'package:flutter/material.dart';

import 'package:hexor/constant.dart';
import '../../game/game_palette.dart';
import '../../game/hex_game_controller.dart';

class AnimatedColorStream extends StatefulWidget {
  const AnimatedColorStream({
    super.key,
    required this.entries,
    required this.highlightedWindows,
  });

  final List<ColorBarEntry> entries;
  final List<BarWindow> highlightedWindows;

  @override
  State<AnimatedColorStream> createState() => _AnimatedColorStreamState();
}

class _AnimatedColorStreamState extends State<AnimatedColorStream> {
  static const Duration _moveDuration = Duration(milliseconds: 260);
  static const double _slotGap = 5;

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
    final highlightedIds = widget.highlightedWindows.expand((window) sync* {
      for (var index = window.start; index <= window.end; index++) {
        if (index >= 0 && index < widget.entries.length) {
          yield widget.entries[index].id;
        }
      }
    }).toSet();

    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth =
            (constraints.maxWidth - (_slotGap * (widget.entries.length - 1))) /
                widget.entries.length;

        final slotHeight = slotWidth * 1.6;

        return SizedBox(
          height: slotHeight + 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: _visualEntries.values.map((visual) {
              final isFirst = visual.index <= 0.1;
              final isLast = visual.index >= widget.entries.length - 1 - 0.1;

              return AnimatedPositioned(
                key: ValueKey<int>(visual.entry.id),
                duration: _moveDuration,
                curve: Curves.easeInOutCubic,
                left: visual.index * (slotWidth + _slotGap),
                top: 0,
                width: slotWidth,
                height: slotHeight,
                child: AnimatedOpacity(
                  duration: _moveDuration,
                  curve: Curves.easeOutCubic,
                  opacity: visual.opacity,
                  child: AnimatedScale(
                    duration: _moveDuration,
                    curve: Curves.easeOutBack,
                    scale: visual.scale,
                    child: _ColorStreamSlot(
                      color: visual.entry.color,
                      highlighted: !visual.removing &&
                          highlightedIds.contains(visual.entry.id),
                      isFirst: isFirst,
                      isLast: isLast,
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        );
      },
    );
  }
}

class _VisualBarEntry {
  _VisualBarEntry({
    required this.entry,
    required this.index,
    this.opacity = 1,
    this.scale = 1,
  });

  ColorBarEntry entry;
  double index;
  double opacity;
  double scale;
  bool removing = false;
}

class _ColorStreamSlot extends StatelessWidget {
  const _ColorStreamSlot({
    required this.color,
    required this.highlighted,
    required this.isFirst,
    required this.isLast,
  });

  final GameColor color;
  final bool highlighted;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final fill = GamePalette.colorFor(color);

    final double topMargin = highlighted ? 1.5 : 0;
    final double leftMargin = highlighted ? 1.5 : 0;
    final double bottomMargin = highlighted ? 0 : 1.5;
    final double rightMargin = highlighted ? 0 : 1.5;
    final double shadowDepth = highlighted ? 0 : 1.5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin:
          EdgeInsets.fromLTRB(leftMargin, topMargin, rightMargin, bottomMargin),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: charcoalBlack,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(shadowDepth, shadowDepth),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: highlighted ? 10 : 6,
          height: highlighted ? 10 : 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: highlighted ? 0.8 : 0.25),
            shape: BoxShape.circle,
            boxShadow: highlighted
                ? [
                    BoxShadow(
                        color: Colors.white.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1)
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
