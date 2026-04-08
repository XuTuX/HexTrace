import 'package:flutter/material.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/theme/app_typography.dart';

class RankingLoadingState extends StatelessWidget {
  const RankingLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: charcoalBlack,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'LOADING...',
            style: AppTypography.label.copyWith(
              color: charcoalBlack.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyRankingState extends StatelessWidget {
  const EmptyRankingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'NO RANKING DATA',
        style: AppTypography.label.copyWith(
          color: charcoalBlack.withValues(alpha: 0.2),
          fontSize: 14,
          letterSpacing: 2.0,
        ),
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
            Text(
              'RANKING LOAD FAILED',
              style: AppTypography.label.copyWith(
                color: charcoalBlack.withValues(alpha: 0.35),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
