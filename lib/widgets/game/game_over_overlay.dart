import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/theme/app_typography.dart';
import 'package:hexor/widgets/home_screen/home_components.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.runSummary,
    required this.bestScore,
    required this.isNewHighScore,
    required this.onRestart,
    required this.onReplay,
    required this.onShare,
    required this.onHome,
    required this.onRanking,
    required this.isSharing,
    this.dailyStatusLabel,
    this.dailyStatusDetail,
    this.completedMissionTitles = const [],
    this.unlockedAchievementTitles = const [],
  });

  final GameRunSummary runSummary;
  final int bestScore;
  final bool isNewHighScore;
  final VoidCallback onRestart;
  final VoidCallback onReplay;
  final VoidCallback onShare;
  final VoidCallback onHome;
  final VoidCallback onRanking;
  final bool isSharing;
  final String? dailyStatusLabel;
  final String? dailyStatusDetail;
  final List<String> completedMissionTitles;
  final List<String> unlockedAchievementTitles;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(29.5),
              child: Stack(
                children: [
                  Positioned(
                    top: -20,
                    right: -20,
                    child: _DecorativeHexagon(
                      size: 100,
                      color: regionColors[0].withValues(alpha: 0.05),
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    left: -30,
                    child: _DecorativeHexagon(
                      size: 80,
                      color: regionColors[4].withValues(alpha: 0.05),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 40,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        if (runSummary.isDailyMode &&
                            dailyStatusLabel != null &&
                            dailyStatusDetail != null) ...[
                          _DailyStatusCard(
                            label: dailyStatusLabel!,
                            detail: dailyStatusDetail!,
                          ),
                          const SizedBox(height: 20),
                        ],
                        _buildScoreSection(),
                        const SizedBox(height: 20),
                        _SummaryGrid(runSummary: runSummary),
                        if (completedMissionTitles.isNotEmpty ||
                            unlockedAchievementTitles.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _ProgressHighlights(
                            completedMissionTitles: completedMissionTitles,
                            unlockedAchievementTitles:
                                unlockedAchievementTitles,
                          ),
                        ],
                        const SizedBox(height: 28),
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
                          label: runSummary.isDailyMode
                              ? '홈으로 돌아가기'
                              : '다시 시작하기',
                          onPressed: onRestart,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
    );
  }

  Widget _buildScoreSection() {
    return Column(
      children: [
        Text(
          '최종 점수',
          style: GoogleFonts.blackHanSans(
            fontSize: 16,
            color: charcoalBlack.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${runSummary.score}',
          style: GoogleFonts.blackHanSans(
            fontSize: 84,
            color: charcoalBlack,
            height: 0.9,
          ),
        ),
        const SizedBox(height: 20),
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
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.runSummary});

  final GameRunSummary runSummary;

  @override
  Widget build(BuildContext context) {
    final bestMove = runSummary.bestMove;
    final bestMoveValue = bestMove == null
        ? '기록 없음'
        : bestMove.combo > 1
            ? '${bestMove.pathLength}칸 / ${bestMove.scoreGained}점 / x${bestMove.combo}'
            : '${bestMove.pathLength}칸 / ${bestMove.scoreGained}점';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryStatCard(
                label: '최대 콤보',
                value: '${runSummary.maxCombo}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryStatCard(
                label: '최장 경로',
                value: '${runSummary.longestPathLength}칸',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryStatCard(
                label: '남은 시간',
                value: '${runSummary.remainingTime.ceil()}초',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryStatCard(
                label: '실수',
                value: '${runSummary.invalidAttemptCount}회',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryStatCard(
          label: '베스트 무브',
          value: bestMoveValue,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: charcoalBlack.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment:
            fullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.label.copyWith(
              fontSize: 12,
              color: charcoalBlack.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: fullWidth ? TextAlign.left : TextAlign.center,
            style: GoogleFonts.blackHanSans(
              fontSize: fullWidth ? 18 : 22,
              color: charcoalBlack,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyStatusCard extends StatelessWidget {
  const _DailyStatusCard({
    required this.label,
    required this.detail,
  });

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: charcoalBlack, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.blackHanSans(
              fontSize: 16,
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: AppTypography.body.copyWith(
              color: charcoalBlack.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHighlights extends StatelessWidget {
  const _ProgressHighlights({
    required this.completedMissionTitles,
    required this.unlockedAchievementTitles,
  });

  final List<String> completedMissionTitles;
  final List<String> unlockedAchievementTitles;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: charcoalBlack.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (completedMissionTitles.isNotEmpty) ...[
            Text(
              '오늘의 미션 완료',
              style: GoogleFonts.blackHanSans(
                fontSize: 14,
                color: const Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: completedMissionTitles
                  .map((title) => _HighlightChip(
                        label: title,
                        color: const Color(0xFFDCFCE7),
                      ))
                  .toList(growable: false),
            ),
          ],
          if (completedMissionTitles.isNotEmpty &&
              unlockedAchievementTitles.isNotEmpty)
            const SizedBox(height: 14),
          if (unlockedAchievementTitles.isNotEmpty) ...[
            Text(
              '새 업적 해금',
              style: GoogleFonts.blackHanSans(
                fontSize: 14,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unlockedAchievementTitles
                  .map((title) => _HighlightChip(
                        label: title,
                        color: const Color(0xFFFEF3C7),
                      ))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: charcoalBlack.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w900,
          color: charcoalBlack,
        ),
      ),
    );
  }
}

class _DecorativeHexagon extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeHexagon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.5,
      child: Icon(
        Icons.hexagon_rounded,
        size: size,
        color: color,
      ),
    );
  }
}
