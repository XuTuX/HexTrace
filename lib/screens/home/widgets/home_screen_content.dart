import 'package:flutter/material.dart';

import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/services/auth_service.dart';
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
    required this.onRankingTap,
  });

  final ScoreController scoreController;
  final AuthService authService;
  final VoidCallback onSettingsTap;
  final VoidCallback onStartGame;
  final Future<void> Function() onStartDaily;
  final VoidCallback onRankingTap;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final isTablet = mediaSize.shortestSide >= 600;
    final horizontalPadding = isTablet ? 32.0 : 24.0;
    final contentMaxWidth = isTablet ? 720.0 : 680.0;

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
                          SizedBox(height: isTablet ? 16 : 8),
                          // Top bar: compact logo + settings
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const CompactHomeLogo(),
                              const Spacer(),
                              TopIconButton(
                                icon: Icons.settings_rounded,
                                onTap: onSettingsTap,
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 22 : 16),
                          // Score display
                          ScoreDisplay(
                            scoreController: scoreController,
                            authService: authService,
                          ),
                          SizedBox(height: isTablet ? 20 : 14),
                          // Game start button
                          PrimaryButton(
                            label: '게임 시작',
                            icon: Icons.play_arrow_rounded,
                            onPressed: onStartGame,
                          ),
                          SizedBox(height: isTablet ? 14 : 10),
                          // 오늘의 퍼즐 + 랭킹 side by side
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: HomeProgressPanel(
                                    authService: authService,
                                    onStartDaily: onStartDaily,
                                  ),
                                ),
                                SizedBox(width: isTablet ? 14 : 10),
                                Expanded(
                                  flex: 2,
                                  child: RankingCard(
                                    onPressed: onRankingTap,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isTablet ? 14 : 10),
                          // 주간 랭킹
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
