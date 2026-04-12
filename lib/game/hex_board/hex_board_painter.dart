import 'package:flutter/material.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/game/game_palette.dart';
import 'package:hexor/game/hex_game_controller.dart';

import 'hex_board_layout.dart';

class HexBoardPainter extends CustomPainter {
  static const double _columnDelayFraction = 0.06;

  HexBoardPainter({
    required this.layout,
    required this.board,
    required this.dragPath,
    required this.clearingPath,
    required this.dragState,
    required this.animatedTiles,
    required this.refillProgress,
    required this.pressProgress,
  });

  final HexBoardLayout layout;
  final List<List<GameColor>> board;
  final List<HexCoord> dragPath;
  final List<HexCoord> clearingPath;
  final DragState dragState;
  final Set<HexCoord> animatedTiles;
  final double refillProgress;
  final Map<HexCoord, double> pressProgress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    final dragSet = dragPath.toSet();
    final clearingSet = clearingPath.toSet();
    final dragColor = switch (dragState) {
      DragState.valid => GamePalette.success,
      DragState.invalid => GamePalette.danger,
      DragState.building => GamePalette.drag,
      DragState.idle => GamePalette.drag,
    };

    for (var row = 0; row < board.length; row++) {
      for (var col = 0; col < board[row].length; col++) {
        final coord = HexCoord(col, row);
        if (!dragSet.contains(coord)) {
          final isAnimated = animatedTiles.contains(coord);
          final tileProgress =
              isAnimated ? _tileProgress(col, board[row].length) : 1;
          final opacity = 0.3 + (tileProgress * 0.7);
          final scale = 0.76 + (tileProgress * 0.24);

          canvas.save();
          final center = layout.centers[coord]!;
          canvas.translate(center.dx, center.dy);
          canvas.scale(scale, scale);
          canvas.translate(-center.dx, -center.dy);

          canvas.drawPath(
            layout.paths[coord]!.shift(const Offset(0, 6)),
            Paint()
              ..style = PaintingStyle.fill
              ..color = charcoalBlack.withValues(alpha: opacity),
          );
          canvas.restore();
        }
      }
    }

    for (var row = 0; row < board.length; row++) {
      for (var col = 0; col < board[row].length; col++) {
        final coord = HexCoord(col, row);
        final isAnimated = animatedTiles.contains(coord);
        final tileProgress =
            isAnimated ? _tileProgress(col, board[row].length) : 1;
        final opacity = 0.3 + (tileProgress * 0.7);
        final scale = 0.76 + (tileProgress * 0.24);
        final pressVal = pressProgress[coord] ?? 0.0;

        _paintTile(
          canvas: canvas,
          path: layout.paths[coord]!,
          center: layout.centers[coord]!,
          color: GamePalette.colorFor(board[row][col]),
          opacity: isAnimated ? opacity : 1,
          scale: isAnimated ? scale : 1,
          borderColor: charcoalBlack,
          borderWidth: 2.5,
          coreAlpha: 0.12 + (0.68 * pressVal),
          isClearing: clearingSet.contains(coord),
          pressVal: pressVal,
        );
      }
    }

    if (dragPath.length > 1) {
      final line = Path()
        ..moveTo(
          layout.centers[dragPath.first]!.dx,
          layout.centers[dragPath.first]!.dy + 6,
        );

      for (var index = 1; index < dragPath.length; index++) {
        final point = layout.centers[dragPath[index]]!;
        line.lineTo(point.dx, point.dy + 6);
      }

      canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = layout.radius * 0.15
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = dragColor,
      );
    }

    }

    canvas.restore();
  }

  double _tileProgress(int col, int totalCols) {
    if (totalCols <= 1) {
      return Curves.easeOutCubic.transform(refillProgress.clamp(0, 1));
    }

    final start = col * _columnDelayFraction;
    final localProgress =
        ((refillProgress - start) / (1 - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(localProgress);
  }

  void _paintTile({
    required Canvas canvas,
    required Path path,
    required Offset center,
    required Color color,
    required double opacity,
    required double scale,
    required Color borderColor,
    required double borderWidth,
    required double coreAlpha,
    required bool isClearing,
    double pressVal = 0.0,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);
    canvas.translate(-center.dx, -center.dy);

    if (pressVal > 0) {
      canvas.translate(0, 6 * pressVal);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = isClearing
            ? color.withValues(alpha: 0.28 * opacity)
            : color.withValues(alpha: opacity),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = borderColor.withValues(alpha: opacity),
    );

    final currentCoreRadiusScale = 0.10 + (0.12 * pressVal);

    if (pressVal > 0) {
      canvas.drawCircle(
        center,
        layout.radius * (0.10 + (0.22 * pressVal)) * scale,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15 * pressVal * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    canvas.drawCircle(
      center,
      layout.radius * currentCoreRadiusScale * scale,
      Paint()..color = Colors.white.withValues(alpha: coreAlpha * opacity),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HexBoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.dragPath != dragPath ||
        oldDelegate.clearingPath != clearingPath ||
        oldDelegate.dragState != dragState ||
        oldDelegate.layout.radius != layout.radius ||
        oldDelegate.animatedTiles != animatedTiles ||
        oldDelegate.refillProgress != refillProgress;
  }
}
