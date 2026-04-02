import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../../game/game_palette.dart';
import 'animated_color_stream.dart';

class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.controller});

  final HexGameController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(label: '점수', value: '${controller.score}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: '시간',
                  value: '${controller.timeRemaining.ceil()}초',
                  accent: controller.timeRemaining <= 10
                      ? GamePalette.danger
                      : GamePalette.warning,
                ),
              ),
              if (controller.combo > 1) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: '콤보',
                    value: 'x${controller.combo}',
                    accent: GamePalette.success,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ColorBarPanel(
            colors: controller.colorBar,
            highlightedWindows: controller.activeBarWindows,
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.accent = GamePalette.ink,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GamePalette.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.1,
                color: GamePalette.ink.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ColorBarPanel extends StatelessWidget {
  const ColorBarPanel({
    super.key,
    required this.colors,
    required this.highlightedWindows,
  });

  final List<ColorBarEntry> colors;
  final List<BarWindow> highlightedWindows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GamePalette.panelAlt.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '색 흐름',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  '사용한 구간만 사라져요',
                  style: TextStyle(
                    color: GamePalette.ink.withValues(alpha: 0.62),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedColorStream(
              entries: colors,
              highlightedWindows: highlightedWindows,
            ),
          ],
        ),
      ),
    );
  }
}
