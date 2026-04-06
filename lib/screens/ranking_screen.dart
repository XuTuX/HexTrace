import 'package:hexor/constant.dart';
import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_service.dart';
import 'package:hexor/theme/app_typography.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

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

  /// The single, definitive data-loading method.
  /// 1. Waits for ScoreController login sync to finish (if running).
  /// 2. Uploads the current local high score to the server.
  /// 3. Fetches rank, best score, and leaderboard from server.
  Future<void> _loadRankingData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final scoreController = Get.find<ScoreController>();
      final authService = Get.find<AuthService>();
      final isLoggedIn = authService.user.value != null;

      // 로그인 사용자는 로그인 직후 점수 병합/동기화가 끝난 뒤 개인 랭킹을 조회한다.
      if (isLoggedIn) {
        await scoreController.waitForLoginSync();
        if (!mounted) return;
        await scoreController.syncScoreForRanking();
      }

      if (!mounted) return;

      // 리더보드는 게스트도 볼 수 있어야 한다.
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

      if (!mounted) return;

      setState(() {
        _myRank = results[0] as int?;
        _myScore = results[1] as int?;
        _scores = List<Map<String, dynamic>>.from(results[2] as List? ?? []);
        _isLoading = false;
      });

      debugPrint(
          '🟢 [RankingScreen] Data loaded — rank: $_myRank, score: $_myScore, leaderboard: ${_scores.length} entries');
    } catch (e) {
      debugPrint('🔴 [RankingScreen] _loadRankingData failed: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Get.find<AuthService>();
    final String? myId = authService.user.value?.id;

    return Container(
      constraints: BoxConstraints(
        maxHeight: Get.height * 0.9,
      ),
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
            Center(
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
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events_outlined,
                    color: charcoalBlack, size: 24),
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
            ),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: charcoalBlack,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'LOADING...',
              style: AppTypography.label.copyWith(
                color: charcoalBlack.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
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
          ),
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

class MyRankCard extends StatelessWidget {
  final int? rank;
  final int? score;
  final bool isLoggedIn;

  const MyRankCard({
    super.key,
    this.rank,
    this.score,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    if (rank == null || score == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: charcoalBlack.withValues(alpha: 0.05)),
        ),
        child: Center(
          child: Text(
            isLoggedIn ? 'PLAY TO RANK UP' : 'LOG IN TO JOIN THE RANKING',
            style: AppTypography.label.copyWith(
              fontSize: 11,
              color: charcoalBlack.withValues(alpha: 0.3),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: charcoalBlack.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$rank',
                style: AppTypography.title.copyWith(
                  fontSize: 32,
                  color: charcoalBlack,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              Text(
                '위',
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  color: charcoalBlack.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 24),
              Container(
                width: 1,
                height: 20,
                color: charcoalBlack.withValues(alpha: 0.08),
              ),
              const SizedBox(width: 24),
              Text(
                '$score',
                style: AppTypography.title.copyWith(
                  fontSize: 32,
                  color: charcoalBlack,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              Text(
                '점',
                style: AppTypography.body.copyWith(
                  fontSize: 14,
                  color: charcoalBlack.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RankListItem extends StatelessWidget {
  final Map<String, dynamic> scoreData;
  final int index;
  final String? myId;

  const RankListItem({
    super.key,
    required this.scoreData,
    required this.index,
    required this.myId,
  });

  @override
  Widget build(BuildContext context) {
    final profileData = scoreData['profiles'];
    Map<String, dynamic> profiles = {};
    if (profileData is Map<String, dynamic>) {
      profiles = profileData;
    } else if (profileData is List && profileData.isNotEmpty) {
      profiles = profileData[0] as Map<String, dynamic>;
    }

    final nickname = profiles['nickname'] ?? 'Player';
    final scoreVal = scoreData['score'];
    final userId = scoreData['user_id'];
    final bool isMe = userId != null && userId == myId;
    final rankValue = scoreData['rank'];
    final rank = switch (rankValue) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value) ?? (index + 1),
      _ => index + 1,
    };

    final bool isTopThree = rank <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:
            isMe ? charcoalBlack.withValues(alpha: 0.04) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          bottom: BorderSide(
            color: charcoalBlack.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // RANK (X위)
          SizedBox(
            width: 44,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$rank',
                    style: AppTypography.body.copyWith(
                      fontSize: isTopThree ? 18 : 15,
                      fontWeight: FontWeight.w900,
                      color: charcoalBlack,
                    ),
                  ),
                  TextSpan(
                    text: '위',
                    style: AppTypography.body.copyWith(
                      fontSize: isTopThree ? 11 : 10,
                      fontWeight: FontWeight.w600,
                      color: charcoalBlack.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // PLAYER NAME
          Expanded(
            child: Text(
              nickname,
              style: GoogleFonts.notoSans(
                fontSize: isTopThree ? 15 : 14,
                fontWeight: isMe
                    ? FontWeight.w700
                    : (isTopThree ? FontWeight.w500 : FontWeight.w400),
                color: charcoalBlack,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // SCORE
          Text(
            '$scoreVal',
            style: AppTypography.body.copyWith(
              fontSize: isTopThree ? 16 : 14,
              fontWeight: isMe
                  ? FontWeight.w900
                  : (isTopThree ? FontWeight.w800 : FontWeight.w600),
              color: charcoalBlack.withValues(alpha: isTopThree ? 1.0 : 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyRankingState extends StatelessWidget {
  const EmptyRankingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'NO RANKING DATA',
        style: AppTypography.label.copyWith(
          color: charcoalBlack.withValues(alpha: 0.2),
          fontSize: 14,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class RankingErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const RankingErrorState({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'RANKING LOAD FAILED',
              style: AppTypography.label.copyWith(
                color: charcoalBlack.withValues(alpha: 0.35),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
