import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constant.dart';
import '../controllers/game_controller.dart';
import '../controllers/score_controller.dart';
import '../gameplay/game_constants.dart';
import '../widgets/dialogs/tutorial_dialog.dart';
import '../widgets/home_screen/background_painter.dart';
import 'board.dart';
import 'draggable_block.dart';
import 'score_bar.dart';

class GameScreen extends StatefulWidget {
  final bool shouldRestore;

  const GameScreen({super.key, this.shouldRestore = false});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GlobalKey _gridKey = GlobalKey();
  late final GameController controller;

  @override
  void initState() {
    super.initState();
    Get.put(ScoreController());
    controller = Get.put(GameController());
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    if (!widget.shouldRestore) {
      controller.resetGame();
      return;
    }

    final restored = await controller.loadGameState();
    if (restored) return;

    controller.resetGame();
    if (!mounted) return;

    Get.snackbar(
      'Restore unavailable',
      'That run was expired or damaged, so Rune Bloom started fresh.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: const Color(0xFFF8F6F1),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.home_rounded, color: charcoalBlack),
            onPressed: Get.back,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                appName,
                style: TextStyle(
                  color: charcoalBlack,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              Text(
                '$gameTitle · Merge 5 matching runes. Level 4 blooms explode.',
                style: TextStyle(
                  color: charcoalBlack.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon:
                  const Icon(Icons.help_outline_rounded, color: charcoalBlack),
              onPressed: controller.openTutorial,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: GridPatternPainter(),
              ),
            ),
            SafeArea(
              top: false,
              child: OrientationBuilder(
                builder: (context, orientation) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isPortrait = orientation == Orientation.portrait ||
                          constraints.maxWidth < 900;

                      return isPortrait
                          ? _buildPortraitLayout(constraints)
                          : _buildLandscapeLayout(constraints);
                    },
                  );
                },
              ),
            ),
            if (controller.showTutorial.value)
              Container(
                color: charcoalBlack.withValues(alpha: 0.72),
                child: TutorialDialog(onClose: controller.completeTutorial),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(BoxConstraints constraints) {
    var gridSize = constraints.maxWidth * 0.86;
    gridSize = gridSize.clamp(260.0, 560.0);

    final maxHeight = constraints.maxHeight * 0.58;
    if (gridSize > maxHeight) {
      gridSize = maxHeight;
    }

    final cellSize = gridSize / boardColumns;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: Column(
        children: [
          SizedBox(
            width: gridSize,
            child: const ScoreBar(),
          ),
          const SizedBox(height: 18),
          _buildBoardFrame(gridSize, cellSize),
          const SizedBox(height: 18),
          _buildHintCard(),
          const SizedBox(height: 18),
          _buildHandTray(gridSize, cellSize),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(BoxConstraints constraints) {
    final gridSize = (constraints.maxHeight * 0.8).clamp(320.0, 560.0);
    final cellSize = gridSize / boardColumns;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: _buildBoardFrame(gridSize, cellSize),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ScoreBar(),
                const SizedBox(height: 18),
                _buildHintCard(),
                const SizedBox(height: 18),
                _buildHandTray(cellSize * 3.8, cellSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardFrame(double gridSize, double cellSize) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: charcoalBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: SizedBox(
        width: gridSize,
        height: gridSize,
        child: Board(
          key: _gridKey,
          gridSize: gridSize,
          cellSize: cellSize,
        ),
      ),
    );
  }

  Widget _buildHintCard() {
    return Obx(() {
      final chain = controller.currentChain.value;
      final message = chain > 1
          ? 'Chain reaction x$chain. Upgraded runes can trigger another merge.'
          : 'Place all 3 rune clusters before the next hand appears.';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: charcoalBlack, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: charcoalBlack),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: charcoalBlack,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHandTray(double width, double cellSize) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: charcoalBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.view_in_ar_rounded,
                  color: charcoalBlack, size: 20),
              const SizedBox(width: 8),
              Text(
                'CURRENT HAND',
                style: TextStyle(
                  color: charcoalBlack.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < 3; i++)
                DraggableBlock(
                  index: i,
                  cellSize: cellSize,
                  gridKey: _gridKey,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
