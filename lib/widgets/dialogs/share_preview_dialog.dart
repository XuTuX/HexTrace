import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A), // Premium Dark Navy
                ),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 340),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 20),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(31),
                      child: Stack(
                        children: [
                          // Subtle Hex Grid Pattern
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.05,
                              child: CustomPaint(
                                painter: _HexGridPainter(),
                              ),
                            ),
                          ),

                          // Glowing Gradient Accents
                          Positioned(
                            top: -60,
                            right: -60,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF0095FF)
                                        .withValues(alpha: 0.4),
                                    const Color(0xFF0095FF)
                                        .withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 44, horizontal: 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Brand Logo
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0095FF)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.hexagon_rounded,
                                        color: Color(0xFF0095FF),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'LINKAGON',
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 48),

                                // Score Label with Line
                                Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                            color: Colors.white
                                                .withValues(alpha: 0.1),
                                            thickness: 1)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text(
                                        'MATCH SCORE',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white
                                              .withValues(alpha: 0.4),
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color: Colors.white
                                                .withValues(alpha: 0.1),
                                            thickness: 1)),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Main Score with Glow
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      '$score',
                                      style: GoogleFonts.outfit(
                                        fontSize: 90,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 40),

                                // Best Score Section (Glassmorphism)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'PERSONAL BEST',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white
                                              .withValues(alpha: 0.4),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$bestScore',
                                            style: GoogleFonts.outfit(
                                              fontSize: 34,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          if (isNewHighScore) ...[
                                            const SizedBox(width: 12),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF0095FF),
                                                    Color(0xFF00D47C)
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF0095FF)
                                                            .withValues(
                                                                alpha: 0.4),
                                                    blurRadius: 10,
                                                  ),
                                                ],
                                              ),
                                              child: const Text(
                                                'NEW RECORD',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // Footer / Website or App Store
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.apple,
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'GET IT ON THE APP STORE',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

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
              style: AppTypography.label.copyWith(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _HexGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const double hexSize = 30;
    const double horizontalSpacing = hexSize * 1.5;
    const double verticalSpacing = hexSize * 1.732;

    for (double y = 0;
        y < size.height + verticalSpacing;
        y += verticalSpacing) {
      for (double x = 0;
          x < size.width + horizontalSpacing;
          x += horizontalSpacing) {
        final double xOffset =
            (y / verticalSpacing).floor() % 2 == 0 ? 0 : horizontalSpacing / 2;
        _drawHexagon(canvas, Offset(x + xOffset, y), hexSize, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double size, Paint paint) {
    final hPath = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = (i * 60) * math.pi / 180;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) {
        hPath.moveTo(x, y);
      } else {
        hPath.lineTo(x, y);
      }
    }
    hPath.close();
    canvas.drawPath(hPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
