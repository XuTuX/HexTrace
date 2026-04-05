import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constant.dart';
import '../controllers/game_controller.dart';
import '../gameplay/game_constants.dart';
import '../gameplay/models/rune_type.dart';

class Board extends StatelessWidget {
  final double gridSize;
  final double cellSize;

  const Board({
    super.key,
    required this.gridSize,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GameController>();

    return SizedBox(
      width: gridSize,
      height: gridSize,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: boardColumns,
        ),
        itemCount: boardColumns * boardRows,
        itemBuilder: (context, index) {
          return Obx(() {
            final row = index ~/ boardColumns;
            final column = index % boardColumns;

            final cell = controller.board[row][column];
            final isHover = controller.hoverCells.contains(index);
            final isFresh = controller.lastPlacedCells.contains(index);
            final isCleared = controller.lastClearedCells.contains(index);

            final background = isHover
                ? controller.hoverColor.value ?? Colors.white
                : cell == null
                    ? const Color(0xFFF7F2E8)
                    : runeColorForLevel(cell.type, cell.level);

            final borderColor = cell == null
                ? charcoalBlack12
                : runeColor(cell.type).withValues(alpha: 0.95);

            return AnimatedScale(
              scale: isFresh ? 1.06 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: isCleared ? 0.25 : 1,
                duration: const Duration(milliseconds: 250),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.all(1.4),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: borderColor, width: 1.4),
                    boxShadow: cell == null
                        ? null
                        : [
                            BoxShadow(
                              color: charcoalBlack.withValues(alpha: 0.12),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: cell == null
                      ? null
                      : Stack(
                          children: [
                            Center(
                              child: Text(
                                cell.type.shortLabel,
                                style: TextStyle(
                                  fontSize: cellSize * 0.34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ),
                            if (cell.level > 1)
                              Positioned(
                                top: 3,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    '${cell.level}',
                                    style: TextStyle(
                                      color: charcoalBlack,
                                      fontSize: cellSize * 0.2,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
