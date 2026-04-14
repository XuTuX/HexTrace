import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_service.dart';
import 'package:hexor/services/settings_service.dart';
import 'package:hexor/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:hexor/widgets/dialogs/tutorial_dialog.dart';
import 'package:hexor/widgets/home_screen/background_painter.dart';
import 'package:hexor/widgets/home_screen/login_sheet.dart';

import 'dialogs/delete_account_dialog.dart';
import 'widgets/settings_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.authService,
    required this.dbService,
  });

  final AuthService authService;
  final DatabaseService dbService;

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: GridPatternPainter()),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).shortestSide >= 600 ? 680 : 600,
                ),
                child: Column(
                  children: [
                    const SettingsHeader(),
                    Expanded(
                      child: Obx(() {
                        final user = authService.user.value;
                        final savedNickname = authService.userNickname.value;
                        final nickname = savedNickname ?? '닉네임 설정 필요';
                        final email = user?.email ?? '';

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                          children: [
                            if (user != null) ...[
                              SettingsProfileSection(
                                email: email,
                                nickname: nickname,
                                onEditNickname: () {
                                  _showEditNicknameDialog(
                                    context,
                                    savedNickname ?? '',
                                    (newNickname) async {
                                      return authService
                                          .updateNickname(newNickname);
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                            SettingsGeneralSection(
                              settingsService: settingsService,
                              onShowTutorial: () =>
                                  _showTutorialDialog(context),
                              onContact: _launchInstagram,
                            ),
                            const SizedBox(height: 24),
                            SettingsAccountSection(
                              isLoggedIn: user != null,
                              onLogout: () {
                                authService.signOut();
                                Get.back();
                              },
                              onDeleteAccount: () {
                                showDeleteAccountDialog(authService);
                              },
                              onLogin: () {
                                Get.bottomSheet(
                                  LoginSheet(
                                    onGoogleSignIn: () async {
                                      return authService.signInWithGoogle();
                                    },
                                    onAppleSignIn: () async {
                                      return authService.signInWithApple();
                                    },
                                    onLoginSuccess: Get.back,
                                  ),
                                  isScrollControlled: true,
                                );
                              },
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Obx(() {
            return authService.isLoading.value
                ? Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                : const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  void _showTutorialDialog(BuildContext context) {
    Get.dialog(
      const TutorialDialog(),
      barrierColor: Colors.black.withValues(alpha: 0.8),
    );
  }

  void _showEditNicknameDialog(
    BuildContext context,
    String currentNickname,
    Future<String?> Function(String) onSave,
  ) {
    Get.dialog(
      EditNicknameDialog(
        currentNickname: currentNickname,
        onSave: onSave,
      ),
    );
  }

  Future<void> _launchInstagram() async {
    final url = Uri.parse(
      'https://www.instagram.com/neoreo_games?igsh=d3R6bnN3M3Y4ZzFu&utm_source=qr',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}
