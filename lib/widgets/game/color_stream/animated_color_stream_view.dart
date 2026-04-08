part of 'package:hexor/widgets/game/animated_color_stream.dart';

class _AnimatedColorStreamView extends StatelessWidget {
  const _AnimatedColorStreamView({
    required this.entries,
    required this.highlightedWindows,
    required this.visualEntries,
    required this.moveDuration,
  });

  static const double _slotGap = 5;

  final List<ColorBarEntry> entries;
  final List<BarWindow> highlightedWindows;
  final List<_VisualBarEntry> visualEntries;
  final Duration moveDuration;

  @override
  Widget build(BuildContext context) {
    final highlightedIds = _highlightedEntryIds(entries, highlightedWindows);

    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth =
            (constraints.maxWidth - (_slotGap * (entries.length - 1))) /
                entries.length;
        final slotHeight = slotWidth * 1.6;

        return SizedBox(
          height: slotHeight + 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: visualEntries.map((visual) {
              final isFirst = visual.index <= 0.1;
              final isLast = visual.index >= entries.length - 1 - 0.1;

              return AnimatedPositioned(
                key: ValueKey<int>(visual.entry.id),
                duration: moveDuration,
                curve: Curves.easeInOutCubic,
                left: visual.index * (slotWidth + _slotGap),
                top: 0,
                width: slotWidth,
                height: slotHeight,
                child: AnimatedOpacity(
                  duration: moveDuration,
                  curve: Curves.easeOutCubic,
                  opacity: visual.opacity,
                  child: AnimatedScale(
                    duration: moveDuration,
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

Set<int> _highlightedEntryIds(
  List<ColorBarEntry> entries,
  List<BarWindow> windows,
) {
  return windows.expand((window) sync* {
    for (var index = window.start; index <= window.end; index++) {
      if (index >= 0 && index < entries.length) {
        yield entries[index].id;
      }
    }
  }).toSet();
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
    final topMargin = highlighted ? 1.5 : 0.0;
    final leftMargin = highlighted ? 1.5 : 0.0;
    final bottomMargin = highlighted ? 0.0 : 1.5;
    final rightMargin = highlighted ? 0.0 : 1.5;
    final shadowDepth = highlighted ? 0.0 : 1.5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: EdgeInsets.fromLTRB(
        leftMargin,
        topMargin,
        rightMargin,
        bottomMargin,
      ),
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
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
