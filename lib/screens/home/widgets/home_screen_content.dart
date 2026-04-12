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
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      SizedBox(height: isTablet ? 20 : 12),
                      Row(
                        children: [
                          const Spacer(),
                          TopIconButton(
                            icon: Icons.settings_rounded,
                            onTap: onSettingsTap,
                          ),
                        ],
                      ),
                      const Spacer(flex: 2),
                      const HomeLogo(),
                      SizedBox(height: isTablet ? 32 : 28),
                      ScoreDisplay(
                        scoreController: scoreController,
                        authService: authService,
                      ),
                      SizedBox(height: isTablet ? 40 : 36),
                      PrimaryButton(
                        label: '게임 시작',
                        icon: Icons.play_arrow_rounded,
                        onPressed: onStartGame,
                      ),
                      SizedBox(height: isTablet ? 16 : 14),
                      RankingButton(
                        onPressed: onRankingTap,
                      ),
                      const Spacer(flex: 3),
                      WeeklyRankingPreview(
                        onViewAll: onRankingTap,
                      ),
                      SizedBox(height: isTablet ? 28 : 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
