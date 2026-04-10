import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:linkagon/constant.dart';
import 'package:linkagon/theme/app_typography.dart';
import 'package:linkagon/game/game_palette.dart';
import 'package:linkagon/game/hex_game_controller.dart';

import '../ranking_period.dart';

class RankingLoadingState extends StatelessWidget {
  const RankingLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: GamePalette.colorFor(GameColor.azure),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'LOADING',
            style: GoogleFonts.blackHanSans(
              color: charcoalBlack.withValues(alpha: 0.3),
              fontSize: 20,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyRankingState extends StatelessWidget {
  const EmptyRankingState({
    super.key,
    required this.period,
  });

  final RankingPeriod period;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: charcoalBlack.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            period.emptyMessage,
            style: GoogleFonts.blackHanSans(
              color: charcoalBlack.withValues(alpha: 0.15),
              fontSize: 18,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class RankingErrorState extends StatelessWidget {
  const RankingErrorState({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GamePalette.colorFor(GameColor.coral).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: GamePalette.colorFor(GameColor.coral),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'FAILED TO LOAD',
              style: GoogleFonts.blackHanSans(
                color: charcoalBlack,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
                child: Text(
                  '다시 시도',
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: charcoalBlack,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
