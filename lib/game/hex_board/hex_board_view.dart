import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:hexor/game/hex_game_controller.dart';

import 'hex_board_layout.dart';
import 'hex_board_painter.dart';

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
  Offset? _lastDragPosition;
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

    final dt = (elapsed - _lastTick).inMilliseconds / 1000.0;
    _lastTick = elapsed;
    var needsRepaint = false;

    for (int row = 0; row < widget.controller.rows; row++) {
      for (int col = 0; col < widget.controller.cols; col++) {
        final coord = HexCoord(col, row);
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

  HexCoord? _resolveTouch(HexBoardLayout layout, Offset position) {
    final directHit = layout.hitTest(position);
    if (directHit != null) {
      return directHit;
    }

    final lastCoord = widget.controller.dragPath.isNotEmpty
        ? widget.controller.dragPath.last
        : null;

    if (lastCoord != null) {
      final adjacentHit = layout.nearestCoord(
        position,
        maxDistance: layout.radius * 1.15,
        where: (coord) =>
            coord == lastCoord ||
            widget.controller.isAdjacent(lastCoord, coord),
      );
      if (adjacentHit != null) {
        return adjacentHit;
      }
    }

    return layout.nearestCoord(
      position,
      maxDistance: layout.radius * 0.95,
    );
  }

  void _handlePanStart(HexBoardLayout layout, DragStartDetails details) {
    _lastDragPosition = details.localPosition;
    widget.controller.beginDrag(_resolveTouch(layout, details.localPosition));
  }

  void _handlePanUpdate(HexBoardLayout layout, DragUpdateDetails details) {
    final currentPosition = details.localPosition;
    final previousPosition = _lastDragPosition ?? currentPosition;
    final distance = (currentPosition - previousPosition).distance;
    final sampleStep = math.max(8.0, layout.radius * 0.45);
    final sampleCount = math.max(1, (distance / sampleStep).ceil());

    for (var index = 1; index <= sampleCount; index++) {
      final t = index / sampleCount;
      final samplePosition =
          Offset.lerp(previousPosition, currentPosition, t) ?? currentPosition;
      widget.controller.extendDrag(_resolveTouch(layout, samplePosition));
    }

    _lastDragPosition = currentPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    _lastDragPosition = null;
    widget.controller.endDrag();
  }

  void _handlePanCancel() {
    _lastDragPosition = null;
    widget.controller.cancelDrag();
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
          onPanStart: (details) => _handlePanStart(layout, details),
          onPanUpdate: (details) => _handlePanUpdate(layout, details),
          onPanEnd: _handlePanEnd,
          onPanCancel: _handlePanCancel,
          child: AnimatedBuilder(
            animation: Listenable.merge([widget.controller, _refillController]),
            builder: (context, _) {
              return CustomPaint(
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
              );
            },
          ),
        );
      },
    );
  }
}
