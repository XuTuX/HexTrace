import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:hexor/widgets/home_screen/background_painter.dart';
import 'package:hexor/widgets/home_screen/home_components.dart';

import 'daily_ranking_calendar_page.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({
    super.key,
    required this.scoreController,
    required this.authService,
    required this.onSettingsTap,
    required this.onStartGame,
    required this.onStartDaily,
    required this.onShowDailyRanking,
    required this.onRankingTap,
  });

  final ScoreController scoreController;
  final AuthService authService;
  final VoidCallback onSettingsTap;
  final VoidCallback onStartGame;
  final Future<void> Function() onStartDaily;
  final VoidCallback onShowDailyRanking;
  final VoidCallback onRankingTap;

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridPatternPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _pageIndex = index);
                    },
                    children: [
                      _HomeDashboardPage(
                        scoreController: widget.scoreController,
                        authService: widget.authService,
                        onSettingsTap: widget.onSettingsTap,
                        onStartGame: widget.onStartGame,
                        onRankingTap: widget.onRankingTap,
                      ),
                      DailyRankingCalendarPage(
                        scoreController: widget.scoreController,
                        authService: widget.authService,
                        onStartDaily: widget.onStartDaily,
                        onShowDailyRanking: widget.onShowDailyRanking,
                        onRankingTap: widget.onRankingTap,
                      ),
                    ],
                  ),
                ),
                _HomePageTabs(
                  activeIndex: _pageIndex,
                  onTap: (index) {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeDashboardPage extends StatelessWidget {
  const _HomeDashboardPage({
    required this.scoreController,
    required this.authService,
    required this.onSettingsTap,
    required this.onStartGame,
    required this.onRankingTap,
  });

  final ScoreController scoreController;
  final AuthService authService;
  final VoidCallback onSettingsTap;
  final VoidCallback onStartGame;
  final VoidCallback onRankingTap;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final isTablet = mediaSize.shortestSide >= 600;
    final viewportHeight = mediaSize.height;
    final horizontalPadding = isTablet ? 40.0 : 24.0;
    final contentMaxWidth = isTablet ? 680.0 : 480.0;
    final topSpacing = isTablet ? 30.0 : 16.0;
    final sectionGap = isTablet ? 20.0 : 16.0;
    final compactVertical = viewportHeight < 760;
    final heroGap = compactVertical ? 18.0 : (isTablet ? 38.0 : 28.0);
    final actionGap = compactVertical ? 12.0 : 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            isTablet ? 36 : 22,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: contentMaxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: topSpacing),
                          Row(
                            children: [
                              Expanded(
                                child:
                                    _HomeProfileChip(authService: authService),
                              ),
                              const SizedBox(width: 12),
                              TopIconButton(
                                icon: Icons.settings_rounded,
                                onTap: onSettingsTap,
                              ),
                            ],
                          ),
                          SizedBox(height: heroGap),
                          _HomeHero(
                            scoreController: scoreController,
                            authService: authService,
                          ),
                          SizedBox(height: sectionGap),
                          WeeklyRankingPreview(
                            isAllTime: true,
                            onViewAll: onRankingTap,
                          ),
                          SizedBox(height: actionGap),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: '게임 시작',
                    icon: Icons.play_arrow_rounded,
                    onPressed: onStartGame,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.scoreController,
    required this.authService,
  });

  final ScoreController scoreController;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CompactHomeLogo(),
        const SizedBox(height: 18),
        ScoreDisplay(
          scoreController: scoreController,
          authService: authService,
        ),
      ],
    );
  }
}

class _HomePageTabs extends StatelessWidget {
  const _HomePageTabs({
    required this.activeIndex,
    required this.onTap,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: charcoalBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(2, (index) {
          final labels = ['플레이', '오늘'];
          final icons = [
            Icons.play_arrow_rounded,
            Icons.calendar_today_rounded,
          ];
          final isActive = activeIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive ? charcoalBlack : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      size: 16,
                      color: isActive ? Colors.white : charcoalBlack54,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      labels[index],
                      style: GoogleFonts.blackHanSans(
                        fontSize: 14,
                        color: isActive ? Colors.white : charcoalBlack54,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _HomeProfileChip extends StatelessWidget {
  const _HomeProfileChip({
    required this.authService,
  });

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final nickname = authService.userNickname.value?.trim();
      final hasNickname = nickname != null && nickname.isNotEmpty;

      return GestureDetector(
        onTap: hasNickname
            ? () {
                Get.dialog(
                  EditNicknameDialog(
                    currentNickname: nickname,
                    onSave: (newNickname) async {
                      return authService.updateNickname(newNickname);
                    },
                  ),
                  barrierDismissible: false,
                );
              }
            : null,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: charcoalBlack, width: 2),
            boxShadow: const [
              BoxShadow(
                color: charcoalBlack,
                offset: Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: Color(0xFF0369A1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '플레이어',
                      style: GoogleFonts.notoSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: charcoalBlack.withValues(alpha: 0.38),
                      ),
                    ),
                    Text(
                      hasNickname ? nickname : '게스트',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.blackHanSans(
                        fontSize: 17,
                        color: charcoalBlack,
                        height: 1.0,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasNickname)
                Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: charcoalBlack.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      );
    });
  }
}
