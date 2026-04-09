import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:linkagon/screens/game_screen.dart';
import 'package:linkagon/screens/ranking_screen.dart';
import 'package:linkagon/screens/settings_screen.dart';
import 'package:linkagon/services/auth_service.dart';
import 'package:linkagon/services/database_service.dart';
import 'package:linkagon/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:linkagon/widgets/home_screen/login_sheet.dart';

void handleRankingPress(AuthService authService) {
  if (authService.user.value != null) {
    showRankingSheet();
  } else {
    showLoginSheet(authService, isRankingAction: true);
  }
}

void openGameScreen() {
  Get.to(() => const GameScreen());
}

void showLoginSheet(
  AuthService authService, {
  bool isRankingAction = false,
  String? initialError,
}) {
  Get.bottomSheet(
    LoginSheet(
      isRankingAction: isRankingAction,
      initialError: initialError,
      onGoogleSignIn: () async {
        return authService.signInWithGoogle();
      },
      onAppleSignIn: () async {
        return authService.signInWithApple();
      },
      onLoginSuccess: () async {
        await Future.delayed(const Duration(milliseconds: 500));
        if (isRankingAction) {
          showRankingSheet();
        }
      },
    ),
    isScrollControlled: true,
  );
}

void showSettingsScreen(AuthService authService) {
  final dbService = Get.find<DatabaseService>();
  Get.to(
    () => SettingsScreen(
      authService: authService,
      dbService: dbService,
    ),
    transition: Transition.rightToLeft,
    duration: const Duration(milliseconds: 300),
  );
}

void showRankingSheet() {
  Get.bottomSheet(
    const RankingScreen(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enterBottomSheetDuration: const Duration(milliseconds: 300),
  );
}

Future<void> showInitialNicknameDialog(AuthService authService) async {
  await Get.dialog(
    EditNicknameDialog(
      currentNickname: '',
      isInitialSetup: true,
      onSave: (newNickname) async {
        return authService.updateNickname(newNickname);
      },
    ),
    barrierDismissible: false,
  );
}
