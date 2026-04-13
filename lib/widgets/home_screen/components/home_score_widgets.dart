import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_models.dart';
import 'package:hexor/services/database_service.dart';
import 'package:hexor/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:hexor/widgets/home_screen/nickname_sticker_card.dart';

class ScoreDisplay extends StatefulWidget {
  const ScoreDisplay({
    super.key,
    required this.scoreController,
    required this.authService,
  });

  final ScoreController scoreController;
  final AuthService authService;

  @override
  State<ScoreDisplay> createState() => _ScoreDisplayState();
}

class _ScoreDisplayState extends State<ScoreDisplay> {
  WeeklySeasonSummary? _seasonSummary;
  late final Worker _authWorker;

  @override
  void initState() {
    super.initState();
    _loadTier();
    _authWorker = ever(widget.authService.user, (_) => _loadTier());
  }

  @override
  void dispose() {
    _authWorker.dispose();
    super.dispose();
  }

  Future<void> _loadTier() async {
    if (widget.authService.user.value == null) {
      if (mounted) setState(() => _seasonSummary = null);
      return;
    }
    try {
      final dbService = Get.find<DatabaseService>();
      final summary = await dbService.getWeeklySeasonSummary(gameId);
      if (mounted) setState(() => _seasonSummary = summary);
    } catch (_) {
      // Tier loading is non-critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading =
          widget.authService.isLoading.value ||
          widget.scoreController.isSyncing.value;

      return NicknameStickerCard(
        nickname: widget.authService.userNickname.value,
        score: widget.scoreController.highscore.value,
        isLoading: isLoading,
        tierLabel: _seasonSummary?.tier.label,
        tierColor: _tierColor(_seasonSummary?.tier),
        tierRank: _seasonSummary?.rank,
        onTapNickname: () {
          Get.dialog(
            EditNicknameDialog(
              currentNickname:
                  widget.authService.userNickname.value ?? '',
              onSave: (newNickname) async {
                return await widget.authService.updateNickname(newNickname);
              },
            ),
            barrierDismissible: false,
          );
        },
      );
    });
  }

  Color? _tierColor(SeasonTier? tier) {
    return switch (tier) {
      SeasonTier.diamond => const Color(0xFF38BDF8),
      SeasonTier.platinum => const Color(0xFF64748B),
      SeasonTier.gold => const Color(0xFFF59E0B),
      SeasonTier.silver => const Color(0xFF94A3B8),
      SeasonTier.bronze => const Color(0xFFB45309),
      null => null,
    };
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
