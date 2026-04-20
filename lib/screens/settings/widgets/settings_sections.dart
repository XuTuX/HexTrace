import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hexor/services/settings_service.dart';

import 'settings_rows.dart';
import 'settings_surface.dart';

class SettingsProfileSection extends StatelessWidget {
  const SettingsProfileSection({
    super.key,
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

class SettingsGeneralSection extends StatelessWidget {
  const SettingsGeneralSection({
    super.key,
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
                  icon: Icons.music_note_rounded,
                  title: '배경음악',
                  value: settingsService.isBgmOn.value,
                  onChanged: (_) => settingsService.toggleBgm(),
                );
              }),
              const SettingsDivider(),
              Obx(() {
                return SettingsSwitchRow(
                  icon: Icons.graphic_eq_rounded,
                  title: '효과음',
                  value: settingsService.isSfxOn.value,
                  onChanged: (_) => settingsService.toggleSfx(),
                );
              }),
              const SettingsDivider(),
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

class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({
    super.key,
    required this.isLoggedIn,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onLogin,
  });

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
