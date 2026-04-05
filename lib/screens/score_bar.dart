import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constant.dart';
import '../controllers/game_controller.dart';
import '../controllers/score_controller.dart';

class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scoreController = Get.find<ScoreController>();
    final gameController = Get.find<GameController>();

    return Obx(
      () => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _StatCard(
            label: 'SCORE',
            value: '${scoreController.score.value}',
            accent: const Color(0xFFF97316),
            helper: scoreController.showIncrement.value &&
                    scoreController.lastIncrement.value > 0
                ? '+${scoreController.lastIncrement.value} last clear'
                : 'Clear longer paths for bigger points',
          ),
          _StatCard(
            label: 'TIME',
            value: '${gameController.timeLeft.value}s',
            accent: gameController.timeLeft.value <= 10
                ? const Color(0xFFDC2626)
                : const Color(0xFF2563EB),
            helper: 'Match adds bonus seconds',
          ),
          _StatCard(
            label: 'BEST',
            value: '${scoreController.highscore.value}',
            accent: const Color(0xFF16A34A),
            helper: gameController.comboDepth.value > 1
                ? 'Combo x${gameController.comboDepth.value}'
                : '1 shuffle charge: ${gameController.shuffleCharges.value}',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final Color accent;

  const _StatCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 56) / 2;

    return Container(
      width: width.clamp(150.0, 220.0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            label,
            style: TextStyle(
              color: charcoalBlack.withValues(alpha: 0.65),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 30,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            helper,
            style: TextStyle(
              color: charcoalBlack.withValues(alpha: 0.68),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
