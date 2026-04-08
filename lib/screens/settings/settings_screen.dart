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
                constraints: const BoxConstraints(maxWidth: 600),
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
                              _ProfileSection(
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
                            _GeneralSection(
                              settingsService: settingsService,
                              onShowTutorial: () =>
                                  _showTutorialDialog(context),
                              onContact: _launchInstagram,
                            ),
                            const SizedBox(height: 24),
                            _AccountSection(
                              authService: authService,
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.email,
    required this.nickname,
    required this.onEditNickname,
  });

  final String email;
  final String nickname;
  final VoidCallback onEditNickname;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel('프로필'),
        SettingsCard(
          child: Column(
            children: [
              SettingsInfoRow(
                icon: Icons.email_outlined,
                title: '이메일',
                value: email,
              ),
              const SettingsDivider(),
              SettingsTapRow(
                icon: Icons.badge_outlined,
                title: '닉네임',
                value: nickname,
                showEditIcon: true,
                onTap: onEditNickname,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GeneralSection extends StatelessWidget {
  const _GeneralSection({
    required this.settingsService,
    required this.onShowTutorial,
    required this.onContact,
  });

  final SettingsService settingsService;
  final VoidCallback onShowTutorial;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel('일반'),
        SettingsCard(
          child: Column(
            children: [
              Obx(() {
                return SettingsSwitchRow(
                  icon: Icons.vibration_rounded,
                  title: '진동 피드백',
                  value: settingsService.isHapticsOn.value,
                  onChanged: (_) => settingsService.toggleHaptics(),
                );
              }),
              const SettingsDivider(),
              SettingsTapRow(
                icon: Icons.help_outline_rounded,
                title: '게임 방법',
                onTap: onShowTutorial,
              ),
              const SettingsDivider(),
              SettingsTapRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: '문의하기',
                onTap: onContact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.authService,
    required this.isLoggedIn,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onLogin,
  });

  final AuthService authService;
  final bool isLoggedIn;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel('계정'),
        if (isLoggedIn)
          SettingsCard(
            child: Column(
              children: [
                SettingsTapRow(
                  icon: Icons.logout_rounded,
                  title: '로그아웃',
                  onTap: onLogout,
                ),
                const SettingsDivider(),
                SettingsTapRow(
                  icon: Icons.delete_outline_rounded,
                  title: '계정 삭제',
                  onTap: onDeleteAccount,
                ),
              ],
            ),
          )
        else
          SettingsCard(
            child: SettingsTapRow(
              icon: Icons.login_rounded,
              title: '로그인',
              onTap: onLogin,
            ),
          ),
      ],
    );
  }
}
