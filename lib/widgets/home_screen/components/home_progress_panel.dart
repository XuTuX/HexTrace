import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_models.dart';
import 'package:hexor/services/database_service.dart';
import 'package:hexor/services/progress_service.dart';
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
  WeeklySeasonSummary? _seasonSummary;
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
    await Get.find<ProgressService>().refresh();

    try {
      final dailyFuture = dbService.getDailyChallenge(gameId);
      final seasonFuture = widget.authService.user.value == null
          ? Future<WeeklySeasonSummary?>.value(null)
          : dbService.getWeeklySeasonSummary(gameId);
      final results = await Future.wait([dailyFuture, seasonFuture]);

      if (!mounted) {
        return;
      }

      setState(() {
        _dailyChallenge = results[0] as DailyChallengeInfo;
        _seasonSummary = results[1] as WeeklySeasonSummary?;
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
    final progressService = Get.find<ProgressService>();

    return Column(
      children: [
        _TodayPuzzleCard(
          isLoading: _isLoading,
          challenge: _dailyChallenge,
          isLoggedIn: widget.authService.user.value != null,
          onPressed: widget.onStartDaily,
        ),
        const SizedBox(height: 14),
        Obx(
          () => _MissionsCard(
            missions: progressService.dailyMissions.toList(growable: false),
          ),
        ),
        const SizedBox(height: 14),
        _SeasonTierCard(
          seasonSummary: _seasonSummary,
          isLoggedIn: widget.authService.user.value != null,
        ),
      ],
    );
  }
}

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
    final hasUsedAttempt = challenge?.hasUsedOfficialAttempt ?? false;
    final buttonLabel =
        isLoggedIn && !hasUsedAttempt ? '오늘의 퍼즐 도전' : '오늘의 퍼즐 연습';
    final subtitle = switch ((isLoggedIn, hasUsedAttempt, challenge?.myScore)) {
      (true, false, _) => '하루 한 번 모두가 같은 시드로 경쟁해요.',
      (true, true, final int myScore?) =>
        '오늘 공식 기록 $myScore점 제출 완료. 같은 시드로 계속 연습할 수 있어요.',
      (true, true, _) => '오늘의 공식 기록은 이미 사용했어요. 같은 시드로 연습할 수 있어요.',
      (false, _, _) => '로그인하면 오늘의 공식 랭킹에 참가할 수 있어요.',
    };

    return _PanelCard(
      title: '오늘의 퍼즐',
      accent: const Color(0xFF2563EB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: charcoalBlack,
                  ),
                ),
              ),
            )
          else ...[
            if (challenge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w700,
                color: charcoalBlack.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onPressed();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: GoogleFonts.blackHanSans(fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MissionsCard extends StatelessWidget {
  const _MissionsCard({required this.missions});

  final List<MissionProgress> missions;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: '오늘의 미션',
      accent: const Color(0xFF059669),
      child: Column(
        children: missions
            .map(
              (mission) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      mission.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: mission.isCompleted
                          ? const Color(0xFF059669)
                          : charcoalBlack.withValues(alpha: 0.25),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission.definition.title,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w900,
                              color: charcoalBlack,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mission.definition.description,
                            style: AppTypography.bodySmall.copyWith(
                              color: charcoalBlack.withValues(alpha: 0.52),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SeasonTierCard extends StatelessWidget {
  const _SeasonTierCard({
    required this.seasonSummary,
    required this.isLoggedIn,
  });

  final WeeklySeasonSummary? seasonSummary;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    final tier = seasonSummary?.tier;
    final label = switch ((isLoggedIn, seasonSummary?.rank, tier)) {
      (false, _, _) => '로그인하면 주간 시즌 티어를 받을 수 있어요.',
      (true, null, _) => '이번 주 첫 기록을 남기면 시즌 티어가 정해집니다.',
      (true, final int rank?, final SeasonTier tier?) =>
        '${tier.label} 티어 · 현재 $rank위',
      _ => '이번 주 시즌 데이터를 불러오는 중입니다.',
    };

    return _PanelCard(
      title: '주간 시즌',
      accent: const Color(0xFFF59E0B),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _tierColor(tier).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 34,
              color: _tierColor(tier),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier?.label ?? 'UNRANKED',
                  style: GoogleFonts.blackHanSans(
                    fontSize: 18,
                    color: charcoalBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: charcoalBlack.withValues(alpha: 0.7),
                  ),
                ),
                if (seasonSummary?.participantCount case final int count
                    when count > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '참가자 $count명',
                    style: AppTypography.bodySmall.copyWith(
                      color: charcoalBlack.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _tierColor(SeasonTier? tier) {
    return switch (tier) {
      SeasonTier.diamond => const Color(0xFF38BDF8),
      SeasonTier.platinum => const Color(0xFF64748B),
      SeasonTier.gold => const Color(0xFFF59E0B),
      SeasonTier.silver => const Color(0xFF94A3B8),
      _ => const Color(0xFFB45309),
    };
  }
}

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
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
