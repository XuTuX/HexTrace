import 'package:flutter/material.dart';

import 'package:hexor/constant.dart';
import '../../game/game_controller.dart';
import 'animated_color_stream.dart';

class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.controller});

  final HexGameController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
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
                      ? const Color(0xFFDC2626) // Red
                      : const Color(0xFF2563EB), // Blue
                ),
              ),
              if (controller.combo > 1) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: '콤보',
                    value: 'x${controller.combo}',
                    accent: const Color(0xFF16A34A), // Green
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
    this.accent = const Color(0xFFF97316),
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: charcoalBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: charcoalBlack.withValues(alpha: 0.65),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              height: 1,
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: charcoalBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '색 흐름',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: charcoalBlack,
                ),
              ),
              const Spacer(),
              Text(
                '사용한 구간만 사라져요',
                style: TextStyle(
                  color: charcoalBlack.withValues(alpha: 0.62),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
    );
  }
}
