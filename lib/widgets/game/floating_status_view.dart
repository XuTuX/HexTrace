import 'package:flutter/material.dart';

import 'package:linkagon/constant.dart';
import 'package:linkagon/game/hex_board_view.dart';
import 'package:linkagon/game/hex_game_controller.dart';

class FloatingStatusView extends StatefulWidget {
  const FloatingStatusView({super.key, required this.controller});

  final HexGameController controller;

  @override
  State<FloatingStatusView> createState() => _FloatingStatusViewState();
}

class _FloatingStatusViewState extends State<FloatingStatusView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacity;
  late Animation<double> _translateY;

  String _currentText = '';
  int _lastScore = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1), weight: 55),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 30),
    ]).animate(_animController);
    _translateY = Tween<double>(begin: 10, end: -40).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant FloatingStatusView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.score > _lastScore) {
      _lastScore = widget.controller.score;
      setState(() {
        _currentText = widget.controller.statusText;
      });
      _animController.forward(from: 0);
    } else if (widget.controller.score == 0) {
      _lastScore = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        if (_animController.isDismissed || _currentText.isEmpty) {
          return const SizedBox.shrink();
        }

        final isCombo = _currentText.contains('COMBO');
        final textLines = _currentText.split('\n');

        return LayoutBuilder(
          builder: (context, constraints) {
            Offset centerOffset =
                Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

            if (widget.controller.lastMatchPath.isNotEmpty) {
              final layout = HexBoardLayout.fromSize(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                rows: widget.controller.rows,
                cols: widget.controller.cols,
              );

              double sumX = 0;
              double sumY = 0;
              for (final coord in widget.controller.lastMatchPath) {
                final point = layout.centers[coord]!;
                sumX += point.dx;
                sumY += point.dy;
              }
              centerOffset = Offset(
                sumX / widget.controller.lastMatchPath.length,
                sumY / widget.controller.lastMatchPath.length,
              );
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: centerOffset.dx,
                  top: centerOffset.dy,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: Transform.translate(
                      offset: Offset(0, _translateY.value),
                      child: Transform.rotate(
                        angle: isCombo ? -0.05 : 0,
                        child: Opacity(
                          opacity: _opacity.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isCombo ? Colors.amberAccent : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: charcoalBlack, width: 3.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: charcoalBlack,
                                  offset: Offset(0, 4),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: textLines.map((line) {
                                final isComboLine = line.startsWith('COMBO');
                                return Text(
                                  line,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: charcoalBlack,
                                    fontSize:
                                        isComboLine ? 14 : (isCombo ? 20 : 18),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    height: 1.1,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
