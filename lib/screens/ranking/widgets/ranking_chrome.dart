import 'package:flutter/material.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/theme/app_typography.dart';

class RankingSheetHandle extends StatelessWidget {
  const RankingSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class RankingHeader extends StatelessWidget {
  const RankingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.emoji_events_outlined,
          color: charcoalBlack,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'RANKING',
          style: AppTypography.title.copyWith(
            fontSize: 20,
            letterSpacing: 4.0,
            color: charcoalBlack,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class TopPlayersLabel extends StatelessWidget {
  const TopPlayersLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'TOP PLAYERS',
          style: AppTypography.label.copyWith(
            fontSize: 11,
            letterSpacing: 2.0,
            color: charcoalBlack.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 0.5,
            color: charcoalBlack.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}
