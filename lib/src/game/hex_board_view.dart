import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_controller.dart';
import 'game_palette.dart';

class HexBoardView extends StatefulWidget {
  const HexBoardView({super.key, required this.controller});

  final HexGameController controller;

  @override
  State<HexBoardView> createState() => _HexBoardViewState();
}

class _HexBoardViewState extends State<HexBoardView>
    with SingleTickerProviderStateMixin {
  static const Duration _refillDuration = Duration(milliseconds: 320);

  late final AnimationController _refillController;
  int _lastBoardAnimationTick = 0;

  @override
  void initState() {
    super.initState();
    _lastBoardAnimationTick = widget.controller.boardAnimationTick;
    _refillController =
        AnimationController(vsync: this, duration: _refillDuration, value: 1)
          ..addListener(() {
            setState(() {});
          });
  }

  @override
  void didUpdateWidget(covariant HexBoardView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller.boardAnimationTick != _lastBoardAnimationTick) {
      _lastBoardAnimationTick = widget.controller.boardAnimationTick;

      if (widget.controller.animatedTiles.isNotEmpty) {
        _refillController.forward(from: 0);
      } else {
        _refillController.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _refillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = HexBoardLayout.fromSize(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          rows: widget.controller.rows,
          cols: widget.controller.cols,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => widget.controller.beginDrag(
            layout.hitTest(details.localPosition),
          ),
          onPanUpdate: (details) => widget.controller.extendDrag(
            layout.hitTest(details.localPosition),
          ),
          onPanEnd: (_) => widget.controller.endDrag(),
          onPanCancel: widget.controller.cancelDrag,
          child: CustomPaint(
            painter: HexBoardPainter(
              layout: layout,
              board: widget.controller.board,
              dragPath: widget.controller.dragPath,
              clearingPath: widget.controller.clearingPath,
              dragState: widget.controller.visibleDragState,
              animatedTiles: widget.controller.animatedTiles,
              refillProgress: _refillController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class HexBoardLayout {
  static const double _tileInsetFactor = 0.09;
  static const double _cornerRadiusFactor = 0.22;

  HexBoardLayout._({
    required this.radius,
    required this.width,
    required this.height,
    required this.verticalStep,
    required this.origin,
    required this.centers,
    required this.paths,
  });

  final double radius;
  final double width;
  final double height;
  final double verticalStep;
  final Offset origin;
  final Map<HexCoord, Offset> centers;
  final Map<HexCoord, Path> paths;

  factory HexBoardLayout.fromSize({
    required Size size,
    required int rows,
    required int cols,
  }) {
    final sqrt3 = math.sqrt(3);
    final double safeWidth = math.max(size.width - 12, 40).toDouble();
    final double safeHeight = math.max(size.height - 12, 40).toDouble();
    final double radiusFromWidth = safeWidth / (sqrt3 * (cols + 0.5));
    final double radiusFromHeight = safeHeight / (2 + (rows - 1) * 1.5);
    final double radius =
        math.max(10, math.min(radiusFromWidth, radiusFromHeight)).toDouble();
    final tileWidth = sqrt3 * radius;
    final tileHeight = radius * 2;
    final verticalStep = radius * 1.5;
    final boardWidth = tileWidth * cols + (tileWidth / 2);
    final boardHeight = tileHeight + (rows - 1) * verticalStep;
    final origin = Offset(
      (size.width - boardWidth) / 2,
      (size.height - boardHeight) / 2,
    );

    final centers = <HexCoord, Offset>{};
    final paths = <HexCoord, Path>{};

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final center = Offset(
          origin.dx +
              (tileWidth / 2) +
              (col * tileWidth) +
              (row.isOdd ? tileWidth / 2 : 0),
          origin.dy + radius + (row * verticalStep),
        );
        final coord = HexCoord(col, row);

        centers[coord] = center;
        paths[coord] = _buildHexPath(center, radius);
      }
    }

    return HexBoardLayout._(
      radius: radius,
      width: tileWidth,
      height: tileHeight,
      verticalStep: verticalStep,
      origin: origin,
      centers: centers,
      paths: paths,
    );
  }

  HexCoord? hitTest(Offset position) {
    for (final entry in paths.entries) {
      if (entry.value.contains(position)) {
        return entry.key;
      }
    }

    return null;
  }

  static Path _buildHexPath(Offset center, double radius) {
    final inset = math.max(1.5, radius * _tileInsetFactor);
    final effectiveRadius = math.max(6, radius - inset);
    final halfWidth = math.sqrt(3) * effectiveRadius / 2;
    final points = <Offset>[
      Offset(center.dx, center.dy - effectiveRadius),
      Offset(center.dx + halfWidth, center.dy - effectiveRadius / 2),
      Offset(center.dx + halfWidth, center.dy + effectiveRadius / 2),
      Offset(center.dx, center.dy + effectiveRadius),
      Offset(center.dx - halfWidth, center.dy + effectiveRadius / 2),
      Offset(center.dx - halfWidth, center.dy - effectiveRadius / 2),
    ];

    final cornerRadius = math.min(
      effectiveRadius * _cornerRadiusFactor,
      effectiveRadius * 0.32,
    );
    final path = Path();

    for (var index = 0; index < points.length; index++) {
      final previous = points[(index - 1 + points.length) % points.length];
      final current = points[index];
      final next = points[(index + 1) % points.length];
      final previousEdge = (current - previous).distance;
      final nextEdge = (next - current).distance;
      final localRadius = math.min(
        cornerRadius,
        math.min(previousEdge, nextEdge) / 2,
      );
      final start = _pointToward(current, previous, localRadius);
      final end = _pointToward(current, next, localRadius);

      if (index == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }

      path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
    }

    path.close();

    return path;
  }

  static Offset _pointToward(Offset from, Offset to, double distance) {
    final delta = to - from;
    final length = delta.distance;

    if (length == 0) {
      return from;
    }

    final direction = delta / length;
    return from + (direction * distance);
  }
}

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
  });

  final HexBoardLayout layout;
  final List<List<GameColor>> board;
  final List<HexCoord> dragPath;
  final List<HexCoord> clearingPath;
  final DragState dragState;
  final Set<HexCoord> animatedTiles;
  final double refillProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final backdropPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF173445), Color(0xFF102431)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    final backdrop = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(28),
    );

    canvas.drawRRect(backdrop, backdropPaint);
    canvas.save();
    canvas.clipRRect(backdrop);

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
        final isAnimated = animatedTiles.contains(coord);
        final tileProgress =
            isAnimated ? _tileProgress(col, board[row].length) : 1;
        final opacity = 0.3 + (tileProgress * 0.7);
        final scale = 0.76 + (tileProgress * 0.24);

        _paintTile(
          canvas: canvas,
          path: layout.paths[coord]!,
          center: layout.centers[coord]!,
          color: GamePalette.colorFor(board[row][col]),
          opacity: isAnimated ? opacity : 1,
          scale: isAnimated ? scale : 1,
          borderColor:
              dragSet.contains(coord) ? dragColor : const Color(0xFF244353),
          borderWidth: dragSet.contains(coord) ? 4 : 1.2,
          coreAlpha: dragSet.contains(coord) ? 0.5 : 0.12,
          isClearing: clearingSet.contains(coord),
        );
      }
    }

    if (dragPath.length > 1) {
      final line = Path()
        ..moveTo(
          layout.centers[dragPath.first]!.dx,
          layout.centers[dragPath.first]!.dy,
        );

      for (var index = 1; index < dragPath.length; index++) {
        final point = layout.centers[dragPath[index]]!;
        line.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = layout.radius * 0.3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = dragColor.withValues(alpha: 0.34),
      );

      canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = layout.radius * 0.13
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = dragColor,
      );
    }

    for (var index = 0; index < dragPath.length; index++) {
      final coord = dragPath[index];
      final center = layout.centers[coord]!;
      final painter = TextPainter(
        text: TextSpan(
          text: '${index + 1}',
          style: TextStyle(
            color: GamePalette.canvas,
            fontSize: layout.radius * 0.62,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
      );
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
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale, scale);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawPath(
      path.shift(const Offset(0, 4)),
      Paint()..color = Colors.black.withValues(alpha: 0.14 * opacity),
    );

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

    canvas.drawCircle(
      center,
      layout.radius * 0.22 * scale,
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
