import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_models.dart';
import 'package:hexor/services/database_service.dart';

import 'ranking_data_loader.dart';
import 'ranking_period.dart';
import 'widgets/my_rank_card.dart';
import 'widgets/ranking_chrome.dart';
import 'widgets/rank_list_item.dart';
import 'widgets/ranking_states.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({
    super.key,
    this.isDailyOnly = false,
  });

  final bool isDailyOnly;

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  bool _isLoading = true;
  String? _error;
  int? _myRank;
  int? _myScore;
  List<Map<String, dynamic>> _scores = [];
  WeeklySeasonSummary? _weeklySeasonSummary;
  late RankingPeriod _period;
  late final Worker _authWorker;

  @override
  void initState() {
    super.initState();
    _period = widget.isDailyOnly ? RankingPeriod.daily : RankingPeriod.weekly;
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
      final dbService = Get.find<DatabaseService>();
      final snapshot = await loadRankingSnapshot(
        scoreController: scoreController,
        authService: authService,
        dbService: dbService,
        period: _period,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _myRank = snapshot.myRank;
        _myScore = snapshot.myScore;
        _scores = snapshot.scores;
        _weeklySeasonSummary = snapshot.weeklySeasonSummary;
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

  void _handlePeriodChanged(RankingPeriod period) {
    if (_period == period) {
      return;
    }

    setState(() {
      _period = period;
    });
    _loadRankingData();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final myId = authService.user.value?.id;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: Border.all(
            color: charcoalBlack.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const RankingSheetHandle(),
              const SizedBox(height: 12),
              RankingHeader(
                period: _period,
                onPeriodChanged: _handlePeriodChanged,
                isDailyOnly: widget.isDailyOnly,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).shortestSide >= 600 ? 680 : 480,
                    ),
                    child: _buildContent(myId),
                  ),
                ),
              ),
            ],
          ),
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
      return EmptyRankingState(period: _period);
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: MyRankCard(
            rank: _myRank,
            score: _myScore,
            isLoggedIn: myId != null,
            period: _period,
            weeklySeasonSummary: _weeklySeasonSummary,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: TopPlayersLabel(period: _period),
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
