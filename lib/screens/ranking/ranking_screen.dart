import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_service.dart';
import 'package:hexor/theme/app_typography.dart';

import 'widgets/my_rank_card.dart';
import 'widgets/rank_list_item.dart';
import 'widgets/ranking_states.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  bool _isLoading = true;
  String? _error;
  int? _myRank;
  int? _myScore;
  List<Map<String, dynamic>> _scores = [];
  late final Worker _authWorker;

  @override
  void initState() {
    super.initState();
    _loadRankingData();

    final authService = Get.find<AuthService>();
    _authWorker = ever(authService.user, (_) {
      if (mounted) {
        _loadRankingData();
      }
    });
  }

  @override
  void dispose() {
    _authWorker.dispose();
    super.dispose();
  }

  Future<void> _loadRankingData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final scoreController = Get.find<ScoreController>();
      final authService = Get.find<AuthService>();
      final isLoggedIn = authService.user.value != null;

      if (isLoggedIn) {
        await scoreController.waitForLoginSync();
        if (!mounted) {
          return;
        }
        await scoreController.syncScoreForRanking();
      }

      if (!mounted) {
        return;
      }

      final dbService = Get.find<DatabaseService>();
      final results = await Future.wait([
        isLoggedIn
            ? dbService.getMyRank(gameId).catchError((e) {
                debugPrint('🔴 [RankingScreen] getMyRank error: $e');
                return null;
              })
            : Future<int?>.value(null),
        isLoggedIn
            ? dbService.getMyBestScore(gameId).catchError((e) {
                debugPrint('🔴 [RankingScreen] getMyBestScore error: $e');
                return null;
              })
            : Future<int?>.value(null),
        dbService.getLeaderboard(gameId).catchError((e) {
          debugPrint('🔴 [RankingScreen] getLeaderboard error: $e');
          return <Map<String, dynamic>>[];
        }),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _myRank = results[0] as int?;
        _myScore = results[1] as int?;
        _scores = List<Map<String, dynamic>>.from(results[2] as List? ?? []);
        _isLoading = false;
      });

      debugPrint(
        '🟢 [RankingScreen] Data loaded — rank: $_myRank, score: $_myScore, leaderboard: ${_scores.length} entries',
      );
    } catch (e) {
      debugPrint('🔴 [RankingScreen] _loadRankingData failed: $e');
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final myId = authService.user.value?.id;

    return Container(
      constraints: BoxConstraints(maxHeight: Get.height * 0.9),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const _RankingSheetHandle(),
            const SizedBox(height: 20),
            _RankingHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildContent(myId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String? myId) {
    if (_isLoading) {
      return const RankingLoadingState();
    }

    if (_error != null) {
      return RankingErrorState(onRetry: _loadRankingData);
    }

    if (_scores.isEmpty) {
      return const EmptyRankingState();
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: MyRankCard(
            rank: _myRank,
            score: _myScore,
            isLoggedIn: myId != null,
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: _TopPlayersLabel(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            itemCount: _scores.length,
            itemBuilder: (context, index) {
              return RankListItem(
                scoreData: _scores[index],
                index: index,
                myId: myId,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RankingSheetHandle extends StatelessWidget {
  const _RankingSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _RankingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.emoji_events_outlined,
          color: charcoalBlack,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'RANKING',
          style: AppTypography.title.copyWith(
            fontSize: 20,
            letterSpacing: 4.0,
            color: charcoalBlack,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TopPlayersLabel extends StatelessWidget {
  const _TopPlayersLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'TOP PLAYERS',
          style: AppTypography.label.copyWith(
            fontSize: 11,
            letterSpacing: 2.0,
            color: charcoalBlack.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 0.5,
            color: charcoalBlack.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}
