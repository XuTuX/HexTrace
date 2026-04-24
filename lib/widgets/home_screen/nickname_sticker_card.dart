import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/game/game_palette.dart';
import 'package:hexor/game/hex_game_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final isTablet = mediaSize.shortestSide >= 600;
        final sw = mediaSize.width;
        final maxCardWidth = isTablet ? 720.0 : double.infinity;
        final scoreFontSize = isTablet
            ? (sw * 0.055).clamp(40.0, 60.0)
            : (sw * 0.11).clamp(32.0, 48.0);
        final cardPadH = isTablet
            ? (sw * 0.035).clamp(22.0, 34.0)
            : (sw * 0.06).clamp(18.0, 28.0);
        final cardPadV = isTablet
            ? (mediaSize.height * 0.028).clamp(24.0, 38.0)
            : (mediaSize.height * 0.03).clamp(20.0, 32.0);
        final tierFs = isTablet
            ? (sw * 0.016).clamp(11.0, 15.0)
            : (sw * 0.03).clamp(10.0, 13.0);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardWidth),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: cardPadH,
                vertical: cardPadV,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: charcoalBlack, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: charcoalBlack,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Mini hex decorations
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TinyHex(
                          color: GamePalette.colorFor(GameColor.coral)
                              .withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      _TinyHex(
                          color: GamePalette.colorFor(GameColor.azure)
                              .withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      _TinyHex(
                          color: GamePalette.colorFor(GameColor.mint)
                              .withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      _TinyHex(
                          color: GamePalette.colorFor(GameColor.amber)
                              .withValues(alpha: 0.4)),
                    ],
                  ),
                  SizedBox(height: cardPadV * 0.7),
                  // Score — big, centered, hero element
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: isLoading
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            height: scoreFontSize,
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
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
                  SizedBox(height: cardPadV * 0.5),
                  // Tier + Rank — subtle text row
                  if (_hasTier)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: tierColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tierRank != null
                              ? '$tierLabel · $tierRank위'
                              : tierLabel!,
                          style: GoogleFonts.notoSans(
                            fontSize: tierFs,
                            fontWeight: FontWeight.w800,
                            color: charcoalBlack.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
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

class _TinyHex extends StatelessWidget {
  const _TinyHex({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: CustomPaint(painter: _TinyHexPainter(color)),
    );
  }
}

class _TinyHexPainter extends CustomPainter {
  _TinyHexPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final path = Path();

    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * (60 * i - 30);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
