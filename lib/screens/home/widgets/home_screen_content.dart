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
    required this.onStartDailyTest,
    required this.onShowDailyRanking,
    required this.onRankingTap,
  });

  final ScoreController scoreController;
  final AuthService authService;
  final VoidCallback onSettingsTap;
  final VoidCallback onStartGame;
  final Future<void> Function() onStartDaily;
  final Future<void> Function() onStartDailyTest;
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
                        onStartDailyTest: widget.onStartDailyTest,
                        onShowDailyRanking: widget.onShowDailyRanking,
                        onRankingTap: widget.onRankingTap,
                        isVisible: _pageIndex == 1,
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
    final sw = mediaSize.width;
    final sh = mediaSize.height;
    final horizontalPadding = isTablet
        ? (sw * 0.06).clamp(32.0, 60.0)
        : (sw * 0.06).clamp(16.0, 28.0);
    final contentMaxWidth = isTablet ? 680.0 : 480.0;
    final topSpacing = isTablet
        ? (sh * 0.025).clamp(20.0, 40.0)
        : (sh * 0.018).clamp(8.0, 20.0);
    final sectionGap = isTablet
        ? (sh * 0.022).clamp(16.0, 28.0)
        : (sh * 0.02).clamp(12.0, 22.0);
    final bottomPad = isTablet
        ? (sh * 0.03).clamp(24.0, 44.0)
        : (sh * 0.025).clamp(14.0, 26.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            bottomPad,
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
                          // Top bar: nickname + settings
                          _TopBar(
                            authService: authService,
                            onSettingsTap: onSettingsTap,
                          ),
                          SizedBox(height: sectionGap + 12),
                          // Score hero card
                          ScoreDisplay(
                            scoreController: scoreController,
                            authService: authService,
                          ),
                          SizedBox(height: sectionGap + 10),
                          // Ranking TOP 3
                          WeeklyRankingPreview(
                            isAllTime: true,
                            onViewAll: onRankingTap,
                          ),
                          SizedBox(height: sectionGap * 0.8),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: sectionGap * 0.8),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.authService,
    required this.onSettingsTap,
  });

  final AuthService authService;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final titleFs = (sw * 0.052).clamp(16.0, 24.0);

    return Obx(() {
      final nickname = authService.userNickname.value?.trim();
      final hasNickname = nickname != null && nickname.isNotEmpty;

      return Row(
        children: [
          Expanded(
            child: GestureDetector(
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
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      hasNickname ? nickname : 'BEE HOUSE',
                      style: GoogleFonts.blackHanSans(
                        fontSize: titleFs,
                        color: charcoalBlack,
                        height: 1.0,
                        letterSpacing: 0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasNickname) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: charcoalBlack.withValues(alpha: 0.2),
                    ),
                  ],
                ],
              ),
            ),
          ),
          TopIconButton(
            icon: Icons.settings_rounded,
            onTap: onSettingsTap,
          ),
        ],
      );
    });
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
    final ms = MediaQuery.sizeOf(context);
    final isTablet = ms.shortestSide >= 600;
    final btnH = isTablet
        ? (ms.height * 0.07).clamp(64.0, 88.0)
        : (ms.height * 0.078).clamp(52.0, 72.0);
    final btnFs = isTablet
        ? (ms.width * 0.032).clamp(22.0, 30.0)
        : (ms.width * 0.06).clamp(18.0, 26.0);
    final br = isTablet ? 28.0 : (ms.width * 0.06).clamp(18.0, 26.0);

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
        height: btnH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(br),
          boxShadow: const [
            BoxShadow(
              color: charcoalBlack,
              offset: Offset(3, 3),
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
            side: const BorderSide(color: charcoalBlack, width: 2.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(br),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            '게임 시작',
            style: GoogleFonts.blackHanSans(
              fontSize: btnFs,
              letterSpacing: 0,
              color: Colors.white,
            ),
          ),
        ),
      ),
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
    final ms = MediaQuery.sizeOf(context);
    final isTablet = ms.shortestSide >= 600;
    final maxWidth = isTablet ? 360.0 : double.infinity;
    final hMargin = isTablet
        ? (ms.width * 0.04).clamp(20.0, 40.0)
        : (ms.width * 0.06).clamp(16.0, 28.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: hMargin),
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
              final labels = ['플레이', '오늘의 도전'];
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
                      color:
                          isActive ? activeColors[index] : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
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
