import 'package:flutter/material.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/widgets/home_screen/home_components.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.score,
    required this.bestScore,
    required this.isNewHighScore,
    required this.onRestart,
    required this.onHome,
    required this.onRanking,
  });

  final int score;
  final int bestScore;
  final bool isNewHighScore;
  final VoidCallback onRestart;
  final VoidCallback onHome;
  final VoidCallback onRanking;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: charcoalBlack.withValues(alpha: 0.72),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: charcoalBlack, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: charcoalBlack,
                  offset: Offset(6, 6),
                  blurRadius: 0,
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFDC2626), width: 2),
                    ),
                    child: const Text(
                      'GAME OVER',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFDC2626),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ScoreDisplay(
                        label: '최종 점수',
                        score: score,
                        color: const Color(0xFF16A34A),
                        isLarge: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ScoreDisplay(
                    label: '최고 기록',
                    score: bestScore,
                    color: charcoalBlack.withValues(alpha: 0.6),
                    isNew: isNewHighScore,
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: '홈',
                          icon: Icons.home_rounded,
                          onPressed: onHome,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SecondaryButton(
                          label: '랭킹',
                          icon: Icons.emoji_events_rounded,
                          onPressed: onRanking,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: '다시 시작하기',
                    onPressed: onRestart,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  const _ScoreDisplay({
    required this.label,
    required this.score,
    required this.color,
    this.isLarge = false,
    this.isNew = false,
  });

  final String label;
  final int score;
  final Color color;
  final bool isLarge;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: charcoalBlack.withValues(alpha: 0.45),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$score',
              style: TextStyle(
                fontSize: isLarge ? 48 : 24,
                fontWeight: FontWeight.w900,
                color: isNew ? const Color(0xFFDC2626) : color,
                height: 1,
              ),
            ),
            if (isNew) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
