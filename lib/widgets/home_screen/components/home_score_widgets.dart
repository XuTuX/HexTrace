import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/widgets/home_screen/nickname_sticker_card.dart';

class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({
    super.key,
    required this.scoreController,
    required this.authService,
  });

  final ScoreController scoreController;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading =
          authService.isLoading.value || scoreController.isSyncing.value;

      return NicknameStickerCard(
        nickname: authService.userNickname.value,
        score: scoreController.highscore.value,
        isLoading: isLoading,
      );
    });
  }
}

class HighScoreCard extends StatelessWidget {
  const HighScoreCard({
    super.key,
    required this.scoreController,
    required this.authService,
  });

  final ScoreController scoreController;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return ScoreDisplay(
      scoreController: scoreController,
      authService: authService,
    );
  }
}

class InfoCardsRow extends StatelessWidget {
  const InfoCardsRow({
    super.key,
    required this.scoreController,
    required this.authService,
  });

  final ScoreController scoreController;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return ScoreDisplay(
      scoreController: scoreController,
      authService: authService,
    );
  }
}

class ColorBarPreview extends StatelessWidget {
  const ColorBarPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
