import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:linkagon/controllers/score_controller.dart';
import 'package:linkagon/services/auth_service.dart';

import 'home_screen_flows.dart';
import 'widgets/home_screen_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Worker _profileLoadedWorker;
  late final Worker _userWorker;
  late final Worker _loadingWorker;
  bool _isNicknameDialogActive = false;

  @override
  void initState() {
    super.initState();

    final authService = Get.find<AuthService>();
    _profileLoadedWorker =
        ever(authService.isProfileLoaded, (_) => _checkNicknameRequirement());
    _userWorker = ever(authService.user, (_) => _checkNicknameRequirement());
    _loadingWorker =
        ever(authService.isLoading, (_) => _checkNicknameRequirement());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNicknameRequirement();
    });
  }

  @override
  void dispose() {
    _profileLoadedWorker.dispose();
    _userWorker.dispose();
    _loadingWorker.dispose();
    super.dispose();
  }

  Future<void> _checkNicknameRequirement() async {
    final authService = Get.find<AuthService>();
    final needsNickname = !authService.isLoading.value &&
        authService.user.value != null &&
        authService.isProfileLoaded.value &&
        !authService.hasProfileLoadError.value &&
        authService.userNickname.value == null;

    if (!needsNickname) {
      return;
    }
    if (_isNicknameDialogActive || Get.isDialogOpen == true) {
      return;
    }

    debugPrint('Force showing nickname dialog due to missing nickname');
    _isNicknameDialogActive = true;
    try {
      await showInitialNicknameDialog(authService);
    } finally {
      _isNicknameDialogActive = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreController = Get.put(ScoreController());
    final authService = Get.find<AuthService>();

    return HomeScreenContent(
      scoreController: scoreController,
      authService: authService,
      onSettingsTap: () => showSettingsScreen(authService),
      onStartGame: openGameScreen,
      onRankingTap: () => handleRankingPress(authService),
    );
  }
}
