import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/theme/app_typography.dart';
import 'package:hexor/widgets/home_screen/home_components.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.score,
    required this.bestScore,
    required this.isNewHighScore,
    required this.onRestart,
    required this.onReplay,
    required this.onShare,
    required this.onHome,
    required this.onRanking,
    required this.shareCardKey,
    required this.isSharing,
  });

  final int score;
  final int bestScore;
  final bool isNewHighScore;
  final VoidCallback onRestart;
  final VoidCallback onReplay;
  final VoidCallback onShare;
  final VoidCallback onHome;
  final VoidCallback onRanking;
  final GlobalKey shareCardKey;
  final bool isSharing;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: RepaintBoundary(
            key: shareCardKey,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: charcoalBlack, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: charcoalBlack,
                    offset: Offset(6, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: charcoalBlack, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: charcoalBlack,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        'GAME OVER',
                        style: GoogleFonts.blackHanSans(
                          fontSize: 18,
                          color: const Color(0xFFEF4444),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Score Section
                    Text(
                      '최종 점수',
                      style: GoogleFonts.blackHanSans(
                        fontSize: 16,
                        color: charcoalBlack.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$score',
                      style: GoogleFonts.blackHanSans(
                        fontSize: 84,
                        color: charcoalBlack,
                        height: 0.9,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Simple Best Score Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: charcoalBlack.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '최고 기록',
                            style: AppTypography.label.copyWith(
                              fontSize: 13,
                              color: charcoalBlack.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$bestScore',
                            style: GoogleFonts.blackHanSans(
                              fontSize: 24,
                              color: charcoalBlack,
                            ),
                          ),
                          if (isNewHighScore) ...[
                            const SizedBox(width: 10),
                            Text(
                              'NEW!',
                              style: GoogleFonts.blackHanSans(
                                color: const Color(0xFF3B82F6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Action Buttons
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: '리플레이',
                            icon: Icons.play_circle_outline_rounded,
                            onPressed: onReplay,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SecondaryButton(
                            label: isSharing ? '공유 중' : '공유하기',
                            icon: isSharing
                                ? Icons.hourglass_top_rounded
                                : Icons.ios_share_rounded,
                            onPressed: onShare,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
      ),
    );
  }
}
