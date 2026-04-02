import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../../game/game_palette.dart';

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
  static const double _slotGap = 3;

  final Map<int, _VisualBarEntry> _visualEntries = <int, _VisualBarEntry>{};

  @override
  void initState() {
    super.initState();

    for (int index = 0; index < widget.entries.length; index++) {
      final ColorBarEntry entry = widget.entries[index];
      _visualEntries[entry.id] = _VisualBarEntry(
        entry: entry,
        index: index.toDouble(),
      );
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedColorStream oldWidget) {
    super.didUpdateWidget(oldWidget);

    final Set<int> nextIds = widget.entries.map((entry) => entry.id).toSet();
    final Set<int> currentIds = _visualEntries.keys.toSet();
    final List<ColorBarEntry> enteringEntries = <ColorBarEntry>[];

    bool changed = false;

    for (final int id in currentIds.difference(nextIds)) {
      final _VisualBarEntry visual = _visualEntries[id]!;
      visual.opacity = 0;
      visual.scale = 0.68;
      visual.removing = true;
      changed = true;
    }

    for (int index = 0; index < widget.entries.length; index++) {
      final ColorBarEntry entry = widget.entries[index];
      final _VisualBarEntry? existing = _visualEntries[entry.id];

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
          for (final ColorBarEntry entry in enteringEntries) {
            final _VisualBarEntry visual = _visualEntries[entry.id]!;
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
    final Set<int> highlightedIds = widget.highlightedWindows.expand((
      window,
    ) sync* {
      for (int index = window.start; index <= window.end; index++) {
        if (index >= 0 && index < widget.entries.length) {
          yield widget.entries[index].id;
        }
      }
    }).toSet();

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double slotWidth =
              (constraints.maxWidth -
                  (_slotGap * (widget.entries.length - 1))) /
              widget.entries.length;

          return SizedBox(
            height: 56,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: _visualEntries.values
                  .map((visual) {
                    final bool isFirst = visual.index <= 0.1;
                    final bool isLast =
                        visual.index >= widget.entries.length - 1 - 0.1;

                    return AnimatedPositioned(
                      key: ValueKey<int>(visual.entry.id),
                      duration: _moveDuration,
                      curve: Curves.easeInOutCubic,
                      left: visual.index * (slotWidth + _slotGap),
                      top: 0,
                      width: slotWidth,
                      height: 56,
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
                            highlighted:
                                !visual.removing &&
                                highlightedIds.contains(visual.entry.id),
                            isFirst: isFirst,
                            isLast: isLast,
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          );
        },
      ),
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
    final Color fill = GamePalette.colorFor(color);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.symmetric(horizontal: 1.2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(isFirst ? 16 : 6),
          right: Radius.circular(isLast ? 16 : 6),
        ),
        border: Border.all(
          color: highlighted
              ? Colors.white
              : Colors.white.withValues(alpha: 0.08),
          width: highlighted ? 2.8 : 0.8,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: fill.withValues(alpha: 0.55),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: highlighted ? 16 : 10,
          height: highlighted ? 16 : 10,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: highlighted ? 0.92 : 0.38),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
