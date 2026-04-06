import 'package:hexor/constant.dart';
import 'package:hexor/screens/home_screen.dart';
import 'package:hexor/theme/app_typography.dart';
import 'package:hexor/widgets/home_screen/background_painter.dart';
import 'package:hexor/widgets/home_screen/login_sheet.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_service.dart';
import 'package:hexor/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:hexor/services/settings_service.dart';
import 'package:hexor/widgets/dialogs/tutorial_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  final AuthService authService;
  final DatabaseService dbService;

  const SettingsScreen({
    super.key,
    required this.authService,
    required this.dbService,
  });

  @override
  Widget build(BuildContext context) {
    final SettingsService settingsService = Get.find<SettingsService>();

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
                    // ── Header ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: charcoalBlack, width: 2.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: charcoalBlack,
                                    offset: Offset(2, 2),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  color: charcoalBlack, size: 24),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'SETTINGS',
                              textAlign: TextAlign.center,
                              style: AppTypography.title.copyWith(
                                fontSize: 22,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                          const SizedBox(
                              width:
                                  48), // Match back button width for centering
                        ],
                      ),
                    ),

                    // ── Body ──
                    Expanded(
                      child: Obx(() {
                        final user = authService.user.value;
                        final savedNickname = authService.userNickname.value;
                        final nickname = savedNickname ?? '닉네임 설정 필요';
                        final email = user?.email ?? '';

                        return ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                          children: [
                            // ── Profile card (logged in only) ──
                            if (user != null) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionLabel('프로필'),
                                  _card(
                                    child: Column(
                                      children: [
                                        _infoRow(
                                          icon: Icons.email_outlined,
                                          title: '이메일',
                                          value: email,
                                        ),
                                        _divider(),
                                        _tapRow(
                                          icon: Icons.badge_outlined,
                                          title: '닉네임',
                                          value: nickname,
                                          showEditIcon: true,
                                          onTap: () => _showEditNicknameDialog(
                                            context,
                                            savedNickname ?? '',
                                            (newNickname) async {
                                              return await authService
                                                  .updateNickname(newNickname);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],

                            // ── General section ──
                            _sectionLabel('일반'),
                            _card(
                              child: Column(
                                children: [
                                  Obx(() => _switchRow(
                                        icon: Icons.vibration_rounded,
                                        title: '진동 피드백',
                                        value:
                                            settingsService.isHapticsOn.value,
                                        onChanged: (_) =>
                                            settingsService.toggleHaptics(),
                                      )),
                                  _divider(),
                                  _tapRow(
                                    icon: Icons.help_outline_rounded,
                                    title: '게임 방법',
                                    onTap: () => _showTutorialDialog(context),
                                  ),
                                  _divider(),
                                  _tapRow(
                                    icon: Icons.chat_bubble_outline_rounded,
                                    title: '문의하기',
                                    onTap: _launchInstagram,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // ── Account section ──
                            _sectionLabel('계정'),
                            if (user != null)
                              _card(
                                child: Column(
                                  children: [
                                    _tapRow(
                                      icon: Icons.logout_rounded,
                                      title: '로그아웃',
                                      onTap: () {
                                        authService.signOut();
                                        Get.back(); // Close settings screen to return to home
                                      },
                                    ),
                                    _divider(),
                                    _tapRow(
                                      icon: Icons.delete_outline_rounded,
                                      title: 'Hexor Trace 데이터 삭제',
                                      onTap: () =>
                                          _showDeleteAccountDialog(authService),
                                    ),
                                  ],
                                ),
                              )
                            else
                              _card(
                                child: _tapRow(
                                  icon: Icons.login_rounded,
                                  title: '로그인',
                                  onTap: () {
                                    Get.bottomSheet(
                                      LoginSheet(
                                        onGoogleSignIn: () async {
                                          return await authService
                                              .signInWithGoogle();
                                        },
                                        onAppleSignIn: () async {
                                          return await authService
                                              .signInWithApple();
                                        },
                                        onLoginSuccess: () {
                                          Get.back(); // Close SettingsScreen on success
                                        },
                                      ),
                                      isScrollControlled: true,
                                    );
                                  },
                                ),
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

  // ═══════════════════════════════════════
  //  UI Building Blocks
  // ═══════════════════════════════════════

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: charcoalBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: child,
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 12),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 2,
      indent: 56,
      endIndent: 16,
      color: charcoalBlack.withValues(alpha: 0.08),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 24, color: charcoalBlack.withValues(alpha: 0.6)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: charcoalBlack,
              activeThumbColor: Colors.white,
              inactiveTrackColor: charcoalBlack.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Icon(icon, size: 24, color: charcoalBlack.withValues(alpha: 0.6)),
          const SizedBox(width: 16),
          Text(
            title,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: charcoalBlack.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tapRow({
    required IconData icon,
    required String title,
    String? value,
    bool showEditIcon = false,
    Color titleColor = charcoalBlack,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, size: 24, color: charcoalBlack.withValues(alpha: 0.6)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              showEditIcon ? Icons.edit_outlined : Icons.chevron_right_rounded,
              size: 20,
              color: charcoalBlack.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  //  Dialogs
  // ═══════════════════════════════════════

  void _showTutorialDialog(BuildContext context) {
    Get.dialog(
      const TutorialDialog(),
      barrierColor: charcoalBlack.withValues(alpha: 0.8),
    );
  }

  void _showDeleteAccountDialog(AuthService authService) {
    Get.dialog(
      Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: charcoalBlack, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: charcoalBlack,
                offset: Offset(5, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      color: Colors.red[400], size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Hexor Trace 데이터만 삭제할까요?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hexor Trace 게임 기록과 랭킹 데이터만 삭제되고 로그아웃됩니다.\n계정 자체는 유지되며, 같은 Supabase를 쓰는 다른 게임 데이터는 건드리지 않습니다.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.grey[500],
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            '취소',
                            style: AppTypography.button.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            Get.back();
                            final error =
                                await authService.deleteHexorData();
                            if (error != null) {
                              Get.snackbar(
                                '삭제 실패',
                                error,
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                                margin: const EdgeInsets.all(16),
                              );
                            } else {
                              Get.snackbar(
                                '삭제 완료',
                                'Hexor Trace 데이터가 삭제되었습니다.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: charcoalBlack,
                                colorText: Colors.white,
                                margin: const EdgeInsets.all(16),
                              );
                              Get.offAll(() => const HomeScreen());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            '삭제',
                            style: AppTypography.button.copyWith(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditNicknameDialog(BuildContext context, String currentNickname,
      Future<String?> Function(String) onSave) {
    Get.dialog(
      EditNicknameDialog(
        currentNickname: currentNickname,
        onSave: onSave,
      ),
    );
  }

  Future<void> _launchInstagram() async {
    final Uri url = Uri.parse(
        'https://www.instagram.com/neoreo_games?igsh=d3R6bnN3M3Y4ZzFu&utm_source=qr');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}
