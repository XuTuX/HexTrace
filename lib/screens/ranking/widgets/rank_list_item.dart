import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:linkagon/constant.dart';
import 'package:linkagon/theme/app_typography.dart';

class RankListItem extends StatelessWidget {
  const RankListItem({
    super.key,
    required this.scoreData,
    required this.index,
    required this.myId,
  });

  final Map<String, dynamic> scoreData;
  final int index;
  final String? myId;

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
    final isMe = userId != null && userId == myId;
    final rankValue = scoreData['rank'];
    final rank = switch (rankValue) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value) ?? (index + 1),
      _ => index + 1,
    };
    final isTopThree = rank <= 3;

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
