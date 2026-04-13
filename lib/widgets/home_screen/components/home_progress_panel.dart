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
    return _TodayPuzzleCard(
      isLoading: _isLoading,
      challenge: _dailyChallenge,
      isLoggedIn: widget.authService.user.value != null,
      onPressed: widget.onStartDaily,
    );
  }
}

// ---------------------------------------------------------------------------
// Today's Puzzle — compact card (designed for side-by-side layout)
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

  bool get _isAvailable =>
      !isLoading && isLoggedIn && !(challenge?.hasUsedEntry ?? false);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isAvailable ? () => onPressed() : null,
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
              offset: Offset(3, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header: dot + title
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
                Flexible(
                  child: Text(
                    '오늘의 퍼즐',
                    style: GoogleFonts.blackHanSans(
                      fontSize: 14,
                      color: charcoalBlack,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildContent(),
          ],
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

    // Not logged in
    if (!isLoggedIn) {
      return Text(
        '로그인 후 참여 가능',
        style: AppTypography.body.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: charcoalBlack.withValues(alpha: 0.45),
        ),
      );
    }

    // Completed — compact result row
    if (hasUsedAttempt) {
      return Row(
        children: [
          if (challenge?.myScore case final int score)
            Expanded(
              child: Text(
                '${_formatScore(score)}점',
                style: GoogleFonts.blackHanSans(
                  fontSize: 14,
                  color: charcoalBlack,
                ),
              ),
            )
          else
            Expanded(
              child: Text(
                '도전 완료',
                style: AppTypography.body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: charcoalBlack.withValues(alpha: 0.7),
                ),
              ),
            ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF059669),
            size: 18,
          ),
        ],
      );
    }

    // Available — compact with play icon (card is tappable)
    return Row(
      children: [
        Expanded(
          child: Text(
            '하루 한 번 도전!',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: charcoalBlack.withValues(alpha: 0.55),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 16,
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

