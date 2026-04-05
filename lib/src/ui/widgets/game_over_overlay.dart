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
      color: charcoalBlack.withValues(alpha: 0.56),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: charcoalBlack, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: charcoalBlack,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 32, 22, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '게임 종료',
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.w900,
                      color: charcoalBlack,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '최종 점수 $score',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isNewHighScore ? '새 최고 기록!' : '최고 점수 $bestScore',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isNewHighScore 
                          ? const Color(0xFFDC2626) 
                          : charcoalBlack.withValues(alpha: 0.84),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '시간이 끝났거나 더 이상 가능한 경로가 없어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: charcoalBlack.withValues(alpha: 0.72),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 32),
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
                    label: '다시 시작',
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
