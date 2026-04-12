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
  });

  final RankingPeriod period;
  final ValueChanged<RankingPeriod> onPeriodChanged;

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
              'RANKING',
              style: GoogleFonts.blackHanSans(
                fontSize: 28,
                letterSpacing: 2.0,
                color: charcoalBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: charcoalBlack, width: 2),
            boxShadow: const [
              BoxShadow(
                color: charcoalBlack,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: RankingPeriod.values
                .map(
                  (candidate) => Expanded(
                    child: _RankingPeriodButton(
                      label: candidate.tabLabel,
                      isActive: candidate == period,
                      onTap: () => onPeriodChanged(candidate),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
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

class _RankingPeriodButton extends StatelessWidget {
  const _RankingPeriodButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? GamePalette.colorFor(GameColor.azure) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isActive ? Border.all(color: charcoalBlack, width: 2) : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.label.copyWith(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
            color: isActive ? Colors.white : charcoalBlack.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
