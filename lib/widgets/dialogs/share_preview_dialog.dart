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
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header / Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
          
          const SizedBox(height: 8),

          // The Shareable Card (captured area)
          RepaintBoundary(
            key: shareCardKey,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA), // Professional light grey background
              ),
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 360),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: charcoalBlack, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: charcoalBlack.withValues(alpha: 0.15),
                        offset: const Offset(0, 12),
                        blurRadius: 24,
                      ),
                      const BoxShadow(
                        color: charcoalBlack,
                        offset: Offset(8, 8),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Stack(
                      children: [
                        // Background Pattern
                        Positioned(
                          top: -40,
                          right: -40,
                          child: _DecorativeHexagon(
                            size: 160,
                            color: regionColors[0].withValues(alpha: 0.12),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          left: -30,
                          child: _DecorativeHexagon(
                            size: 120,
                            color: regionColors[4].withValues(alpha: 0.12),
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Brand Logo
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'HEX',
                                    style: GoogleFonts.blackHanSans(
                                      fontSize: 24,
                                      color: charcoalBlack,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'TRACE',
                                    style: GoogleFonts.blackHanSans(
                                      fontSize: 24,
                                      color: const Color(0xFF0095FF),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 60),
                              
                              // Score Label
                              Text(
                                'FINAL SCORE',
                                style: GoogleFonts.blackHanSans(
                                  fontSize: 14,
                                  color: charcoalBlack.withValues(alpha: 0.4),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Main Score
                              Text(
                                '$score',
                                style: GoogleFonts.blackHanSans(
                                  fontSize: 100,
                                  color: charcoalBlack,
                                  height: 0.9,
                                ),
                              ),
                              
                              const SizedBox(height: 60),
                              
                              // Best Score Section
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: charcoalBlack.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.emoji_events_rounded,
                                          color: isNewHighScore 
                                              ? const Color(0xFFF59E0B) 
                                              : charcoalBlack.withValues(alpha: 0.2),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'PERSONAL BEST',
                                          style: GoogleFonts.blackHanSans(
                                            fontSize: 12,
                                            color: charcoalBlack.withValues(alpha: 0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$bestScore',
                                          style: GoogleFonts.blackHanSans(
                                            fontSize: 32,
                                            color: charcoalBlack,
                                          ),
                                        ),
                                        if (isNewHighScore) ...[
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3B82F6),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: charcoalBlack, width: 1.5),
                                            ),
                                            child: const Text(
                                              'NEW',
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
                              
                              const SizedBox(height: 48),
                              
                              // Footer / Game Link Hint
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: charcoalBlack.withValues(alpha: 0.1), width: 1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'PLAY NOW ON APP STORE',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: charcoalBlack.withValues(alpha: 0.3),
                                    letterSpacing: 1.5,
                                  ),
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
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action Button (Outside captured area)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: PrimaryButton(
              label: isSharing ? '공유 중...' : '이미지로 공유하기',
              icon: isSharing ? Icons.hourglass_top_rounded : Icons.ios_share_rounded,
              onPressed: isSharing ? () {} : () {
                // We don't pop here anymore, we wait for the share to complete or fail
                // Or we can pop inside onShare if we want. 
                // Let's let the caller decide.
                onShare();
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            '이미지가 갤러리에 저장되거나 친구에게 공유됩니다',
            style: AppTypography.label.copyWith(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeHexagon extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeHexagon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.5,
      child: Icon(
        Icons.hexagon_rounded,
        size: size,
        color: color,
      ),
    );
  }
}
