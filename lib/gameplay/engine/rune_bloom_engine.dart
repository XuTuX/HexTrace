import 'dart:math';

import '../game_constants.dart';
import '../models/board_cell.dart';
import '../models/rune_piece.dart';

class CascadeResolution {
  final List<List<BoardCell?>> board;
  final int cascadeScore;
  final int highestChain;
  final List<int> clearedCells;
  final List<int> upgradedCells;

  const CascadeResolution({
    required this.board,
    required this.cascadeScore,
    required this.highestChain,
    required this.clearedCells,
    required this.upgradedCells,
  });
}

class RescueWindow {
  final int startRow;
  final int startColumn;
  final int occupiedCells;

  const RescueWindow({
    required this.startRow,
    required this.startColumn,
    required this.occupiedCells,
  });
}

class _MergeGroup {
  final BoardCell cell;
  final List<Point<int>> members;

  const _MergeGroup({
    required this.cell,
    required this.members,
  });
}

class RuneBloomEngine {
  static List<List<BoardCell?>> createEmptyBoard() {
    return List.generate(
      boardRows,
      (_) => List<BoardCell?>.filled(boardColumns, null),
    );
  }

  static List<List<BoardCell?>> cloneBoard(List<List<BoardCell?>> board) {
    return board
        .map(
          (row) => row.map((cell) => cell?.copyWith()).toList(growable: false),
        )
        .toList(growable: false);
  }

  static List<Point<int>> pieceCellsAtCenter(
    RunePiece piece,
    int centerRow,
    int centerColumn,
  ) {
    return piece.shape
        .map(
          (offset) => Point<int>(
            (centerRow - 1) + offset.dy.toInt(),
            (centerColumn - 1) + offset.dx.toInt(),
          ),
        )
        .toList(growable: false);
  }

  static bool canPlacePieceAtCenter(List<List<BoardCell?>> board,
      RunePiece piece, int centerRow, int centerColumn,
      {Set<int> ignoredCells = const <int>{}}) {
    for (final cell in pieceCellsAtCenter(piece, centerRow, centerColumn)) {
      if (cell.x < 0 ||
          cell.x >= boardRows ||
          cell.y < 0 ||
          cell.y >= boardColumns) {
        return false;
      }

      final cellIndex = toCellIndex(cell.x, cell.y);
      if (ignoredCells.contains(cellIndex)) {
        continue;
      }

      if (board[cell.x][cell.y] != null) {
        return false;
      }
    }

    return true;
  }

  static bool canPlacePieceAnywhere(
    List<List<BoardCell?>> board,
    RunePiece piece, {
    Set<int> ignoredCells = const <int>{},
  }) {
    const int padding = 4;

    for (int row = -padding; row < boardRows + padding; row++) {
      for (int column = -padding; column < boardColumns + padding; column++) {
        if (canPlacePieceAtCenter(
          board,
          piece,
          row,
          column,
          ignoredCells: ignoredCells,
        )) {
          return true;
        }
      }
    }

    return false;
  }

  static CascadeResolution resolveCascades(
    List<List<BoardCell?>> initialBoard,
  ) {
    final board = cloneBoard(initialBoard);
    final clearedCells = <int>{};
    final upgradedCells = <int>{};
    int cascadeScore = 0;
    int chain = 0;

    while (true) {
      final groups = _findMergeGroups(board);
      if (groups.isEmpty) break;

      chain += 1;

      final cellsToClear = <Point<int>>{};
      final upgrades = <Point<int>, BoardCell>{};

      for (final group in groups) {
        if (group.cell.level >= maxRuneLevel) {
          final blastZone = <Point<int>>{};
          for (final cell in group.members) {
            blastZone.add(cell);
            for (int dx = -1; dx <= 1; dx++) {
              for (int dy = -1; dy <= 1; dy++) {
                final nextRow = cell.x + dx;
                final nextColumn = cell.y + dy;
                if (_isInsideBoard(nextRow, nextColumn)) {
                  blastZone.add(Point<int>(nextRow, nextColumn));
                }
              }
            }
          }

          cellsToClear.addAll(blastZone);
          cascadeScore +=
              (group.members.length * 45 + blastZone.length * 8) * chain;
          continue;
        }

        final anchor = _pickAnchor(group.members);
        upgrades[anchor] = BoardCell(
          type: group.cell.type,
          level: group.cell.level + 1,
        );

        for (final member in group.members) {
          if (member != anchor) {
            cellsToClear.add(member);
          }
        }

        cascadeScore += (group.members.length * 18 * group.cell.level) * chain;
      }

      for (final cell in cellsToClear) {
        board[cell.x][cell.y] = null;
        clearedCells.add(toCellIndex(cell.x, cell.y));
      }

      upgrades.forEach((point, value) {
        if (cellsToClear.contains(point)) {
          return;
        }

        board[point.x][point.y] = value;
        upgradedCells.add(toCellIndex(point.x, point.y));
      });
    }

    return CascadeResolution(
      board: board,
      cascadeScore: cascadeScore,
      highestChain: chain,
      clearedCells: clearedCells.toList(growable: false),
      upgradedCells: upgradedCells.toList(growable: false),
    );
  }

  static RescueWindow? findBestRescueWindow(
    List<List<BoardCell?>> board,
    Iterable<RunePiece?> pieces,
  ) {
    RescueWindow? bestWindow;

    for (int row = 0; row <= boardRows - 3; row++) {
      for (int column = 0; column <= boardColumns - 3; column++) {
        final clearedIndices = <int>{};
        int occupiedCells = 0;

        for (int y = row; y < row + 3; y++) {
          for (int x = column; x < column + 3; x++) {
            if (board[y][x] != null) {
              occupiedCells += 1;
              clearedIndices.add(toCellIndex(y, x));
            }
          }
        }

        if (occupiedCells == 0) {
          continue;
        }

        final helps = pieces.any(
          (piece) =>
              piece != null &&
              canPlacePieceAnywhere(
                board,
                piece,
                ignoredCells: clearedIndices,
              ),
        );

        if (!helps) {
          continue;
        }

        if (bestWindow == null || occupiedCells > bestWindow.occupiedCells) {
          bestWindow = RescueWindow(
            startRow: row,
            startColumn: column,
            occupiedCells: occupiedCells,
          );
        }
      }
    }

    return bestWindow;
  }

  static int toCellIndex(int row, int column) {
    return row * boardColumns + column;
  }

  static List<_MergeGroup> _findMergeGroups(List<List<BoardCell?>> board) {
    final visited = <String>{};
    final groups = <_MergeGroup>[];

    for (int row = 0; row < boardRows; row++) {
      for (int column = 0; column < boardColumns; column++) {
        final cell = board[row][column];
        if (cell == null) continue;

        final visitKey = '$row:$column';
        if (visited.contains(visitKey)) {
          continue;
        }

        final group = _collectGroup(board, row, column, cell);
        for (final member in group) {
          visited.add('${member.x}:${member.y}');
        }

        if (group.length >= mergeThreshold) {
          groups.add(_MergeGroup(cell: cell, members: group));
        }
      }
    }

    return groups;
  }

  static List<Point<int>> _collectGroup(
    List<List<BoardCell?>> board,
    int startRow,
    int startColumn,
    BoardCell seed,
  ) {
    final queue = <Point<int>>[Point<int>(startRow, startColumn)];
    final result = <Point<int>>[];
    final seen = <String>{'$startRow:$startColumn'};

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      result.add(current);

      for (final direction in const [
        Point<int>(-1, 0),
        Point<int>(1, 0),
        Point<int>(0, -1),
        Point<int>(0, 1),
      ]) {
        final nextRow = current.x + direction.x;
        final nextColumn = current.y + direction.y;
        if (!_isInsideBoard(nextRow, nextColumn)) {
          continue;
        }

        final nextCell = board[nextRow][nextColumn];
        if (nextCell == null ||
            nextCell.type != seed.type ||
            nextCell.level != seed.level) {
          continue;
        }

        final nextKey = '$nextRow:$nextColumn';
        if (seen.add(nextKey)) {
          queue.add(Point<int>(nextRow, nextColumn));
        }
      }
    }

    return result;
  }

  static Point<int> _pickAnchor(List<Point<int>> members) {
    double averageRow = 0;
    double averageColumn = 0;

    for (final member in members) {
      averageRow += member.x;
      averageColumn += member.y;
    }

    averageRow /= members.length;
    averageColumn /= members.length;

    members.sort((a, b) {
      final distanceA = (a.x - averageRow).abs() + (a.y - averageColumn).abs();
      final distanceB = (b.x - averageRow).abs() + (b.y - averageColumn).abs();
      final compare = distanceA.compareTo(distanceB);
      if (compare != 0) return compare;
      if (a.x != b.x) return a.x.compareTo(b.x);
      return a.y.compareTo(b.y);
    });

    return members.first;
  }

  static bool _isInsideBoard(int row, int column) {
    return row >= 0 && row < boardRows && column >= 0 && column < boardColumns;
  }
}
