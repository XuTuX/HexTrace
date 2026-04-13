import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/game/game_palette.dart';
import 'package:hexor/game/hex_game_controller.dart';

import '../ranking_period.dart';

class RankingLoadingState extends StatelessWidget {
  const RankingLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: charcoalBlack,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'LOADING',
            style: GoogleFonts.blackHanSans(
              color: charcoalBlack.withValues(alpha: 0.2),
              fontSize: 16,
              letterSpacing: 1.5,
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
            size: 48,
            color: charcoalBlack.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 14),
          Text(
            period.emptyMessage,
            style: GoogleFonts.blackHanSans(
              color: charcoalBlack.withValues(alpha: 0.12),
              fontSize: 15,
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
            Icon(
              Icons.error_outline,
              color: charcoalBlack.withValues(alpha: 0.25),
              size: 36,
            ),
            const SizedBox(height: 16),
            Text(
              'FAILED TO LOAD',
              style: GoogleFonts.blackHanSans(
                color: charcoalBlack.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: charcoalBlack.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '다시 시도',
                  style: GoogleFonts.notoSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
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
