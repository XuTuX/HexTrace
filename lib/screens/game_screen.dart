import 'package:flutter/material.dart';

import '../src/ui/hex_puzzle_page.dart';

class GameScreen extends StatelessWidget {
  final bool shouldRestore;

  const GameScreen({super.key, this.shouldRestore = false});

  @override
  Widget build(BuildContext context) {
    return const HexPuzzlePage();
  }
}
