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

    if (authService.user.value != null &&
        authService.isProfileLoaded.value &&
        !authService.hasProfileLoadError.value &&
        authService.userNickname.value == null) {
      if (_isNicknameDialogActive) return;
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // 1. Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: GridPatternPainter(),
            ),
          ),

          // 2. Main Scrollable Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ─── Top padding ───
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 16),
                    ),

                    // ─── SECTION 1: Logo + Hex Cluster ───
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // Logo with decorative hexagons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const HomeLogo(width: 200),
                                const SizedBox(width: 4),
                                const HexCluster(size: 30),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // ─── SECTION 2: Info Cards (Score + Timer) ───
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: InfoCardsRow(
                          scoreController: scoreController,
                          authService: authService,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // ─── SECTION 3: Color Bar Preview ───
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const ColorBarPreview(),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ─── SECTION 4: Action Buttons ───
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            // Start Game — larger
                            Expanded(
                              flex: 3,
                              child: PrimaryButton(
                                label: '게임 시작',
                                icon: Icons.play_arrow_rounded,
                                onPressed: () {
                                  Get.to(() => const GameScreen());
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Ranking — smaller
                            Expanded(
                              flex: 2,
                              child: RankingButton(
                                onPressed: () =>
                                    _handleRankingPress(authService),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ─── SECTION 5: Weekly Ranking Preview ───
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: WeeklyRankingPreview(
                          onViewAll: () => _handleRankingPress(authService),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // ─── SECTION 6: Settings + Gameplay Tip ───
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SettingsButton(
                              onPressed: () {
                                if (authService.user.value != null) {
                                  _showSettingsSheet(authService);
                                } else {
                                  _showLoginSheet(authService);
                                }
                              },
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: GameplayTip()),
                          ],
                        ),
                      ),
                    ),

                    // ─── Bottom safe padding ───
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
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
