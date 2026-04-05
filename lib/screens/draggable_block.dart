import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/game_controller.dart';
import '../gameplay/game_constants.dart';
import '../gameplay/models/rune_piece.dart';
import '../gameplay/widgets/rune_piece_view.dart';

class DraggableBlock extends StatelessWidget {
  final int index;
  final double cellSize;
  final GlobalKey gridKey;

  const DraggableBlock({
    super.key,
    required this.index,
    required this.cellSize,
    required this.gridKey,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GameController>();

    return Obx(() {
      if (index >= controller.activePieces.length ||
          controller.activePieces[index] == null) {
        return const SizedBox(width: handSlotSize, height: handSlotSize);
      }

      final piece = controller.activePieces[index]!;

      return Draggable<int>(
        data: index,
        feedback: Material(
          color: Colors.transparent,
          child: RunePieceView(
            piece: piece,
            cellSize: cellSize,
            opacity: 0.8,
          ),
        ),
        childWhenDragging: SizedBox(
          width: cellSize * 3,
          height: cellSize * 3,
        ),
        dragAnchorStrategy: (draggable, context, position) {
          return Offset(1.5 * cellSize, 3.0 * cellSize);
        },
        onDragUpdate: (details) {
          _handleDragUpdate(details, controller, piece);
        },
        onDragEnd: (details) {
          _handleDragEnd(details, controller, piece, index);
        },
        child: Container(
          width: cellSize * 3,
          height: cellSize * 3,
          alignment: Alignment.center,
          child: RunePieceView(
            piece: piece,
            cellSize: cellSize * 0.8,
          ),
        ),
      );
    });
  }

  void _handleDragUpdate(
    DragUpdateDetails details,
    GameController controller,
    RunePiece piece,
  ) {
    final gridBox = gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    final anchor = Offset(1.5 * cellSize, 3.0 * cellSize);
    final dropPosition = details.globalPosition - anchor;
    final gridPosition = gridBox.localToGlobal(Offset.zero);

    final centerX = dropPosition.dx + (1.5 * cellSize);
    final centerY = dropPosition.dy + (1.5 * cellSize);

    final relativeX = centerX - gridPosition.dx;
    final relativeY = centerY - gridPosition.dy;

    final centerColumn = (relativeX / cellSize).floor();
    final centerRow = (relativeY / cellSize).floor();

    controller.updateHover(centerRow, centerColumn, piece);
  }

  void _handleDragEnd(
    DraggableDetails details,
    GameController controller,
    RunePiece piece,
    int index,
  ) {
    final gridBox = gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    final gridPosition = gridBox.localToGlobal(Offset.zero);
    final centerX = details.offset.dx + (1.5 * cellSize);
    final centerY = details.offset.dy + (1.5 * cellSize);
    final relativeX = centerX - gridPosition.dx;
    final relativeY = centerY - gridPosition.dy;

    final centerColumn = (relativeX / cellSize).floor();
    final centerRow = (relativeY / cellSize).floor();

    controller.placePiece(centerRow, centerColumn, index);
  }
}
