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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GamePalette.colorFor(GameColor.amber),
                shape: BoxShape.circle,
                border: Border.all(color: charcoalBlack, width: 2),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isDailyOnly ? '오늘의 퍼즐 랭킹' : 'RANKING',
              style: GoogleFonts.blackHanSans(
                fontSize: isDailyOnly ? 22 : 28,
                letterSpacing: isDailyOnly ? 0.0 : 2.0,
                color: charcoalBlack,
              ),
            ),
          ],
        ),
        if (!isDailyOnly) ...[
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: charcoalBlack, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: charcoalBlack,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
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
                              color: isActive
                                  ? GamePalette.colorFor(GameColor.azure)
                                  : Colors.transparent,
                              alignment: Alignment.center,
                              child: Text(
                                candidate.tabLabel,
                                style: AppTypography.label.copyWith(
                                  fontSize: 14,
                                  fontWeight: isActive
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : charcoalBlack.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                    .expand((widget) => [
                          widget,
                          Container(width: 2, color: charcoalBlack),
                        ])
                    .toList()
                  ..removeLast(),
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
            fontSize: 12,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w900,
            color: charcoalBlack.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 2,
            color: charcoalBlack.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}
