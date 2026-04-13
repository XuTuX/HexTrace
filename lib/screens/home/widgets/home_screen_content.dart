import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:hexor/widgets/home_screen/background_painter.dart';
import 'package:hexor/widgets/home_screen/home_components.dart';

class HomeScreenContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final isTablet = mediaSize.shortestSide >= 600;
    final horizontalPadding = isTablet ? 32.0 : 24.0;
    final contentMaxWidth = isTablet ? 640.0 : 520.0;

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: contentMaxWidth,
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: isTablet ? 18 : 10),
                          Row(
                            children: [
                              Expanded(
                                child: _HomeProfileChip(
                                  authService: authService,
                                ),
                              ),
                              const SizedBox(width: 12),
                              TopIconButton(
                                icon: Icons.settings_rounded,
                                onTap: onSettingsTap,
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 28 : 20),
                          PrimaryButton(
                            label: '게임 시작',
                            icon: Icons.play_arrow_rounded,
                            onPressed: onStartGame,
                          ),
                          SizedBox(height: isTablet ? 18 : 14),
                          ScoreDisplay(
                            scoreController: scoreController,
                            authService: authService,
                          ),
                          SizedBox(height: isTablet ? 12 : 10),
                          HomeProgressPanel(
                            authService: authService,
                            onStartDaily: onStartDaily,
                            onShowDailyRanking: onShowDailyRanking,
                          ),
                          SizedBox(height: isTablet ? 12 : 10),
                          WeeklyRankingPreview(
                            onViewAll: onRankingTap,
                          ),
                          SizedBox(height: isTablet ? 24 : 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: charcoalBlack.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: Color(0xFF0369A1),
                ),
              ),
              const SizedBox(width: 10),
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
                        color: charcoalBlack.withValues(alpha: 0.35),
                      ),
                    ),
                    Text(
                      hasNickname ? nickname : '게스트',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.blackHanSans(
                        fontSize: 16,
                        color: charcoalBlack,
                        height: 1.0,
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
