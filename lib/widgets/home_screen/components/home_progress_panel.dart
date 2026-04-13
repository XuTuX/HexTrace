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
  });

  final AuthService authService;
  final Future<void> Function() onStartDaily;

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
    return Column(
      children: [
        _TodayPuzzleCard(
          isLoading: _isLoading,
          challenge: _dailyChallenge,
          isLoggedIn: widget.authService.user.value != null,
          onPressed: widget.onStartDaily,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Today's Puzzle — compact card
// ---------------------------------------------------------------------------

class _TodayPuzzleCard extends StatelessWidget {
  const _TodayPuzzleCard({
    required this.isLoading,
    required this.challenge,
    required this.isLoggedIn,
    required this.onPressed,
  });

  final bool isLoading;
  final DailyChallengeInfo? challenge;
  final bool isLoggedIn;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          // Header: dot + title + date pill
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '오늘의 퍼즐',
                style: GoogleFonts.blackHanSans(
                  fontSize: 16,
                  color: charcoalBlack,
                ),
              ),
              const Spacer(),
              if (challenge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    challenge!.displayDateLabel,
                    style: AppTypography.label.copyWith(
                      fontSize: 11,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: charcoalBlack,
            ),
          ),
        ),
      );
    }

    final hasUsedAttempt = challenge?.hasUsedEntry ?? false;

    // Not logged in
    if (!isLoggedIn) {
      return Text(
        '로그인 후 참여할 수 있어요',
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.w700,
          color: charcoalBlack.withValues(alpha: 0.52),
        ),
      );
    }

    // Completed — compact result row
    if (hasUsedAttempt) {
      return Row(
        children: [
          if (challenge?.myScore case final int score)
            Text(
              '${_formatScore(score)}점 달성',
              style: GoogleFonts.blackHanSans(
                fontSize: 15,
                color: charcoalBlack,
              ),
            )
          else
            Text(
              '도전 완료',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w800,
                color: charcoalBlack.withValues(alpha: 0.7),
              ),
            ),
          const Spacer(),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF059669),
            size: 20,
          ),
        ],
      );
    }

    // Available — short description + compact CTA
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '하루 한 번, 같은 시드로 경쟁!',
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: charcoalBlack.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => onPressed(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              '도전하기',
              style: GoogleFonts.blackHanSans(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  String _formatScore(int value) {
    final digits = value.toString();
    if (digits.length <= 3) return digits;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}



// ---------------------------------------------------------------------------
// Shared card shell
// ---------------------------------------------------------------------------

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.accent,
    required this.child,
  });

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.blackHanSans(
                  fontSize: 16,
                  color: charcoalBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
