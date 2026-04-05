import 'package:flutter/material.dart';

import 'models/rune_type.dart';

const int boardRows = 9;
const int boardColumns = 9;
const int mergeThreshold = 5;
const int maxRuneLevel = 4;
const double handSlotSize = 90.0;

const List<List<Offset>> runePieceTemplates = [
  [
    Offset(1, 1),
  ],
  [
    Offset(1, 1),
    Offset(2, 1),
  ],
  [
    Offset(0, 1),
    Offset(1, 1),
    Offset(2, 1),
  ],
  [
    Offset(1, 0),
    Offset(1, 1),
    Offset(2, 1),
  ],
  [
    Offset(1, 0),
    Offset(1, 1),
    Offset(1, 2),
  ],
  [
    Offset(1, 0),
    Offset(1, 1),
    Offset(2, 1),
    Offset(2, 2),
  ],
  [
    Offset(1, 0),
    Offset(2, 0),
    Offset(1, 1),
    Offset(2, 1),
  ],
  [
    Offset(0, 1),
    Offset(1, 1),
    Offset(2, 1),
    Offset(1, 2),
  ],
  [
    Offset(1, 0),
    Offset(0, 1),
    Offset(1, 1),
    Offset(2, 1),
  ],
  [
    Offset(1, 0),
    Offset(1, 1),
    Offset(0, 2),
    Offset(1, 2),
  ],
];

Color runeColor(RuneType type) {
  switch (type) {
    case RuneType.ember:
      return const Color(0xFFF97316);
    case RuneType.tide:
      return const Color(0xFF3B82F6);
    case RuneType.grove:
      return const Color(0xFF22C55E);
    case RuneType.storm:
      return const Color(0xFFEAB308);
    case RuneType.voidRune:
      return const Color(0xFF8B5CF6);
  }
}

Color runeColorForLevel(RuneType type, int level) {
  final base = runeColor(type);
  final brighten = (maxRuneLevel - level).clamp(0, maxRuneLevel) / 6;
  return Color.lerp(base, Colors.white, brighten) ?? base;
}

Color hoverColorForRune(RuneType type) {
  return runeColor(type).withValues(alpha: 0.35);
}
