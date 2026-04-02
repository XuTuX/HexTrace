import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../game/game_palette.dart';
import '../game/hex_board_view.dart';
import 'widgets/game_hud.dart';
import 'widgets/game_over_overlay.dart';

class HexPuzzlePage extends StatefulWidget {
  const HexPuzzlePage({super.key});

  @override
  State<HexPuzzlePage> createState() => _HexPuzzlePageState();
}

class _HexPuzzlePageState extends State<HexPuzzlePage> {
  late final HexGameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HexGameController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF183343), Color(0xFF09151D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      GameHud(controller: _controller),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: HexBoardView(controller: _controller),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _controller.restart,
                            style: FilledButton.styleFrom(
                              backgroundColor: GamePalette.success,
                              foregroundColor: GamePalette.canvas,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              '새 게임',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_controller.isGameOver)
                    Positioned.fill(
                      child: GameOverOverlay(
                        score: _controller.score,
                        onRestart: _controller.restart,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
