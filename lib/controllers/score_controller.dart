import 'dart:async';
import 'dart:math';

import '../constant.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoreController extends GetxController {
  var score = 0.obs;
  var highscore = 0.obs;
  var isSyncing = false.obs;
  var hasNewHighScoreThisGame = false.obs;

  var placementScore = 0.obs;
  var cascadeScore = 0.obs;

  var combo = 0.obs;
  var lastIncrement = 0.obs;
  var showIncrement = false.obs;

  /// Completer that resolves when the current login sync is done.
  /// External code (e.g. RankingScreen) can await this.
  Completer<void>? _loginSyncCompleter;

  /// Current logged-in user ID (null = guest)
  String? get _currentUserId => Get.find<AuthService>().user.value?.id;

  @override
  void onInit() {
    super.onInit();

    _loadHighScore();

    // Watch auth state changes
    final authService = Get.find<AuthService>();
    ever(authService.user, (user) {
      if (user != null) {
        // Create a new completer so callers can await this sync round
        _loginSyncCompleter = Completer<void>();
        _onUserLogin(user.id);
      } else {
        _onUserLogout();
      }
    });
  }

  /// Waits for any in-progress login sync to complete.
  /// Returns immediately if no sync is running.
  Future<void> waitForLoginSync() async {
    final completer = _loginSyncCompleter;
    if (completer != null && !completer.isCompleted) {
      await completer.future;
    }
  }

  // --- Score Key Management ---

  /// Returns the SharedPreferences key for the current user's high score
  String get _scoreKey {
    final userId = _currentUserId;
    if (userId != null) {
      return 'high_score_$userId';
    }
    return 'high_score_guest';
  }

  // --- Auth State Handlers ---

  Future<void> _onUserLogin(String userId) async {
    isSyncing.value = true;
    hasNewHighScoreThisGame.value = false;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load this user's existing local score (from previous sessions)
      final userLocalScore = prefs.getInt('high_score_$userId') ?? 0;

      // --- Legacy Migration (v1.0 'high_score' → user-specific key) ---
      final legacyScore = prefs.getInt('high_score') ?? 0;

      // Always check if there is a guest score to merge
      final guestScore = prefs.getInt('high_score_guest') ?? 0;

      int bestLocalScore = max(userLocalScore, legacyScore);

      if (guestScore > 0) {
        bestLocalScore = max(bestLocalScore, guestScore);
        debugPrint(
            '🔵 [ScoreController] Merging guest score ($guestScore) with user score ($userLocalScore) / legacy ($legacyScore) → $bestLocalScore');

        // Clear guest score after merging
        await prefs.setInt('high_score_guest', 0);
      }

      // Clear legacy key after migration to avoid re-processing
      if (legacyScore > 0) {
        await prefs.remove('high_score');
        debugPrint(
            '🔵 [ScoreController] Legacy score ($legacyScore) migrated and cleared.');
      }

      // Save user-specific local score
      highscore.value = bestLocalScore;
      await prefs.setInt('high_score_$userId', bestLocalScore);

      // Sync with server
      await _syncWithOnlineScore(bestLocalScore);
    } catch (e) {
      debugPrint('🔴 [ScoreController] _onUserLogin failed: $e');
    } finally {
      isSyncing.value = false;
      // Signal that login sync is complete
      if (_loginSyncCompleter != null && !_loginSyncCompleter!.isCompleted) {
        _loginSyncCompleter!.complete();
      }
    }
  }

  /// Called when a user logs out.
  /// Switches back to guest score storage (starts fresh).
  Future<void> _onUserLogout() async {
    isSyncing.value = true;
    hasNewHighScoreThisGame.value = false;

    final prefs = await SharedPreferences.getInstance();
    final guestScore = prefs.getInt('high_score_guest') ?? 0;
    highscore.value = guestScore;

    debugPrint(
        '🔵 [ScoreController] Switched to guest mode. Guest score: $guestScore');
    isSyncing.value = false;
  }

  // --- Server Sync ---

  /// Syncs local score with the server.
  /// Takes the higher of local vs server and updates both sides.
  Future<void> _syncWithOnlineScore(int localScore) async {
    try {
      debugPrint('🔵 [ScoreController] Starting score sync...');

      final dbService = Get.find<DatabaseService>();

      int? onlineBest;
      try {
        onlineBest = await dbService.getMyBestScore(gameId);
      } catch (e) {
        debugPrint(
            '🟡 [ScoreController] Could not fetch online best score (might be empty/error). Proceeding to upload local anyway: $e');
      }

      if (onlineBest != null && onlineBest > localScore) {
        // Server score is higher → update local
        highscore.value = onlineBest;
        await _saveHighScore(onlineBest);
        debugPrint(
            '🟢 [ScoreController] Synced: server ($onlineBest) > local ($localScore). Updated local.');
      } else if (localScore > (onlineBest ?? 0)) {
        // Local score is higher → upload to server
        final bestScore = await dbService.saveScore(gameId, localScore);
        highscore.value = bestScore;
        await _saveHighScore(bestScore);
        debugPrint(
            '🟢 [ScoreController] Synced: local ($localScore) > server (${onlineBest ?? 0}). Uploaded best=$bestScore.');
      } else {
        debugPrint('🟢 [ScoreController] Scores already in sync ($localScore)');
      }
    } catch (e) {
      debugPrint('🔴 [ScoreController] Online score sync overall failed: $e');
    }
  }

  // --- Scoring Logic ---

  void registerPuzzleMatch({
    required int points,
    required int comboDepth,
  }) {
    placementScore.value += points;
    cascadeScore.value = 0;
    score.value += points;
    combo.value = comboDepth;

    lastIncrement.value = points;
    showIncrement.value = points > 0;

    if (points > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        showIncrement.value = false;
      });
    }

    checkHighScore();
  }

  void resetScore() {
    score.value = 0;
    placementScore.value = 0;
    cascadeScore.value = 0;
    combo.value = 0;
    lastIncrement.value = 0;
    showIncrement.value = false;
    hasNewHighScoreThisGame.value = false;
  }

  void checkHighScore() async {
    if (score.value > highscore.value) {
      highscore.value = score.value;
      hasNewHighScoreThisGame.value = true;
      await _saveHighScore(highscore.value);
    }
  }

  /// Uploads the current high score to Supabase.
  /// Called at game over and when opening the ranking tab.
  Future<void> uploadHighScoreToServer() async {
    if (_currentUserId == null) return; // Guest — skip
    try {
      final dbService = Get.find<DatabaseService>();
      final bestScore = await dbService.saveScore(gameId, highscore.value);
      highscore.value = bestScore;
      await _saveHighScore(bestScore);
      debugPrint(
          '🟢 [ScoreController] High score uploaded: ${highscore.value}');
    } catch (e) {
      debugPrint('🔴 [ScoreController] High score upload failed: $e');
    }
  }

  /// Syncs local high score with server when opening ranking tab.
  /// Takes the higher of local vs server and updates both sides.
  Future<void> syncScoreForRanking() async {
    if (_currentUserId == null) return;
    await _syncWithOnlineScore(highscore.value);
  }

  // --- Persistence ---

  Future<void> _saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scoreKey, score);
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    int storedScore = prefs.getInt(_scoreKey) ?? 0;

    // --- Legacy Migration (v1.0 'high_score' -> v2.0 'high_score_guest') ---
    // If we are in guest mode, check if there's an old version score that is higher
    if (_currentUserId == null) {
      final legacyScore = prefs.getInt('high_score') ?? 0;
      if (legacyScore > storedScore) {
        debugPrint(
            '🔵 [ScoreController] Legacy score ($legacyScore) > guest score ($storedScore). Migrating...');
        storedScore = legacyScore;
        await prefs.setInt('high_score_guest', storedScore);
      }
      // Clear legacy key after migration
      if (legacyScore > 0) {
        await prefs.remove('high_score');
      }
    }

    highscore.value = storedScore;
    hasNewHighScoreThisGame.value = false;
  }
}
