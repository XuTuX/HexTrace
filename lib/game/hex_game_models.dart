import 'package:flutter/foundation.dart';

enum GameColor { coral, amber, mint, azure, violet }

extension GameColorKey on GameColor {
  String get key => switch (this) {
        GameColor.coral => 'coral',
        GameColor.amber => 'amber',
        GameColor.mint => 'mint',
        GameColor.azure => 'azure',
        GameColor.violet => 'violet',
      };
}

enum DragState { idle, building, valid, invalid }

enum GameMessageTone { info, success, warning, error }

@immutable
class ColorBarEntry {
  const ColorBarEntry({required this.id, required this.color});

  final int id;
  final GameColor color;
}

@immutable
class HexCoord {
  const HexCoord(this.col, this.row);

  final int col;
  final int row;

  @override
  bool operator ==(Object other) {
    return other is HexCoord && other.col == col && other.row == row;
  }

  @override
  int get hashCode => Object.hash(col, row);
}

@immutable
class BarWindow {
  const BarWindow(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start + 1;

  bool containsIndex(int index) => index >= start && index <= end;
}
