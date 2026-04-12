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
    final statusText =
        period == RankingPeriod.weekly && weeklySeasonSummary != null
            ? '${weeklySeasonSummary!.tier.label} TIER'
            : period.statusLabel;

    if (rank == null || score == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: charcoalBlack.withValues(alpha: 0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: charcoalBlack.withValues(alpha: 0.05),
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.sentiment_dissatisfied_outlined,
              color: charcoalBlack.withValues(alpha: 0.2),
              size: 32,
            ),
            const SizedBox(height: 12),
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
      RankingPeriod.daily => GamePalette.colorFor(GameColor.azure),
      RankingPeriod.weekly => GamePalette.colorFor(GameColor.coral),
      RankingPeriod.allTime => GamePalette.colorFor(GameColor.violet),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
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
            offset: Offset(6, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: charcoalBlack, width: 1.5),
                ),
                child: Text(
                  period.tabLabel,
                  style: AppTypography.label.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                statusText,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: charcoalBlack.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          if (period == RankingPeriod.weekly) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: charcoalBlack.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: charcoalBlack.withValues(alpha: 0.08), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 14, color: charcoalBlack),
                  const SizedBox(width: 6),
                  Text(
                    weeklyResetInfo.koreanLabel,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: charcoalBlack.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (weeklySeasonSummary != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _seasonTierColor(weeklySeasonSummary!.tier)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 16,
                      color: _seasonTierColor(weeklySeasonSummary!.tier),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${weeklySeasonSummary!.tier.label} · 참가자 ${weeklySeasonSummary!.participantCount}명',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: charcoalBlack.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$rank',
                style: GoogleFonts.blackHanSans(
                  fontSize: 44,
                  color: accentColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '위',
                style: AppTypography.body.copyWith(
                  fontSize: 16,
                  color: charcoalBlack,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 24),
              Container(
                width: 2,
                height: 30,
                color: charcoalBlack.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 24),
              Text(
                '$score',
                style: GoogleFonts.blackHanSans(
                  fontSize: 44,
                  color: charcoalBlack,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '점',
                style: AppTypography.body.copyWith(
                  fontSize: 16,
                  color: charcoalBlack,
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
