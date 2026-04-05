import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constant.dart';
import '../controllers/score_controller.dart';
import '../theme/app_typography.dart';

class ScoreBar extends StatelessWidget {
  const ScoreBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scoreController = Get.find<ScoreController>();

    return Row(
      children: [
        Expanded(
          child: _ScoreCard(
            label: 'SCORE',
            value: scoreController.score,
            increment: scoreController.lastIncrement,
            showIncrement: scoreController.showIncrement,
            combo: scoreController.combo,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ScoreCard(
            label: 'BEST',
            value: scoreController.highscore,
          ),
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String label;
  final RxInt value;
  final RxInt? increment;
  final RxBool? showIncrement;
  final RxInt? combo;

  const _ScoreCard({
    required this.label,
    required this.value,
    this.increment,
    this.showIncrement,
    this.combo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Obx(
            () => Text(
              '${value.value}',
              style: AppTypography.scoreMedium.copyWith(
                fontSize: 30,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (combo != null)
            Obx(() {
              final chainDepth = combo!.value;
              if (chainDepth <= 1) {
                return Text(
                  'Build a chain',
                  style: AppTypography.bodySmall.copyWith(
                    color: charcoalBlack45,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }

              return Text(
                'Chain x$chainDepth',
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFFF97316),
                  fontWeight: FontWeight.w900,
                ),
              );
            })
          else if (increment != null && showIncrement != null)
            Obx(() {
              if (!showIncrement!.value || increment!.value <= 0) {
                return Text(
                  'Keep climbing',
                  style: AppTypography.bodySmall.copyWith(
                    color: charcoalBlack45,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }

              return Text(
                '+${increment!.value} this turn',
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFF22C55E),
                  fontWeight: FontWeight.w900,
                ),
              );
            })
          else
            const SizedBox(height: 18),
        ],
      ),
    );
  }
}
