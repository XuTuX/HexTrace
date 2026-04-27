part of 'package:hexor/game/hex_game_controller.dart';

void _startTutorial(HexGameController controller) {
  controller._gameVersion++;
  controller._timer?.cancel();

  // Reset stats
  controller.score = 0;
  controller.combo = 0;
  controller.maxCombo = 0;
  controller.longestPathLength = 0;
  controller.matchCount = 0;
  controller.invalidAttemptCount = 0;
  controller.bestMove = null;
  controller.timeRemaining = 999; 
  controller.isGameOver = false;
  controller.isResolvingMatch = false;
  controller.invalidPulse = false;
  controller.dragState = DragState.idle;
  controller.dragPath = const [];
  controller.clearingPath = const [];
  controller.lastMatchPath = const [];
  controller.animatedTiles = const {};
  controller.boardAnimationTick = 0;
  controller._lastMatchAt = null;
  controller._nextBarEntryId = 0;
  controller.statusText = '';
  controller.statusTone = GameMessageTone.info;

  // Set tutorial step
  controller.tutorialStepIndex = 0;
  
  // Setup a fixed board
  _setupTutorialBoard(controller);
  
  // Setup color bar (Full size like real game)
  final random = Random(42);
  final List<ColorBarEntry> initialBar = [];
  // First 4 entries: Coral, Mint, Azure, Violet
  initialBar.add(ColorBarEntry(id: controller._nextBarEntryId++, color: GameColor.coral));
  initialBar.add(ColorBarEntry(id: controller._nextBarEntryId++, color: GameColor.mint));
  initialBar.add(ColorBarEntry(id: controller._nextBarEntryId++, color: GameColor.azure));
  initialBar.add(ColorBarEntry(id: controller._nextBarEntryId++, color: GameColor.violet));
  
  // Rest random
  for (int i = 4; i < controller.colorBarSize; i++) {
    initialBar.add(ColorBarEntry(
      id: controller._nextBarEntryId++, 
      color: GameColorKey.baseColors[random.nextInt(GameColorKey.baseColors.length)],
    ));
  }
  controller.colorBar = initialBar;

  _updateTutorialStep(controller);
  controller._notify();
}

void _setupTutorialBoard(HexGameController controller) {
  // Create a 7x6 board with mostly random but some fixed colors
  final random = Random(42); // Fixed seed for tutorial
  final List<List<GameColor>> board = [];
  
  for (int r = 0; r < controller.rows; r++) {
    final List<GameColor> row = [];
    for (int c = 0; c < controller.cols; c++) {
      row.add(GameColorKey.baseColors[random.nextInt(GameColorKey.baseColors.length)]);
    }
    board.add(row);
  }

  // Force a sequence match: Coral, Mint, Azure
  board[1][1] = GameColor.coral;
  board[2][1] = GameColor.mint;
  board[3][1] = GameColor.azure;
  
  controller.board = board;
}

void _updateTutorialStep(HexGameController controller) {
  switch (controller.tutorialStepIndex) {
    case 0:
      controller.tutorialMessage = '반가워요! Hexor는 육각형 타일을 연결하는 게임이에요.';
      controller.tutorialHighlights = {};
      controller.tutorialBarHighlight = {};
      controller.tutorialPathHint = null;
      controller.tutorialRequiresInteraction = false;
      break;
    case 1:
      controller.tutorialMessage = '상단 컬러바의 처음 세 색상대로 연결해 보세요!\n(보너스 점수와 추가 시간을 얻습니다)';
      controller.tutorialHighlights = {
        const HexCoord(1, 1),
        const HexCoord(1, 2),
        const HexCoord(1, 3),
      };
      controller.tutorialBarHighlight = {0, 1, 2};
      controller.tutorialPathHint = [
        const HexCoord(1, 1),
        const HexCoord(1, 2),
        const HexCoord(1, 3),
      ];
      controller.tutorialRequiresInteraction = true;
      break;
    case 2:
      controller.tutorialMessage = '시퀀스는 꼭 처음부터 시작하지 않아도 돼요.\n컬러바의 중간 어디든 3개 이상 이어지면 보너스!';
      
      // Force color bar to have Mint, Azure, Violet at indices 1, 2, 3
      final bar = List<ColorBarEntry>.from(controller.colorBar);
      if (bar.length >= 4) {
        bar[0] = ColorBarEntry(id: bar[0].id, color: GameColor.azure); // Padding
        bar[1] = ColorBarEntry(id: bar[1].id, color: GameColor.mint);
        bar[2] = ColorBarEntry(id: bar[2].id, color: GameColor.azure);
        bar[3] = ColorBarEntry(id: bar[3].id, color: GameColor.violet);
      }
      controller.colorBar = bar;

      // Update board for second match (Mint, Azure, Violet)
      final board = controller.board;
      board[1][4] = GameColor.mint;
      board[2][4] = GameColor.azure;
      board[3][4] = GameColor.violet;
      controller.board = board;
      controller.boardAnimationTick++;

      controller.tutorialHighlights = {
        const HexCoord(4, 1),
        const HexCoord(4, 2),
        const HexCoord(4, 3),
      };
      controller.tutorialBarHighlight = {1, 2, 3};
      controller.tutorialPathHint = [
        const HexCoord(4, 1),
        const HexCoord(4, 2),
        const HexCoord(4, 3),
      ];
      controller.tutorialRequiresInteraction = true;
      break;
    case 3:
      controller.tutorialMessage = '대단해요! 이렇게 컬러바를 활용하면 점수를 더 빨리 올릴 수 있어요.';
      controller.tutorialHighlights = {};
      controller.tutorialBarHighlight = {};
      controller.tutorialPathHint = null;
      controller.tutorialRequiresInteraction = false;
      break;
    case 4:
      controller.tutorialMessage = '축하합니다! 이제 진짜 게임에서 실력을 발휘해 보세요!';
      controller.tutorialHighlights = {};
      controller.tutorialBarHighlight = {};
      controller.tutorialPathHint = null;
      controller.tutorialRequiresInteraction = false;
      break;
  }
}

void _nextTutorialStep(HexGameController controller) {
  controller.tutorialStepIndex++;
  if (controller.tutorialStepIndex > 4) {
    // End tutorial
    Get.find<SettingsService>().completeTutorial();
    
    // Clear tutorial state specifically before reset
    controller.tutorialMessage = null;
    controller.tutorialHighlights = {};
    controller.tutorialBarHighlight = {};
    controller.tutorialPathHint = null;
    controller.tutorialRequiresInteraction = false;
    
    _resetGame(controller);
    Get.back();
    return;
  }
  _updateTutorialStep(controller);
  controller._notify();
}
