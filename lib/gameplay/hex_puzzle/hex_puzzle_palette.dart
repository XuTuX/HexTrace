import 'package:flutter/material.dart';

import 'hex_puzzle_logic.dart';

extension HexTileColorPalette on HexTileColor {
  String get label {
    switch (this) {
      case HexTileColor.coral:
        return 'Coral';
      case HexTileColor.amber:
        return 'Amber';
      case HexTileColor.lime:
        return 'Lime';
      case HexTileColor.teal:
        return 'Teal';
      case HexTileColor.blue:
        return 'Blue';
      case HexTileColor.violet:
        return 'Violet';
    }
  }

  Color get fillColor {
    switch (this) {
      case HexTileColor.coral:
        return const Color(0xFFFF6B6B);
      case HexTileColor.amber:
        return const Color(0xFFFFB84D);
      case HexTileColor.lime:
        return const Color(0xFFB8D96C);
      case HexTileColor.teal:
        return const Color(0xFF49C6B6);
      case HexTileColor.blue:
        return const Color(0xFF5B86FF);
      case HexTileColor.violet:
        return const Color(0xFFAE7CFF);
    }
  }

  Color get accentColor {
    switch (this) {
      case HexTileColor.coral:
        return const Color(0xFFC94C4C);
      case HexTileColor.amber:
        return const Color(0xFFCB8A2E);
      case HexTileColor.lime:
        return const Color(0xFF86A746);
      case HexTileColor.teal:
        return const Color(0xFF2E9E90);
      case HexTileColor.blue:
        return const Color(0xFF3559BF);
      case HexTileColor.violet:
        return const Color(0xFF7751CC);
    }
  }
}
