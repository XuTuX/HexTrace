import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:linkagon/constant.dart';
import 'package:linkagon/services/database_service.dart';

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
      final scores = await dbService.getLeaderboard(gameId).catchError((e) {
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: charcoalBlack.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                const Text(
                  '🏆',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  '주간 랭킹',
                  style: GoogleFonts.blackHanSans(
                    fontSize: 14,
                    color: charcoalBlack,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onViewAll,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '전체 보기',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: charcoalBlack.withValues(alpha: 0.4),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: charcoalBlack.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: charcoalBlack.withValues(alpha: 0.2),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_topScores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'NO DATA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: charcoalBlack.withValues(alpha: 0.15),
                  letterSpacing: 1.5,
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Divider(
                color: charcoalBlack.withValues(alpha: 0.06),
                height: 16,
              ),
            ),
            ...List.generate(_topScores.length, (index) {
              return _RankRow(
                rank: index + 1,
                data: _topScores[index],
                isLast: index == _topScores.length - 1,
              );
            }),
          ],
          const SizedBox(height: 6),
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

    final Color rankBg;
    final Color rankFg;
    switch (rank) {
      case 1:
        rankBg = const Color(0xFFFFB300);
        rankFg = Colors.white;
        break;
      case 2:
        rankBg = const Color(0xFFB0BEC5);
        rankFg = Colors.white;
        break;
      case 3:
        rankBg = const Color(0xFFBF8040);
        rankFg = Colors.white;
        break;
      default:
        rankBg = charcoalBlack.withValues(alpha: 0.08);
        rankFg = charcoalBlack;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rankBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: rankFg,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nickname.toString(),
              style: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: charcoalBlack.withValues(alpha: 0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatScore(score),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: charcoalBlack.withValues(alpha: 0.7),
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
