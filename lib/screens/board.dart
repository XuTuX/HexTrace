import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constant.dart';
import '../controllers/game_controller.dart';
import '../gameplay/hex_puzzle/hex_puzzle_logic.dart';
import '../gameplay/hex_puzzle/hex_puzzle_palette.dart';

class Board extends StatelessWidget {
  final bool interactive;

  const Board({
    super.key,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GameController>();

    return Obx(() {
      if (controller.board.isEmpty) {
        return const SizedBox.expand();
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final layout = _HexBoardLayout.fromSize(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            rows: controller.board.length,
            columns: controller.board.first.length,
          );

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: !interactive
                ? null
                : (details) {
                    final hit = layout.hitTest(details.localPosition);
                    if (hit != null) {
                      controller.startDrag(hit);
                    }
                  },
            onPanUpdate: !interactive
                ? null
                : (details) {
                    final hit = layout.hitTest(details.localPosition);
                    if (hit != null) {
                      controller.updateDrag(hit);
                    }
                  },
            onPanEnd: !interactive ? null : (_) => controller.endDrag(),
            onPanCancel: !interactive ? null : controller.cancelDrag,
            child: CustomPaint(
              painter: _HexBoardPainter(
                board: controller.board,
                dragPath: controller.dragPath,
                lastMatchedPath: controller.lastMatchedPath,
                dragStatus: controller.dragStatus.value,
                layout: layout,
              ),
              size: Size.infinite,
            ),
          );
        },
      );
    });
  }
}

class _HexBoardPainter extends CustomPainter {
  final List<List<HexTileColor>> board;
  final List<HexCoord> dragPath;
  final List<HexCoord> lastMatchedPath;
  final DragPathStatus dragStatus;
  final _HexBoardLayout layout;

  _HexBoardPainter({
    required this.board,
    required this.dragPath,
    required this.lastMatchedPath,
    required this.dragStatus,
    required this.layout,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final selected = dragPath.toSet();
    final matched = lastMatchedPath.toSet();
    final connectionColor = _pathColorForStatus(dragStatus);

    for (final cell in layout.cells) {
      final tileColor = board[cell.coord.row][cell.coord.column];
      final isSelected = selected.contains(cell.coord);
      final isMatched = matched.contains(cell.coord);

      final shadowPaint = Paint()
        ..color = charcoalBlack.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill;
      canvas.drawPath(cell.path.shift(const Offset(0, 4)), shadowPaint);

      final fillPaint = Paint()
        ..color = tileColor.fillColor.withValues(
          alpha: isMatched ? 0.45 : 1,
        )
        ..style = PaintingStyle.fill;
      canvas.drawPath(cell.path, fillPaint);

      if (isMatched) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell.radius * 0.20;
        canvas.drawPath(cell.path, glowPaint);
      }

      if (isSelected) {
        final overlayPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.20)
          ..style = PaintingStyle.fill;
        canvas.drawPath(cell.path, overlayPaint);
      }

      final borderPaint = Paint()
        ..color = isSelected ? connectionColor : tileColor.accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? cell.radius * 0.12 : 2.5;
      canvas.drawPath(cell.path, borderPaint);

      _drawTileLabel(canvas, cell, tileColor);
    }

    if (dragPath.length > 1) {
      _drawPathLine(canvas, connectionColor);
    }

    for (var index = 0; index < dragPath.length; index++) {
      _drawOrderBadge(canvas, layout.centerFor(dragPath[index]), index + 1);
    }
  }

  void _drawTileLabel(
    Canvas canvas,
    _HexCellGeometry cell,
    HexTileColor tileColor,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: tileColor.label.characters.first,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: cell.radius * 0.62,
          shadows: const [
            Shadow(
              color: Color(0x44000000),
              offset: Offset(0, 2),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        cell.center.dx - textPainter.width / 2,
        cell.center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawPathLine(Canvas canvas, Color color) {
    final pathPaint = Paint()
      ..color = color
      ..strokeWidth = layout.radius * 0.26
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..strokeWidth = layout.radius * 0.52
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final line = Path()
      ..moveTo(
        layout.centerFor(dragPath.first).dx,
        layout.centerFor(dragPath.first).dy,
      );

    for (final coord in dragPath.skip(1)) {
      final center = layout.centerFor(coord);
      line.lineTo(center.dx, center.dy);
    }

    canvas.drawPath(line, glowPaint);
    canvas.drawPath(line, pathPaint);
  }

  void _drawOrderBadge(Canvas canvas, Offset center, int index) {
    final badgePaint = Paint()..color = charcoalBlack;
    canvas.drawCircle(
      Offset(center.dx, center.dy - layout.radius * 0.58),
      layout.radius * 0.26,
      badgePaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$index',
        style: TextStyle(
          color: Colors.white,
          fontSize: layout.radius * 0.26,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - layout.radius * 0.58 - textPainter.height / 2,
      ),
    );
  }

  Color _pathColorForStatus(DragPathStatus status) {
    switch (status) {
      case DragPathStatus.exact:
        return const Color(0xFF16A34A);
      case DragPathStatus.invalid:
        return const Color(0xFFDC2626);
      case DragPathStatus.building:
      case DragPathStatus.idle:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  bool shouldRepaint(covariant _HexBoardPainter oldDelegate) {
    return oldDelegate.board != board ||
        oldDelegate.dragPath != dragPath ||
        oldDelegate.lastMatchedPath != lastMatchedPath ||
        oldDelegate.dragStatus != dragStatus ||
        oldDelegate.layout != layout;
  }
}

class _HexBoardLayout {
  final double radius;
  final List<_HexCellGeometry> cells;
  final Map<HexCoord, _HexCellGeometry> cellMap;

  const _HexBoardLayout({
    required this.radius,
    required this.cells,
    required this.cellMap,
  });

  factory _HexBoardLayout.fromSize({
    required Size size,
    required int rows,
    required int columns,
  }) {
    final usableWidth = math.max(40.0, size.width - 12);
    final usableHeight = math.max(40.0, size.height - 12);
    final radius = math.min(
      usableWidth / (math.sqrt(3) * (columns + 0.5)),
      usableHeight / (rows * 1.5 + 0.5),
    );

    final tileWidth = math.sqrt(3) * radius;
    final boardWidth = tileWidth * (columns + 0.5);
    final boardHeight = radius * (rows * 1.5 + 0.5);
    final leftInset = (size.width - boardWidth) / 2;
    final topInset = (size.height - boardHeight) / 2;

    final cells = <_HexCellGeometry>[];
    final cellMap = <HexCoord, _HexCellGeometry>{};

    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final center = Offset(
          leftInset +
              tileWidth / 2 +
              (column * tileWidth) +
              (row.isOdd ? tileWidth / 2 : 0),
          topInset + radius + (row * radius * 1.5),
        );
        final coord = HexCoord(row, column);
        final geometry = _HexCellGeometry(
          coord: coord,
          center: center,
          radius: radius,
          path: _hexPath(center, radius),
        );

        cells.add(geometry);
        cellMap[coord] = geometry;
      }
    }

    return _HexBoardLayout(
      radius: radius,
      cells: cells,
      cellMap: cellMap,
    );
  }

  HexCoord? hitTest(Offset position) {
    for (final cell in cells) {
      if (cell.path.contains(position)) {
        return cell.coord;
      }
    }
    return null;
  }

  Offset centerFor(HexCoord coord) => cellMap[coord]!.center;

  static Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (var index = 0; index < 6; index++) {
      final angle = (math.pi / 180) * ((60 * index) - 30);
      final point = Offset(
        center.dx + (radius * math.cos(angle)),
        center.dy + (radius * math.sin(angle)),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }
}

class _HexCellGeometry {
  final HexCoord coord;
  final Offset center;
  final double radius;
  final Path path;

  const _HexCellGeometry({
    required this.coord,
    required this.center,
    required this.radius,
    required this.path,
  });
}
