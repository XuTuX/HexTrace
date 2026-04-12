import 'package:flutter/material.dart';

import 'package:hexor/constant.dart';
import '../../game/hex_game_controller.dart';
import 'animated_color_stream.dart';

class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.controller});

  final HexGameController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.sessionConfig.isDailyMode && !controller.isReplaying)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: controller.sessionConfig.isOfficialScoreSubmission
                        ? const Color(0xFFE0F2FE)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: charcoalBlack, width: 1.5),
                  ),
                  child: Text(
                    controller.sessionConfig.isOfficialScoreSubmission
                        ? '오늘의 퍼즐 공식 도전'
                        : '오늘의 퍼즐 연습 모드',
                    style: const TextStyle(
                      color: charcoalBlack,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          if (!controller.isReplaying)
            Align(
              alignment: Alignment.centerRight,
              child: _RestartButton(onPressed: controller.playAgain),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (controller.isReplaying)
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: StatCard(
                        label: '점수',
                        value: '${controller.score}',
                      ),
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: StatCard(label: '점수', value: '${controller.score}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: '시간',
                    value: '${controller.timeRemaining.ceil()}초',
                    accent: controller.timeRemaining <= 5
                        ? const Color(0xFFFF0000) // Vibrant Red
                        : controller.timeRemaining <= 10
                            ? const Color(0xFFF97316) // Orange
                            : const Color(0xFF2563EB), // Blue
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ColorBarPanel(
            controller: controller,
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
    required this.controller,
  });

  final HexGameController controller;

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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                controller.isReplaying ? '리플레이 재생 중...' : '사용한 구간만 사라져요',
                style: TextStyle(
                  color: controller.isReplaying
                      ? const Color(0xFFDC2626)
                      : charcoalBlack.withValues(alpha: 0.62),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedColorStream(
            entries: controller.colorBar,
            highlightedWindows: controller.activeBarWindows,
          ),
        ],
      ),
    );
  }
}

class _RestartButton extends StatelessWidget {
  const _RestartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: charcoalBlack, width: 2),
          boxShadow: const [
            BoxShadow(
              color: charcoalBlack,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.refresh_rounded,
            color: charcoalBlack,
            size: 20,
          ),
        ),
      ),
    );
  }
}
