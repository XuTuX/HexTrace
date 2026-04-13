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
      GameColor.coral => const Color(0xFFFF4D4D), // Bold Red
      GameColor.amber => const Color(0xFFFFB300), // Vibrant Orange
      GameColor.mint => const Color(0xFF00D47C), // Bright Green
      GameColor.azure => const Color(0xFF0095FF), // Clear Blue
      GameColor.violet => const Color(0xFF8F00FF), // Strong Purple
      GameColor.rainbow => const Color(0xFFFFFFFF), // White placeholder for rainbow
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
