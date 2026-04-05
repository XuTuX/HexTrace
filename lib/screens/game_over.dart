import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constant.dart';
import '../controllers/game_controller.dart';
import '../controllers/score_controller.dart';
import '../gameplay/game_constants.dart';
import '../services/ad_service.dart';
import '../theme/app_typography.dart';
import '../widgets/dialogs/custom_dialog.dart';
import 'board.dart';
import 'home_screen.dart';

class GameOverDialog extends StatefulWidget {
  final VoidCallback onRestart;
  final Future<ContinueResult> Function()? onContinue;

  const GameOverDialog({
    super.key,
    required this.onRestart,
    this.onContinue,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog> {
  final GlobalKey _snapshotKey = GlobalKey();
  bool _isContinueLoading = false;

  Future<void> _shareImage() async {
    try {
      HapticFeedback.mediumImpact();
      final boundary = _snapshotKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      await Future.delayed(const Duration(milliseconds: 50));
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Snapshot failed');
      }

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/rune_bloom_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final shareOrigin =
          box != null ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        sharePositionOrigin: shareOrigin,
      );
    } catch (error) {
      debugPrint('Share failed: $error');
      if (mounted) {
        showCustomAlert('Share failed', 'The result card could not be shared.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreController = Get.find<ScoreController>();
    final adService = Get.find<AdService>();
    final isHighScore = scoreController.hasNewHighScoreThisGame.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: charcoalBlack.withValues(alpha: 0.7),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RepaintBoundary(
                        key: _snapshotKey,
                        child: Container(
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
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                            child: Column(
                              children: [
                                Text(
                                  appName,
                                  style: AppTypography.title.copyWith(
                                    fontSize: 26,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$gameTitle final board',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: charcoalBlack54,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final gridSize = constraints.maxWidth - 12;
                                    return SizedBox(
                                      width: gridSize,
                                      height: gridSize,
                                      child: AbsorbPointer(
                                        child: Board(
                                          gridSize: gridSize,
                                          cellSize: gridSize / boardColumns,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  '${scoreController.score.value}',
                                  style: AppTypography.scoreDisplay.copyWith(
                                    fontSize: 54,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isHighScore
                                      ? 'New best bloom!'
                                      : 'Best ${scoreController.highscore.value}',
                                  style: AppTypography.body.copyWith(
                                    color: isHighScore
                                        ? const Color(0xFFF97316)
                                        : charcoalBlack54,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildPrimaryButton(
                        label: 'SHARE RESULT',
                        icon: Icons.ios_share_rounded,
                        color: const Color(0xFF2563EB),
                        onTap: _shareImage,
                      ),
                      const SizedBox(height: 12),
                      if (widget.onContinue != null)
                        Obx(() {
                          final adReady = adService.isRewardedAdReady.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildPrimaryButton(
                              label: _isContinueLoading
                                  ? 'OPENING AD...'
                                  : adReady
                                      ? 'WATCH AD FOR SUNBURST'
                                      : 'AD LOADING...',
                              icon: _isContinueLoading
                                  ? null
                                  : Icons.bolt_rounded,
                              color: const Color(0xFF16A34A),
                              onTap: _isContinueLoading
                                  ? null
                                  : () async {
                                      setState(() {
                                        _isContinueLoading = true;
                                      });

                                      final result =
                                          await widget.onContinue!.call();
                                      if (!mounted) return;

                                      if (result == ContinueResult.success) {
                                        Get.back();
                                        return;
                                      }

                                      setState(() {
                                        _isContinueLoading = false;
                                      });

                                      switch (result) {
                                        case ContinueResult.alreadyUsed:
                                          showCustomAlert(
                                            'Sunburst spent',
                                            'Each run can only trigger one rescue pulse.',
                                          );
                                          break;
                                        case ContinueResult.noValidPulse:
                                          showCustomAlert(
                                            'No rescue window',
                                            'There is no 3x3 pulse that opens a valid move.',
                                          );
                                          break;
                                        case ContinueResult.adNotCompleted:
                                          showCustomAlert(
                                            'Reward not earned',
                                            'Watch the full ad to fire the pulse.',
                                          );
                                          break;
                                        case ContinueResult.adUnavailable:
                                          showCustomAlert(
                                            'Ad unavailable',
                                            'Try again in a moment.',
                                          );
                                          break;
                                        case ContinueResult.success:
                                          break;
                                      }
                                    },
                            ),
                          );
                        }),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSecondaryButton(
                              label: 'HOME',
                              icon: Icons.home_rounded,
                              onTap: () => Get.offAll(() => const HomeScreen()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSecondaryButton(
                              label: 'RETRY',
                              icon: Icons.refresh_rounded,
                              onTap: widget.onRestart,
                              fill: const Color(0xFFFFB27A),
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
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required Color color,
    required VoidCallback? onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.lightImpact(),
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: color,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isContinueLoading && onTap == null)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else if (icon != null)
                Icon(icon, color: Colors.white),
              if (_isContinueLoading && onTap == null || icon != null)
                const SizedBox(width: 10),
              Text(
                label,
                style: AppTypography.button.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color fill = Colors.white,
  }) {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.lightImpact(),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: charcoalBlack),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.button.copyWith(
                color: charcoalBlack,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
