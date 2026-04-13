import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/theme/app_typography.dart';
import 'package:hexor/game/game_palette.dart';
import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/services/database_models.dart';

import '../ranking_period.dart';
import '../weekly_reset_info.dart';

class MyRankCard extends StatelessWidget {
  const MyRankCard({
    super.key,
    this.rank,
    this.score,
    required this.isLoggedIn,
    required this.period,
    this.weeklySeasonSummary,
  });

  final int? rank;
  final int? score;
  final bool isLoggedIn;
  final RankingPeriod period;
  final WeeklySeasonSummary? weeklySeasonSummary;

  @override
  Widget build(BuildContext context) {
    final weeklyResetInfo = WeeklyResetInfo.current();
    if (rank == null || score == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: charcoalBlack.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.sentiment_dissatisfied_outlined,
              color: charcoalBlack.withValues(alpha: 0.15),
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              isLoggedIn
                  ? period.loggedInEmptyMessage
                  : period.guestEmptyMessage,
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: charcoalBlack.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      );
    }

    final accentColor = switch (period) {
      RankingPeriod.daily => const Color(0xFF2563EB),
      RankingPeriod.weekly => GamePalette.colorFor(GameColor.coral),
      RankingPeriod.allTime => GamePalette.colorFor(GameColor.violet),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: charcoalBlack,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                period.tabLabel,
                style: AppTypography.label.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: charcoalBlack.withValues(alpha: 0.42),
                ),
              ),
              const Spacer(),
              if (period == RankingPeriod.weekly)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 12, color: charcoalBlack.withValues(alpha: 0.3)),
                    const SizedBox(width: 4),
                    Text(
                      weeklyResetInfo.koreanLabel,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: charcoalBlack.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  period.statusLabel,
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: charcoalBlack.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (period == RankingPeriod.weekly &&
              weeklySeasonSummary != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 14,
                  color: _seasonTierColor(weeklySeasonSummary!.tier),
                ),
                const SizedBox(width: 4),
                Text(
                  '${weeklySeasonSummary!.tier.label} TIER',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _seasonTierColor(weeklySeasonSummary!.tier),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$rank',
                style: GoogleFonts.blackHanSans(
                  fontSize: 36,
                  color: accentColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '위',
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  color: charcoalBlack.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 1,
                height: 22,
                color: charcoalBlack.withValues(alpha: 0.08),
              ),
              const SizedBox(width: 20),
              Text(
                '$score',
                style: GoogleFonts.blackHanSans(
                  fontSize: 36,
                  color: charcoalBlack,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '점',
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  color: charcoalBlack.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _seasonTierColor(SeasonTier tier) {
    return switch (tier) {
      SeasonTier.diamond => const Color(0xFF0EA5E9),
      SeasonTier.platinum => const Color(0xFF64748B),
      SeasonTier.gold => const Color(0xFFF59E0B),
      SeasonTier.silver => const Color(0xFF94A3B8),
      SeasonTier.bronze => const Color(0xFFB45309),
    };
  }
}
