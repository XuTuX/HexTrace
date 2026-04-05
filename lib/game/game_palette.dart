import 'package:flutter/material.dart';

import 'hex_game_controller.dart';

class GamePalette {
  static const Color canvas = Color(0xFF0D1B24);
  static const Color panel = Color(0xFF132734);
  static const Color panelAlt = Color(0xFF1A3444);
  static const Color line = Color(0x3328404C);
  static const Color ink = Color(0xFFF3F2E9);
  static const Color success = Color(0xFF7AF0B5);
  static const Color warning = Color(0xFFFFCE6A);
  static const Color danger = Color(0xFFFF7F7A);
  static const Color drag = Color(0xFFF7F6EF);

  static Color colorFor(GameColor color) {
    return switch (color) {
      GameColor.coral => const Color(0xFFFF5A5F),
      GameColor.amber => const Color(0xFFFFB703),
      GameColor.mint => const Color(0xFF00C853),
      GameColor.azure => const Color(0xFF00B8F0),
      GameColor.violet => const Color(0xFF7B61FF),
    };
  }

  static Color toneColor(GameMessageTone tone) {
    return switch (tone) {
      GameMessageTone.info => ink,
      GameMessageTone.success => success,
      GameMessageTone.warning => warning,
      GameMessageTone.error => danger,
    };
  }
}
