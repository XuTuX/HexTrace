import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/game/game_palette.dart';
import 'package:hexor/game/hex_game_controller.dart';

class TopIconButton extends StatelessWidget {
  const TopIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: charcoalBlack.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: charcoalBlack.withValues(alpha: 0.5),
          size: 22,
        ),
      ),
    );
  }
}

class HomeLogo extends StatelessWidget {
  const HomeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MiniHex(color: GamePalette.colorFor(GameColor.coral)),
            const SizedBox(width: 6),
            _MiniHex(color: GamePalette.colorFor(GameColor.azure)),
            const SizedBox(width: 6),
            _MiniHex(color: GamePalette.colorFor(GameColor.mint)),
            const SizedBox(width: 6),
            _MiniHex(color: GamePalette.colorFor(GameColor.amber)),
            const SizedBox(width: 6),
            _MiniHex(color: GamePalette.colorFor(GameColor.violet)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'HEX',
              style: GoogleFonts.blackHanSans(
                fontSize: 48,
                color: charcoalBlack,
                height: 1.0,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'TRACE',
              style: GoogleFonts.blackHanSans(
                fontSize: 48,
                color: const Color(0xFF0095FF),
                height: 1.0,
                letterSpacing: 3.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniHex extends StatelessWidget {
  const _MiniHex({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _HexPainter(color)),
    );
  }
}

class _HexPainter extends CustomPainter {
  _HexPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexPath(size);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = charcoalBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _hexPath(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final path = Path();

    for (int i = 0; i < 6; i++) {
      final angle = (pi / 180) * (60 * i - 30);
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
