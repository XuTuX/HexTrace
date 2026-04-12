import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/screens/ranking/weekly_reset_info.dart';
import 'package:hexor/services/database_service.dart';
import 'package:hexor/game/game_palette.dart';
import 'package:hexor/game/hex_game_controller.dart';

class WeeklyRankingPreview extends StatefulWidget {
  const WeeklyRankingPreview({
    super.key,
    required this.onViewAll,
  });

  final VoidCallback onViewAll;

  @override
  State<WeeklyRankingPreview> createState() => _WeeklyRankingPreviewState();
}

class _WeeklyRankingPreviewState extends State<WeeklyRankingPreview> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _topScores = [];

  @override
  void initState() {
    super.initState();
    _loadTopScores();
  }

  Future<void> _loadTopScores() async {
    try {
      final dbService = Get.find<DatabaseService>();
      final scores = await dbService
          .getWeeklyLeaderboard(gameId, limit: 3)
          .catchError((e) {
        debugPrint('🔴 [WeeklyRankingPreview] Error: $e');
        return <Map<String, dynamic>>[];
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _topScores = List<Map<String, dynamic>>.from(scores.take(3));
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeklyResetInfo = WeeklyResetInfo.current();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: charcoalBlack,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: GamePalette.colorFor(GameColor.amber),
                    shape: BoxShape.circle,
                    border: Border.all(color: charcoalBlack, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '주간 랭킹',
                  style: GoogleFonts.blackHanSans(
                    fontSize: 16,
                    letterSpacing: 0.5,
                    color: charcoalBlack,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onViewAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: charcoalBlack.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '더 보기',
                          style: GoogleFonts.notoSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: charcoalBlack.withValues(alpha: 0.4),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: charcoalBlack.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: charcoalBlack,
                  strokeWidth: 3,
                ),
              ),
            )
          else if (_topScores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'NO DATA',
                style: GoogleFonts.blackHanSans(
                  fontSize: 14,
                  color: charcoalBlack.withValues(alpha: 0.1),
                  letterSpacing: 2.0,
                ),
              ),
            )
          else ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: charcoalBlack.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: List.generate(_topScores.length, (index) {
                  return _RankRow(
                    rank: index + 1,
                    data: _topScores[index],
                    isLast: index == _topScores.length - 1,
                  );
                }),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, size: 12, color: charcoalBlack38),
                const SizedBox(width: 4),
                Text(
                  weeklyResetInfo.koreanLabel,
                  style: GoogleFonts.notoSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: charcoalBlack.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.data,
    this.isLast = false,
  });

  final int rank;
  final Map<String, dynamic> data;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final profileData = data['profiles'];
    Map<String, dynamic> profiles = {};
    if (profileData is Map<String, dynamic>) {
      profiles = profileData;
    } else if (profileData is List && profileData.isNotEmpty) {
      profiles = profileData[0] as Map<String, dynamic>;
    }

    final nickname = profiles['nickname'] ?? 'Player';
    final score = data['score'] ?? 0;

    final Color rankColor = switch (rank) {
      1 => GamePalette.colorFor(GameColor.amber),
      2 => charcoalBlack.withValues(alpha: 0.4),
      3 => GamePalette.colorFor(GameColor.coral),
      _ => charcoalBlack.withValues(alpha: 0.2),
    };

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: charcoalBlack.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: GoogleFonts.blackHanSans(
                fontSize: 16,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nickname.toString(),
              style: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: charcoalBlack,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatScore(score),
            style: GoogleFonts.blackHanSans(
              fontSize: 14,
              color: charcoalBlack.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'P',
            style: GoogleFonts.notoSans(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: charcoalBlack.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(dynamic score) {
    final value = score is int ? score : int.tryParse(score.toString()) ?? 0;
    if (value < 1000) {
      return value.toString();
    }

    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[index]);
    }

    return buffer.toString();
  }
}
