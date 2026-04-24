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
    this.tierLabel,
    this.tierColor,
    this.tierRank,
  });

  final String? nickname;
  final int score;
  final bool isLoading;
  final VoidCallback? onTapNickname;
  final String? tierLabel;
  final Color? tierColor;
  final int? tierRank;

  bool get _hasTier => tierLabel != null && tierColor != null;

  Color get _tierTextColor {
    if (tierColor == null) {
      return charcoalBlack;
    }
    return tierColor!.computeLuminance() > 0.3 ? charcoalBlack : Colors.white;
  }

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
        final scoreFontSize = isTablet ? 42.0 : 34.0;
        final cardHorizontalPadding = isTablet ? 26.0 : 20.0;
        final cardVerticalPadding = isTablet ? 20.0 : 16.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardWidth),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: cardHorizontalPadding,
                vertical: cardVerticalPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: charcoalBlack, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: charcoalBlack,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'BEST SCORE',
                          style: TextStyle(
                            fontSize: isTablet ? 15 : 12,
                            fontWeight: FontWeight.w900,
                            color: charcoalBlack.withValues(alpha: 0.38),
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: isLoading
                              ? const SizedBox(
                                  key: ValueKey('loading'),
                                  height: 32,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: charcoalBlack,
                                        strokeWidth: 2.5,
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
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasTier) ...[
                    const SizedBox(width: 12),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: effectiveCardWidth * 0.34,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 12.0 : 9.0,
                        vertical: isTablet ? 8.0 : 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: charcoalBlack,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            size: isTablet ? 18.0 : 14.0,
                            color: _tierTextColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              tierRank != null
                                  ? '$tierLabel · $tierRank위'
                                  : tierLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.blackHanSans(
                                fontSize: isTablet ? 14.0 : 11.0,
                                color: _tierTextColor,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
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
