import 'dart:math';

enum HexTileColor {
  coral,
  amber,
  lime,
  teal,
  blue,
  violet,
}

enum DragPathStatus {
  idle,
  building,
  exact,
  invalid,
}

class HexCoord {
  final int row;
  final int column;

  const HexCoord(this.row, this.column);

  @override
  bool operator ==(Object other) {
    return other is HexCoord && other.row == row && other.column == column;
  }

  @override
  int get hashCode => Object.hash(row, column);
}

class BarWindowMatch {
  final int start;
  final int end;

  const BarWindowMatch({
    required this.start,
    required this.end,
  });

  int get length => end - start + 1;
}

class DragEvaluation {
  final DragPathStatus status;
  final BarWindowMatch? window;

  const DragEvaluation._({
    required this.status,
    this.window,
  });

  const DragEvaluation.idle() : this._(status: DragPathStatus.idle);

  const DragEvaluation.building(BarWindowMatch window)
      : this._(
          status: DragPathStatus.building,
          window: window,
        );

  const DragEvaluation.exact(BarWindowMatch window)
      : this._(
          status: DragPathStatus.exact,
          window: window,
        );

  const DragEvaluation.invalid() : this._(status: DragPathStatus.invalid);

  bool get isExactMatch => status == DragPathStatus.exact && window != null;
}

class HexPuzzleLogic {
  static const int boardRows = 7;
  static const int boardColumns = 7;
  static const int colorBarLength = 5;
  static const int minimumPathLength = 3;
  static const int initialTimeSeconds = 75;
  static const int maximumTimeSeconds = 99;

  static const List<HexTileColor> palette = [
    HexTileColor.coral,
    HexTileColor.amber,
    HexTileColor.lime,
    HexTileColor.teal,
    HexTileColor.blue,
  ];

  static List<List<HexTileColor>> randomBoard(
    Random random, {
    int rows = boardRows,
    int columns = boardColumns,
  }) {
    return List.generate(
      rows,
      (_) => List.generate(columns, (_) => randomColor(random)),
      growable: false,
    );
  }

  static List<HexTileColor> randomColorBar(
    Random random, {
    int length = colorBarLength,
  }) {
    return List.generate(length, (_) => randomColor(random), growable: false);
  }

  static HexTileColor randomColor(Random random) {
    return palette[random.nextInt(palette.length)];
  }

  static List<HexCoord> neighbors(
    HexCoord origin, {
    int rows = boardRows,
    int columns = boardColumns,
  }) {
    // Odd-r offset coordinates keep the model rectangular while rendering
    // as a staggered honeycomb grid.
    const evenRowOffsets = [
      (-1, -1),
      (-1, 0),
      (0, -1),
      (0, 1),
      (1, -1),
      (1, 0),
    ];
    const oddRowOffsets = [
      (-1, 0),
      (-1, 1),
      (0, -1),
      (0, 1),
      (1, 0),
      (1, 1),
    ];

    final offsets = origin.row.isEven ? evenRowOffsets : oddRowOffsets;

    return offsets
        .map(
          (offset) => HexCoord(
            origin.row + offset.$1,
            origin.column + offset.$2,
          ),
        )
        .where(
          (coord) =>
              coord.row >= 0 &&
              coord.row < rows &&
              coord.column >= 0 &&
              coord.column < columns,
        )
        .toList(growable: false);
  }

  static bool areAdjacent(HexCoord a, HexCoord b) {
    return neighbors(a).contains(b);
  }

  static DragEvaluation evaluatePath(
    List<HexTileColor> path,
    List<HexTileColor> colorBar,
  ) {
    if (path.isEmpty) {
      return const DragEvaluation.idle();
    }

    BarWindowMatch? previewWindow;
    BarWindowMatch? exactWindow;

    for (final window in contiguousWindows(colorBar)) {
      final candidate = colorBar.sublist(window.start, window.end + 1);
      if (path.length > candidate.length) {
        continue;
      }

      var matchesPrefix = true;
      for (var index = 0; index < path.length; index++) {
        if (path[index] != candidate[index]) {
          matchesPrefix = false;
          break;
        }
      }

      if (!matchesPrefix) {
        continue;
      }

      previewWindow ??= window;
      if (path.length == candidate.length) {
        exactWindow ??= window;
      }
    }

    if (exactWindow != null && path.length >= minimumPathLength) {
      return DragEvaluation.exact(exactWindow);
    }

    if (previewWindow != null) {
      return DragEvaluation.building(previewWindow);
    }

    return const DragEvaluation.invalid();
  }

  static List<BarWindowMatch> contiguousWindows(List<HexTileColor> colorBar) {
    final windows = <BarWindowMatch>[];

    for (var start = 0; start <= colorBar.length - minimumPathLength; start++) {
      for (var end = start + minimumPathLength - 1;
          end < colorBar.length;
          end++) {
        windows.add(BarWindowMatch(start: start, end: end));
      }
    }

    return windows;
  }

  static bool hasAnyValidMove(
    List<List<HexTileColor>> board,
    List<HexTileColor> colorBar,
  ) {
    for (final window in contiguousWindows(colorBar)) {
      final target = colorBar.sublist(window.start, window.end + 1);

      for (var row = 0; row < board.length; row++) {
        for (var column = 0; column < board[row].length; column++) {
          if (board[row][column] != target.first) {
            continue;
          }

          final visited = <HexCoord>{HexCoord(row, column)};
          if (_searchSequence(
            board: board,
            current: HexCoord(row, column),
            target: target,
            targetIndex: 0,
            visited: visited,
          )) {
            return true;
          }
        }
      }
    }

    return false;
  }

  static bool _searchSequence({
    required List<List<HexTileColor>> board,
    required HexCoord current,
    required List<HexTileColor> target,
    required int targetIndex,
    required Set<HexCoord> visited,
  }) {
    if (targetIndex == target.length - 1) {
      return true;
    }

    final nextColor = target[targetIndex + 1];
    for (final neighbor in neighbors(
      current,
      rows: board.length,
      columns: board.first.length,
    )) {
      if (visited.contains(neighbor)) {
        continue;
      }
      if (board[neighbor.row][neighbor.column] != nextColor) {
        continue;
      }

      visited.add(neighbor);
      final found = _searchSequence(
        board: board,
        current: neighbor,
        target: target,
        targetIndex: targetIndex + 1,
        visited: visited,
      );
      if (found) {
        return true;
      }
      visited.remove(neighbor);
    }

    return false;
  }

  static List<List<HexTileColor>> removePathAndRefill(
    List<List<HexTileColor>> board,
    List<HexCoord> path,
    Random random,
  ) {
    final working = board
        .map((row) => row.cast<HexTileColor?>().toList(growable: false))
        .toList(growable: false);

    for (final coord in path) {
      working[coord.row][coord.column] = null;
    }

    for (var column = 0; column < working.first.length; column++) {
      final survivors = <HexTileColor>[];
      for (var row = working.length - 1; row >= 0; row--) {
        final value = working[row][column];
        if (value != null) {
          survivors.add(value);
        }
      }

      var cursor = working.length - 1;
      for (final value in survivors) {
        working[cursor][column] = value;
        cursor--;
      }

      while (cursor >= 0) {
        working[cursor][column] = randomColor(random);
        cursor--;
      }
    }

    return working
        .map(
          (row) => row.map((cell) => cell!).toList(growable: false),
        )
        .toList(growable: false);
  }

  static List<HexTileColor> consumeColorBarWindow(
    List<HexTileColor> colorBar,
    BarWindowMatch window,
    Random random,
  ) {
    final nextBar = List<HexTileColor>.from(colorBar)
      ..removeRange(window.start, window.end + 1);

    while (nextBar.length < colorBar.length) {
      nextBar.add(randomColor(random));
    }

    return nextBar;
  }

  static List<List<HexTileColor>> shuffledBoard(
    List<List<HexTileColor>> board,
    Random random,
  ) {
    final colors = board.expand((row) => row).toList(growable: true)
      ..shuffle(random);
    var index = 0;

    return List.generate(
      board.length,
      (_) => List.generate(
        board.first.length,
        (_) => colors[index++],
        growable: false,
      ),
      growable: false,
    );
  }

  static List<HexTileColor> shuffledColorBar(
    List<HexTileColor> colorBar,
    Random random,
  ) {
    final next = List<HexTileColor>.from(colorBar)..shuffle(random);
    return next;
  }

  static int scoreForPath(int pathLength, int comboDepth) {
    final base = 80 + (pathLength * 45);
    final lengthBonus = max(0, pathLength - minimumPathLength) * 35;
    final comboBonus = max(0, comboDepth - 1) * 50;
    return base + lengthBonus + comboBonus;
  }

  static int timeBonusForPath(int pathLength) {
    return min(6, 2 + max(0, pathLength - minimumPathLength));
  }
}
