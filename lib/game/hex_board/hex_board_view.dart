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
          onPanStart: (details) {
            widget.controller.beginDrag(layout.hitTest(details.localPosition));
          },
          onPanUpdate: (details) {
            widget.controller.extendDrag(layout.hitTest(details.localPosition));
          },
          onPanEnd: (_) => widget.controller.endDrag(),
          onPanCancel: widget.controller.cancelDrag,
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
