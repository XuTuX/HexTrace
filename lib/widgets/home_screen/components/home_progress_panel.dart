import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_models.dart';
import 'package:hexor/services/database_service.dart';
import 'package:hexor/theme/app_typography.dart';

class HomeProgressPanel extends StatefulWidget {
  const HomeProgressPanel({
    super.key,
    required this.authService,
    required this.onStartDaily,
    required this.onShowDailyRanking,
  });

  final AuthService authService;
  final Future<void> Function() onStartDaily;
  final VoidCallback onShowDailyRanking;

  @override
  State<HomeProgressPanel> createState() => _HomeProgressPanelState();
}

class _HomeProgressPanelState extends State<HomeProgressPanel> {
  bool _isLoading = true;
  DailyChallengeInfo? _dailyChallenge;
  late final Worker _authWorker;

  @override
  void initState() {
    super.initState();
    _load();
    _authWorker = ever(widget.authService.user, (_) => _load());
  }

  @override
  void dispose() {
    _authWorker.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final dbService = Get.find<DatabaseService>();

    try {
      final daily = await dbService.getDailyChallenge(gameId);

      if (!mounted) {
        return;
      }

      setState(() {
        _dailyChallenge = daily;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TodayPuzzleCard(
      isLoading: _isLoading,
      challenge: _dailyChallenge,
      isLoggedIn: widget.authService.user.value != null,
      onPressed: widget.onStartDaily,
      onShowRanking: widget.onShowDailyRanking,
    );
  }
}

class _TodayPuzzleCard extends StatelessWidget {
  const _TodayPuzzleCard({
    required this.isLoading,
    required this.challenge,
    required this.isLoggedIn,
    required this.onPressed,
    required this.onShowRanking,
  });

  final bool isLoading;
  final DailyChallengeInfo? challenge;
  final bool isLoggedIn;
  final Future<void> Function() onPressed;
  final VoidCallback onShowRanking;

  @override
  Widget build(BuildContext context) {
    final hasUsedAttempt = challenge?.hasUsedEntry ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading
            ? null
            : () {
                if (hasUsedAttempt) {
                  onShowRanking();
                } else {
                  onPressed();
                }
              },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: charcoalBlack, width: 2),
            boxShadow: const [
              BoxShadow(
                color: charcoalBlack,
                offset: Offset(4, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '오늘의 퍼즐',
                    style: GoogleFonts.blackHanSans(
                      fontSize: 16,
                      color: charcoalBlack,
                    ),
                  ),
                  const Spacer(),
                  _RankingShortcut(
                    onTap: onShowRanking,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: charcoalBlack,
            ),
          ),
        ),
      );
    }

    final hasUsedAttempt = challenge?.hasUsedEntry ?? false;

    if (!isLoggedIn) {
      return Row(
        children: [
          Expanded(
            child: Text(
              '로그인 후 하루 한 번 참여 가능',
              style: AppTypography.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: charcoalBlack.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.chevron_right_rounded,
            color: charcoalBlack38,
          ),
        ],
      );
    }

    if (hasUsedAttempt) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘 기록',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: charcoalBlack.withValues(alpha: 0.42),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge?.myScore != null
                      ? '${_formatScore(challenge!.myScore!)}점'
                      : '도전 완료',
                  style: GoogleFonts.blackHanSans(
                    fontSize: 24,
                    color: charcoalBlack,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '랭킹 보기',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0369A1),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF0369A1),
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '하루 한 번 도전',
                style: GoogleFonts.blackHanSans(
                  fontSize: 22,
                  color: charcoalBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '공식 기록이 오늘 랭킹에 반영돼요',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: charcoalBlack.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 4),
              Text(
                '시작',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatScore(int value) {
    final digits = value.toString();
    if (digits.length <= 3) {
      return digits;
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

class _RankingShortcut extends StatelessWidget {
  const _RankingShortcut({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: charcoalBlack.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '랭킹',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: charcoalBlack.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: charcoalBlack.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}
