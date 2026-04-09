import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linkagon/constant.dart';
import 'package:linkagon/services/auth_service.dart';
import 'package:linkagon/services/database_service.dart';

part 'score/score_auth.dart';
part 'score/score_gameplay.dart';
part 'score/score_persistence.dart';
part 'score/score_sync.dart';

class ScoreController extends GetxController {
  final score = 0.obs;
  final highscore = 0.obs;
  final isSyncing = false.obs;
  final hasNewHighScoreThisGame = false.obs;

  final placementScore = 0.obs;
  final cascadeScore = 0.obs;

  final combo = 0.obs;
  final lastIncrement = 0.obs;
  final showIncrement = false.obs;

  Completer<void>? _loginSyncCompleter;
  Worker? _authWorker;

  String? get _currentUserId => Get.find<AuthService>().user.value?.id;
  String get _scoreKey => _scoreStorageKeyFor(this);

  @override
  void onInit() {
    super.onInit();
    _loadHighScore(this);
    _bindScoreAuthState(this);
  }

  @override
  void onClose() {
    _authWorker?.dispose();
    super.onClose();
  }

  Future<void> waitForLoginSync() async {
    final completer = _loginSyncCompleter;
    if (completer != null && !completer.isCompleted) {
      await completer.future;
    }
  }

  void registerPuzzleMatch({
    required int points,
    required int comboDepth,
  }) {
    _registerPuzzleMatch(
      this,
      points: points,
      comboDepth: comboDepth,
    );
  }

  void resetScore() {
    _resetScoreState(this);
  }

  void checkHighScore() {
    _checkHighScore(this);
  }

  Future<void> uploadHighScoreToServer() {
    return _uploadHighScoreToServer(this);
  }

  Future<void> syncScoreForRanking() {
    return _syncScoreForRanking(this);
  }
}
