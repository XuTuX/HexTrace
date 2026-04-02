import 'package:flutter/material.dart';

import 'src/game/game_palette.dart';
import 'src/ui/hex_puzzle_page.dart';

void runHexorApp() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: GamePalette.success,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hexor',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: GamePalette.canvas,
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: GamePalette.ink,
          displayColor: GamePalette.ink,
        ),
      ),
      home: const HexPuzzlePage(),
    );
  }
}
