import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:linkagon/game/hex_game_controller.dart';

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
    final safeWidth = math.max(size.width - 12, 40).toDouble();
    final safeHeight = math.max(size.height - 12, 40).toDouble();
    final radiusFromWidth = safeWidth / (sqrt3 * (cols + 0.5));
    final radiusFromHeight = safeHeight / (2 + (rows - 1) * 1.5);
    final radius =
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
