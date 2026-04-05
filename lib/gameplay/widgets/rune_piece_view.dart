import 'package:flutter/material.dart';

import '../../constant.dart';
import '../game_constants.dart';
import '../models/rune_piece.dart';
import '../models/rune_type.dart';

class RunePieceView extends StatelessWidget {
  final RunePiece piece;
  final double cellSize;
  final double opacity;

  const RunePieceView({
    super.key,
    required this.piece,
    required this.cellSize,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    final cellColor =
        runeColorForLevel(piece.type, 1).withValues(alpha: opacity);

    return SizedBox(
      width: cellSize * 3,
      height: cellSize * 3,
      child: Stack(
        clipBehavior: Clip.none,
        children: piece.shape.map((offset) {
          return Positioned(
            left: offset.dx * cellSize,
            top: offset.dy * cellSize,
            child: Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(cellSize * 0.18),
                border: Border.all(color: charcoalBlack, width: 1.4),
                boxShadow: const [
                  BoxShadow(
                    color: charcoalBlack,
                    offset: Offset(1.5, 1.5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  piece.type.shortLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: cellSize * 0.34,
                    height: 1,
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
