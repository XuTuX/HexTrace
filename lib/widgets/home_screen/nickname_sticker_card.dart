import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexor/constant.dart';

class NicknameStickerCard extends StatelessWidget {
  const NicknameStickerCard({
    super.key,
    required this.nickname,
    required this.score,
    this.isLoading = false,
    this.onTapNickname,
  });

  final String? nickname;
  final int score;
  final bool isLoading;
  final VoidCallback? onTapNickname;

  static const Color stickerYellow = Color(0xFFF9D86D);

  bool get _hasNickname => nickname?.trim().isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final screenWidth = mediaSize.width;
        final isTablet = mediaSize.shortestSide >= 600;
        final maxCardWidth = isTablet ? 720.0 : double.infinity;
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : screenWidth;
        final effectiveCardWidth = maxCardWidth.isFinite
            ? math.min(availableWidth, maxCardWidth)
            : availableWidth;

        final stickerMaxWidth =
            isTablet ? effectiveCardWidth * 0.57 : screenWidth * 0.70;
        final stickerTop = isTablet ? -18.0 : -14.0;
        final stickerLeft = isTablet ? 24.0 : 16.0;
        final stickerHorizontalPadding = isTablet ? 22.0 : 16.0;
        final stickerVerticalPadding = isTablet ? 11.0 : 8.0;
        final iconSize = isTablet ? 22.0 : 18.0;
        final nicknameFontSize = isTablet ? 20.0 : 16.0;
        final scoreFontSize = isTablet ? 56.0 : 48.0;
        final cardHorizontalPadding = isTablet ? 32.0 : 24.0;
        final cardVerticalPadding = isTablet ? 32.0 : 28.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardWidth),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    cardHorizontalPadding,
                    cardVerticalPadding,
                    cardHorizontalPadding,
                    cardVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: charcoalBlack, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: charcoalBlack,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BEST SCORE',
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w800,
                          color: charcoalBlack.withValues(alpha: 0.55),
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: isTablet ? 12 : 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: isLoading
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                height: 52,
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: charcoalBlack,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                _formatScore(score),
                                key: const ValueKey('score'),
                                style: GoogleFonts.blackHanSans(
                                  fontSize: scoreFontSize,
                                  color: charcoalBlack,
                                  height: 1.0,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                if (_hasNickname)
                  Positioned(
                    top: stickerTop,
                    left: stickerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          alignment: Alignment.topLeft,
                          scale: value,
                          child: Transform.rotate(
                            angle: -0.06,
                            child: child,
                          ),
                        );
                      },
                        child: GestureDetector(
                          onTap: onTapNickname,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: stickerMaxWidth),
                            padding: EdgeInsets.symmetric(
                              horizontal: stickerHorizontalPadding,
                              vertical: stickerVerticalPadding,
                            ),
                            decoration: BoxDecoration(
                              color: stickerYellow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: charcoalBlack,
                                width: 2.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: charcoalBlack,
                                  offset: Offset(3, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: iconSize,
                                  color: charcoalBlack,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    nickname!.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.blackHanSans(
                                      fontSize: nicknameFontSize,
                                      color: charcoalBlack,
                                      height: 1.0,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatScore(int value) {
    final digits = value.toString();
    if (digits.length <= 3) {
      return digits;
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
