part of 'package:hexor/game/hex_game_controller.dart';

List<HexCoord> _neighborsOf(HexGameController controller, HexCoord coord) {
  final oddRow = coord.row.isOdd;
  final List<(int, int)> deltas = oddRow
      ? const [(-1, 0), (1, 0), (0, -1), (1, -1), (0, 1), (1, 1)]
      : const [(-1, 0), (1, 0), (-1, -1), (0, -1), (-1, 1), (0, 1)];

  return deltas
      .map((delta) => HexCoord(coord.col + delta.$1, coord.row + delta.$2))
      .where((candidate) => _isOnBoard(controller, candidate))
      .toList(growable: false);
}

bool _isAdjacent(HexGameController controller, HexCoord a, HexCoord b) {
  return _neighborsOf(controller, a).contains(b);
}

bool _sequenceMatchesAnyBarWindow(
  HexGameController controller,
  List<GameColor> sequence,
) {
  return _matchingBarWindowsForSequence(controller, sequence).isNotEmpty;
}

List<BarWindow> _matchingBarWindowsForSequence(
  HexGameController controller,
  List<GameColor> sequence,
) {
  if (sequence.isEmpty || sequence.length > controller.colorBar.length) {
    return const [];
  }

  final matches = <BarWindow>[];

  for (var start = 0;
      start <= controller.colorBar.length - sequence.length;
      start++) {
    var matched = true;

    for (var offset = 0; offset < sequence.length; offset++) {
      if (controller.colorBar[start + offset].color != sequence[offset]) {
        matched = false;
        break;
      }
    }

    if (matched) {
      matches.add(BarWindow(start, start + sequence.length - 1));
    }
  }

  return matches;
}

bool _hasAnyValidMove(HexGameController controller) {
  final seenSequences = <String>{};

  for (var length = 3; length <= controller.colorBar.length; length++) {
    for (var start = 0; start <= controller.colorBar.length - length; start++) {
      final sequence = controller.colorBar
          .sublist(start, start + length)
          .map((entry) => entry.color)
          .toList(growable: false);
      final key = sequence.map((color) => color.key).join('-');

      if (!seenSequences.add(key)) {
        continue;
      }

      for (var row = 0; row < controller.rows; row++) {
        for (var col = 0; col < controller.cols; col++) {
          final origin = HexCoord(col, row);

          if (controller.board[row][col] == sequence.first &&
              _canTraceSequence(
                controller,
                origin,
                sequence,
                0,
                <HexCoord>{origin},
              )) {
            return true;
          }
        }
      }
    }
  }

  return false;
}

bool _canTraceSequence(
  HexGameController controller,
  HexCoord current,
  List<GameColor> sequence,
  int index,
  Set<HexCoord> visited,
) {
  if (index == sequence.length - 1) {
    return true;
  }

  for (final neighbor in _neighborsOf(controller, current)) {
    if (visited.contains(neighbor)) {
      continue;
    }

    if (controller.board[neighbor.row][neighbor.col] != sequence[index + 1]) {
      continue;
    }

    visited.add(neighbor);

    if (_canTraceSequence(controller, neighbor, sequence, index + 1, visited)) {
      return true;
    }

    visited.remove(neighbor);
  }

  return false;
}

List<GameColor> _colorsForPath(
  HexGameController controller,
  List<HexCoord> path,
) {
  return path
      .map((coord) => controller.board[coord.row][coord.col])
      .toList(growable: false);
}

bool _isOnBoard(HexGameController controller, HexCoord coord) {
  return coord.row >= 0 &&
      coord.row < controller.rows &&
      coord.col >= 0 &&
      coord.col < controller.cols;
}
