part of 'package:hexor/game/hex_game_controller.dart';

void _randomizeBoardUntilPlayable(HexGameController controller) {
  for (var attempt = 0; attempt < 200; attempt++) {
    final counts = <GameColor, int>{};
    controller.board = List<List<GameColor>>.generate(
      controller.rows,
      (_) => List<GameColor>.generate(
        controller.cols,
        (_) {
          final nextColor = _weightedBoardColor(controller, counts);
          counts[nextColor] = (counts[nextColor] ?? 0) + 1;
          return nextColor;
        },
        growable: false,
      ),
      growable: false,
    );

    if (_hasAnyValidMove(controller)) {
      return;
    }
  }

  _endGame(controller, '플레이 가능한 보드를 만들지 못했어요.');
}

int _scoreForLength(HexGameController controller, int length, int comboCount) {
  const baseScore = 100;
  final extraBlocks = max(0, length - 3);
  final lengthBonus = (extraBlocks * 150) + (extraBlocks * extraBlocks * 50);
  final comboBonus = max(0, comboCount - 1) * 50;

  return baseScore + lengthBonus + comboBonus;
}

double _timeBonusForLength(HexGameController controller, int length) {
  return 1.4 + max(0, length - 2) * 0.65;
}

GameColor _randomColor(HexGameController controller) {
  return GameColorKey.baseColors[controller._random.nextInt(GameColorKey.baseColors.length)];
}

Map<GameColor, int> _colorCountsFromBoard(
  HexGameController controller,
  List<List<GameColor?>> sourceBoard,
) {
  final counts = <GameColor, int>{};

  for (final row in sourceBoard) {
    for (final color in row) {
      if (color == null) {
        continue;
      }
      counts[color] = (counts[color] ?? 0) + 1;
    }
  }

  return counts;
}

GameColor _weightedBoardColor(
  HexGameController controller,
  Map<GameColor, int> counts,
) {
  final totalTiles = counts.values.fold<int>(0, (sum, value) => sum + value);
  final average = totalTiles / GameColorKey.baseColors.length;
  final weights = <GameColor, double>{};
  var totalWeight = 0.0;

  for (final color in GameColorKey.baseColors) {
    final count = (counts[color] ?? 0).toDouble();
    final deltaFromAverage = count - average;
    final weight = deltaFromAverage <= 0
        ? 1.0 + (-deltaFromAverage * 0.08)
        : 1.0 / (1.0 + (deltaFromAverage * 0.35));

    weights[color] = weight;
    totalWeight += weight;
  }

  var roll = controller._random.nextDouble() * totalWeight;
  for (final color in GameColorKey.baseColors) {
    roll -= weights[color]!;
    if (roll <= 0) {
      return color;
    }
  }

  return GameColorKey.baseColors.last;
}

void _refillColorBar(HexGameController controller) {
  final nextBar = List<ColorBarEntry>.from(controller.colorBar);

  while (nextBar.length < controller.colorBarSize) {
    nextBar.add(_newBarEntry(controller, existingEntries: nextBar));
  }

  controller.colorBar = List<ColorBarEntry>.unmodifiable(nextBar);
}

GameColor _nextBarColor(
  HexGameController controller, {
  required List<ColorBarEntry> existingEntries,
}) {
  final presentColors = existingEntries.map((entry) => entry.color).toSet();
  final missingColors = GameColorKey.baseColors
      .where((color) => !presentColors.contains(color))
      .toList(growable: false);

  if (missingColors.isEmpty) {
    return _randomColor(controller);
  }

  return missingColors[controller._random.nextInt(missingColors.length)];
}

ColorBarEntry _newBarEntry(
  HexGameController controller, {
  List<ColorBarEntry> existingEntries = const [],
}) {
  return ColorBarEntry(
    id: controller._nextBarEntryId++,
    color: _nextBarColor(controller, existingEntries: existingEntries),
  );
}
