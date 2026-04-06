import 'package:hexor/constant.dart';
import 'package:hexor/theme/app_typography.dart';
import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/screens/game_screen.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_service.dart';
import 'package:hexor/widgets/home_screen/background_painter.dart';
import 'package:hexor/widgets/home_screen/home_components.dart';
import 'package:hexor/widgets/home_screen/login_sheet.dart';

import 'package:hexor/screens/ranking_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexor/widgets/dialogs/edit_nickname_dialog.dart';
import 'package:hexor/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Worker _profileLoadedWorker;
  late final Worker _userWorker;
  bool _isNicknameDialogActive = false;

  @override
  void initState() {
    super.initState();

    // Listen to profile loaded state to enforce nickname setup if missing
    final authService = Get.find<AuthService>();

    // Check when profile load status changes
    _profileLoadedWorker =
        ever(authService.isProfileLoaded, (_) => _checkNicknameRequirement());

    // Check when user changes (e.g. session recovery)
    _userWorker = ever(authService.user, (_) => _checkNicknameRequirement());

    // Initial check after build
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkNicknameRequirement());
  }

  @override
  void dispose() {
    _profileLoadedWorker.dispose();
    _userWorker.dispose();
    super.dispose();
  }

  Future<void> _checkNicknameRequirement() async {
    final authService = Get.find<AuthService>();

    // Only proceed if:
    // 1. User is logged in
    // 2. Profile has finished loading
    // 3. Nickname is still null
    // 4. No nickname dialog is currently active
    if (authService.user.value != null &&
        authService.isProfileLoaded.value &&
        !authService.hasProfileLoadError.value &&
        authService.userNickname.value == null) {
      if (_isNicknameDialogActive) return;
      // Also check general dialog status just in case
      if (Get.isDialogOpen == true) return;

      debugPrint('Force showing nickname dialog due to missing nickname');
      _isNicknameDialogActive = true;
      try {
        await _showEditNicknameDialog(authService);
      } finally {
        _isNicknameDialogActive = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ScoreController scoreController = Get.put(ScoreController());
    final AuthService authService = Get.find<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Soft off-white
      bottomNavigationBar: null,
      body: Stack(
        children: [
          // 1. Dynamic Background
          Positioned.fill(
            child: CustomPaint(
              painter: GridPatternPainter(),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Row: Profile
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ProfileButton(
                              authService: authService,
                              onProfileTap: () =>
                                  _showSettingsSheet(authService),
                              onLoginTap: () => _showLoginSheet(authService),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 1),

                      // Title Area
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HomeLogo(width: 260),
                            const SizedBox(height: 20),
                            Text(
                              'Real-time hex drag puzzle',
                              style: AppTypography.body.copyWith(
                                color: charcoalBlack54,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Best Score Card
                      Center(
                          child: HighScoreCard(
                        scoreController: scoreController,
                        authService: authService,
                      )),

                      const Spacer(flex: 2),

                      // Action Buttons
                      Column(
                        children: [
                          PrimaryButton(
                            label: 'PLAY',
                            onPressed: () {
                              Get.to(() => const GameScreen());
                            },
                          ),
                          const SizedBox(height: 16),
                          SecondaryButton(
                            label: 'RANKING',
                            icon: Icons.emoji_events_outlined,
                            onPressed: () => _handleRankingPress(authService),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Logic & Sheets ---

  void _handleRankingPress(AuthService authService) {
    if (authService.user.value != null) {
      _showRankingSheet();
    } else {
      _showLoginSheet(authService, isRankingAction: true);
    }
  }

  void _showLoginSheet(AuthService authService,
      {bool isRankingAction = false, String? initialError}) {
    Get.bottomSheet(
      LoginSheet(
        isRankingAction: isRankingAction,
        initialError: initialError,
        onGoogleSignIn: () async {
          return await authService.signInWithGoogle();
        },
        onAppleSignIn: () async {
          return await authService.signInWithApple();
        },
        onLoginSuccess: () async {
          // Give ScoreController._onUserLogin time to start (it's triggered
          // by a reactive ever() listener, so it runs asynchronously).
          await Future.delayed(const Duration(milliseconds: 500));

          if (isRankingAction) {
            _showRankingSheet();
          }
        },
      ),
      isScrollControlled: true,
    );
  }

  void _showSettingsSheet(AuthService authService) {
    final DatabaseService dbService = Get.find<DatabaseService>();
    Get.to(
      () => SettingsScreen(
        authService: authService,
        dbService: dbService,
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _showRankingSheet() {
    Get.bottomSheet(
      const RankingScreen(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _showEditNicknameDialog(AuthService authService) async {
    await Get.dialog(
      EditNicknameDialog(
        currentNickname: '',
        isInitialSetup: true,
        onSave: (newNickname) async {
          return await authService.updateNickname(newNickname);
        },
      ),
      barrierDismissible: false,
    );
  }
}
