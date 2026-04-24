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
                  _AnimatedPlayButton(
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

class _AnimatedPlayButton extends StatefulWidget {
  const _AnimatedPlayButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  State<_AnimatedPlayButton> createState() => _AnimatedPlayButtonState();
}

class _AnimatedPlayButtonState extends State<_AnimatedPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        height: isTablet ? 80 : 68,
        decoration: BoxDecoration(
          color: charcoalBlack,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: charcoalBlack,
              offset: Offset(5, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0095FF),
            foregroundColor: Colors.white,
            elevation: 0,
            side: const BorderSide(color: charcoalBlack, width: 2.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isTablet ? 40 : 36,
                height: isTablet ? 40 : 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: isTablet ? 28 : 24,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: isTablet ? 14 : 12),
              Text(
                '게임 시작',
                style: GoogleFonts.blackHanSans(
                  fontSize: isTablet ? 28 : 25,
                  letterSpacing: 0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
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
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final maxWidth = isTablet ? 360.0 : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              final labels = ['플레이', '오늘의 창'];
              final icons = [
                Icons.sports_esports_rounded,
                Icons.auto_awesome_rounded,
              ];
              final activeColors = [
                const Color(0xFF0095FF),
                const Color(0xFFF59E0B),
              ];
              final isActive = activeIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isActive
                          ? activeColors[index]
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: isActive
                          ? Border.all(color: charcoalBlack, width: 2)
                          : null,
                      boxShadow: isActive
                          ? const [
                              BoxShadow(
                                color: charcoalBlack,
                                offset: Offset(2, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icons[index],
                          size: 17,
                          color: isActive
                              ? Colors.white
                              : charcoalBlack.withValues(alpha: 0.32),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          labels[index],
                          style: GoogleFonts.blackHanSans(
                            fontSize: 14,
                            color: isActive
                                ? Colors.white
                                : charcoalBlack.withValues(alpha: 0.32),
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
        ),
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE0F2FE),
                      Color(0xFFBAE6FD),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0369A1).withValues(alpha: 0.15),
                    width: 1,
                  ),
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
