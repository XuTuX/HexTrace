import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/theme/app_typography.dart';
import 'package:hexor/game/game_palette.dart';
import 'package:hexor/game/hex_game_controller.dart';

import '../ranking_period.dart';

class RankingSheetHandle extends StatelessWidget {
  const RankingSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: 48,
          height: 6,
          decoration: BoxDecoration(
            color: charcoalBlack.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class RankingHeader extends StatelessWidget {
  const RankingHeader({
    super.key,
    required this.period,
    required this.onPeriodChanged,
    this.isDailyOnly = false,
  });

  final RankingPeriod period;
  final ValueChanged<RankingPeriod> onPeriodChanged;
  final bool isDailyOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: GamePalette.colorFor(GameColor.amber),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isDailyOnly ? '오늘의 퍼즐 랭킹' : 'RANKING',
              style: GoogleFonts.blackHanSans(
                fontSize: isDailyOnly ? 18 : 20,
                letterSpacing: isDailyOnly ? 0.0 : 1.0,
                color: charcoalBlack,
              ),
            ),
          ],
        ),
        if (!isDailyOnly) ...[
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: charcoalBlack.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: RankingPeriod.values
                    .where((period) => period != RankingPeriod.daily)
                    .map<Widget>(
                      (candidate) {
                        final isActive = candidate == period;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => onPeriodChanged(candidate),
                            behavior: HitTestBehavior.opaque,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive
                                      ? charcoalBlack.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                candidate.tabLabel,
                                style: AppTypography.label.copyWith(
                                  fontSize: 13,
                                  fontWeight: isActive
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  color: isActive
                                      ? charcoalBlack
                                      : charcoalBlack.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class TopPlayersLabel extends StatelessWidget {
  const TopPlayersLabel({
    super.key,
    required this.period,
  });

  final RankingPeriod period;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          period.topPlayersLabel,
          style: AppTypography.label.copyWith(
            fontSize: 11,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w900,
            color: charcoalBlack.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: charcoalBlack.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}
