import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkagon/constant.dart';
import 'package:linkagon/theme/app_typography.dart';
import 'package:linkagon/widgets/home_screen/components/home_action_buttons.dart';

class SharePreviewDialog extends StatelessWidget {
  const SharePreviewDialog({
    super.key,
    required this.score,
    required this.bestScore,
    required this.isNewHighScore,
    required this.onShare,
    required this.shareCardKey,
    this.isSharing = false,
  });

  final int score;
  final int bestScore;
  final bool isNewHighScore;
  final VoidCallback onShare;
  final GlobalKey shareCardKey;
  final bool isSharing;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header / Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 28),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // The Shareable Card (captured area)
            RepaintBoundary(
              key: shareCardKey,
              child: Container(
                width: 360,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: charcoalBlack, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: charcoalBlack,
                      offset: Offset(8, 8),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(29.5),
                  child: Stack(
                    children: [
                      // Decorative elements - subtle hex patterns
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Transform.rotate(
                          angle: 0.5,
                          child: Icon(
                            Icons.hexagon_rounded,
                            size: 150,
                            color: charcoalBlack.withValues(alpha: 0.03),
                          ),
                        ),
                      ),

                      // Main Content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 50, horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Brand Identity
                            Text(
                              'BEE HOUSE',
                              style: GoogleFonts.blackHanSans(
                                fontSize: 26,
                                color: charcoalBlack,
                                letterSpacing: 3,
                              ),
                            ),

                            const SizedBox(height: 60),

                            // Score Label
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isNewHighScore
                                    ? const Color(0xFFFEF2F2)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: charcoalBlack, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: charcoalBlack,
                                    offset: Offset(4, 4),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Text(
                                isNewHighScore ? 'NEW BEST!' : 'FINAL SCORE',
                                style: GoogleFonts.blackHanSans(
                                  fontSize: 14,
                                  color: isNewHighScore
                                      ? const Color(0xFFEF4444)
                                      : charcoalBlack,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Score Display Area
                            SizedBox(
                              height: 120,
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    score.toString().replaceAllMapped(
                                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                        (Match m) => '${m[1]},'),
                                    style: GoogleFonts.blackHanSans(
                                      fontSize: 110,
                                      color: charcoalBlack,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 60),

                            // Achievement Stats
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border:
                                    Border.all(color: charcoalBlack, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: charcoalBlack,
                                    offset: Offset(5, 5),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _StatItem(
                                      label: 'PERSONAL BEST',
                                      value: bestScore
                                          .toString()
                                          .replaceAllMapped(
                                              RegExp(
                                                  r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                              (Match m) => '${m[1]},'),
                                    ),
                                  ),
                                  if (isNewHighScore) ...[
                                    const SizedBox(width: 20),
                                    const Expanded(
                                      child: _StatItem(
                                        label: 'STATUS',
                                        value: 'RECORD',
                                        color: Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action Button (Outside captured area)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PrimaryButton(
                label: isSharing ? '공유 중...' : '이미지로 공유하기',
                icon: isSharing
                    ? Icons.hourglass_top_rounded
                    : Icons.ios_share_rounded,
                onPressed: isSharing
                    ? () {}
                    : () {
                        onShare();
                      },
              ),
            ),

            const SizedBox(height: 12),

            Text(
              '이미지가 갤러리에 저장되거나 친구에게 공유됩니다',
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.blackHanSans(
            fontSize: 10,
            color: charcoalBlack.withValues(alpha: 0.4),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 38,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.blackHanSans(
                fontSize: 34,
                color: color ?? charcoalBlack,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
