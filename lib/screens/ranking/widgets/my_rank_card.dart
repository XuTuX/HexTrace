import 'package:flutter/material.dart';

import 'package:linkagon/constant.dart';
import 'package:linkagon/theme/app_typography.dart';

class MyRankCard extends StatelessWidget {
  const MyRankCard({
    super.key,
    this.rank,
    this.score,
    required this.isLoggedIn,
  });

  final int? rank;
  final int? score;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    if (rank == null || score == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: charcoalBlack.withValues(alpha: 0.05)),
        ),
        child: Center(
          child: Text(
            isLoggedIn ? 'PLAY TO RANK UP' : 'LOG IN TO JOIN THE RANKING',
            style: AppTypography.label.copyWith(
              fontSize: 11,
              color: charcoalBlack.withValues(alpha: 0.3),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: charcoalBlack.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$rank',
                style: AppTypography.title.copyWith(
                  fontSize: 32,
                  color: charcoalBlack,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              Text(
                '위',
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  color: charcoalBlack.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 24),
              Container(
                width: 1,
                height: 20,
                color: charcoalBlack.withValues(alpha: 0.08),
              ),
              const SizedBox(width: 24),
              Text(
                '$score',
                style: AppTypography.title.copyWith(
                  fontSize: 32,
                  color: charcoalBlack,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              Text(
                '점',
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  color: charcoalBlack.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
