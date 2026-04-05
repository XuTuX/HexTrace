import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:hexor/constant.dart';
import 'game_palette.dart';
import 'hex_game_controller.dart';

class HexBoardView extends StatefulWidget {
  const HexBoardView({super.key, required this.controller});

  final HexGameController controller;

  @override
  State<HexBoardView> createState() => _HexBoardViewState();
}

class _HexBoardViewState extends State<HexBoardView>
    with TickerProviderStateMixin {
  static const Duration _refillDuration = Duration(milliseconds: 320);

  late final AnimationController _refillController;
  late final Ticker _pressTicker;
  final Map<HexCoord, double> _pressProgress = {};
  Duration _lastTick = Duration.zero;
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

    _pressTicker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    
    final double dt = (elapsed - _lastTick).inMilliseconds / 1000.0;
    _lastTick = elapsed;
    bool needsRepaint = false;

    // Smooth press transition (200ms duration = speed 5.0)
    for (int r = 0; r < widget.controller.rows; r++) {
      for (int c = 0; c < widget.controller.cols; c++) {
        final coord = HexCoord(c, r);
        final isPressed = widget.controller.dragPath.contains(coord);
        final target = isPressed ? 1.0 : 0.0;
        final current = _pressProgress[coord] ?? 0.0;
        
        if (current != target) {
          double next = current;
          if (current < target) {
            next = (current + dt * 5.0).clamp(0.0, 1.0);
          } else {
            next = (current - dt * 5.0).clamp(0.0, 1.0);
          }
          _pressProgress[coord] = next;
          needsRepaint = true;
        }
      }
    }

    if (needsRepaint && mounted) {
      setState(() {});
    }
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
    _pressTicker.dispose();
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
              pressProgress: _pressProgress,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class HexBoardLayout {
  static const double _tileInsetFactor = 0.14;
  static const double _cornerRadiusFactor = 0.28;

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

    // --- Pass 1: Draw Shadows ---
    for (var row = 0; row < board.length; row++) {
      for (var col = 0; col < board[row].length; col++) {
        final coord = HexCoord(col, row);
        if (!dragSet.contains(coord)) {
          final isAnimated = animatedTiles.contains(coord);
          final tileProgress = isAnimated ? _tileProgress(col, board[row].length) : 1;
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

    // --- Pass 2: Draw Foregrounds ---
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
          coreAlpha: 0.12 + (0.68 * pressVal), // 0.12 to 0.8
          isClearing: clearingSet.contains(coord),
          pressVal: pressVal,
        );
      }
    }

    if (dragPath.length > 1) {
      final line = Path()
        ..moveTo(
          layout.centers[dragPath.first]!.dx,
          layout.centers[dragPath.first]!.dy + 6, // Align with pressed tile
        );

      for (var index = 1; index < dragPath.length; index++) {
        final point = layout.centers[dragPath[index]]!;
        line.lineTo(point.dx, point.dy + 6); // Align with pressed tile
      }

      // Simple, pretty, thin line
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

    // Index numbers removed per user request

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
      // Shift everything down smoothly when pressed
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

    final double currentCoreRadiusScale = 0.10 + (0.12 * pressVal);

    if (pressVal > 0) {
      // Add a subtle soft glow effect that scales with pressVal
      canvas.drawCircle(
        center,
        layout.radius * (0.10 + (0.22 * pressVal)) * scale,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15 * pressVal * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Draw the center dot
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
