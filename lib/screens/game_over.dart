import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constant.dart';
import '../controllers/game_controller.dart';
import '../controllers/score_controller.dart';
import 'board.dart';
import 'home_screen.dart';

class GameOverDialog extends StatelessWidget {
  final VoidCallback onRestart;

  const GameOverDialog({
    super.key,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final scoreController = Get.find<ScoreController>();
    final gameController = Get.find<GameController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: charcoalBlack.withValues(alpha: 0.68),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: charcoalBlack, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: charcoalBlack,
                          offset: Offset(6, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'GAME OVER',
                          style: TextStyle(
                            color: charcoalBlack,
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          gameController.gameOverReason.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: charcoalBlack.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: 240,
                          height: 250,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: const ColoredBox(
                              color: Color(0xFFF7F2E8),
                              child: Padding(
                                padding: EdgeInsets.all(10),
                                child: Board(interactive: false),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: 'SCORE',
                                value: '${scoreController.score.value}',
                                accent: const Color(0xFFF97316),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                label: 'BEST',
                                value: '${scoreController.highscore.value}',
                                accent: const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _MetricCard(
                          label: 'MATCHES',
                          value: '${gameController.matchesMade.value}',
                          accent: const Color(0xFF2563EB),
                          fullWidth: true,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                label: 'HOME',
                                onTap: () =>
                                    Get.offAll(() => const HomeScreen()),
                                fill: Colors.white,
                                textColor: charcoalBlack,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionButton(
                                label: 'RETRY',
                                onTap: onRestart,
                                fill: const Color(0xFFFFB84D),
                                textColor: charcoalBlack,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final bool fullWidth;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: charcoalBlack, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: charcoalBlack.withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 26,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color fill;
  final Color textColor;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.fill,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: charcoalBlack, width: 2),
          boxShadow: const [
            BoxShadow(
              color: charcoalBlack,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
