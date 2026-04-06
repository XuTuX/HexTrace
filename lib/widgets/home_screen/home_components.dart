import 'dart:math';

import 'package:hexor/constant.dart';
import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/game/game_palette.dart';
import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_service.dart';
import 'package:google_fonts/google_fonts.dart';

// ──────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS (shared across all home screen widgets)
// ──────────────────────────────────────────────────────────────────────

const double _borderWidth = 2.5;
const double _cardRadius = 20.0;
const Offset _shadowOffset = Offset(3, 3);

BoxDecoration _cardDecoration({
  Color fill = Colors.white,
  double radius = _cardRadius,
}) =>
    BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: charcoalBlack, width: _borderWidth),
      boxShadow: const [
        BoxShadow(
          color: charcoalBlack,
          offset: _shadowOffset,
          blurRadius: 0,
        ),
      ],
    );

// ──────────────────────────────────────────────────────────────────────
//  1. LOGO + HEX CLUSTER
// ──────────────────────────────────────────────────────────────────────

class HomeLogo extends StatelessWidget {
  const HomeLogo({super.key, this.width = 240});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/logo.png',
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class HexCluster extends StatelessWidget {
  const HexCluster({super.key, this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) {
    // 5 game colors arranged in a tight hex cluster
    final colors = [
      GamePalette.colorFor(GameColor.azure),
      GamePalette.colorFor(GameColor.violet),
      GamePalette.colorFor(GameColor.mint),
      GamePalette.colorFor(GameColor.coral),
      GamePalette.colorFor(GameColor.amber),
    ];
    final offsets = [
      Offset(0, -size * 0.55),
      Offset(size * 0.48, 0),
      Offset(-size * 0.48, 0),
      Offset(size * 0.48, -size * 0.55),
      Offset(-size * 0.48, -size * 0.55),
    ];

    return SizedBox(
      width: size * 2.2,
      height: size * 1.8,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: List.generate(colors.length, (i) {
          return Positioned(
            left: size * 1.1 + offsets[i].dx - size * 0.38,
            top: size * 0.9 + offsets[i].dy - size * 0.38,
            child: _HexTile(color: colors[i], tileSize: size * 0.68),
          );
        }),
      ),
    );
  }
}

class _HexTile extends StatelessWidget {
  const _HexTile({required this.color, this.tileSize = 28});
  final Color color;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tileSize,
      height: tileSize,
      child: CustomPaint(
        painter: _HexPainter(color),
        child: Center(
          child: Container(
            width: tileSize * 0.22,
            height: tileSize * 0.22,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  _HexPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexPath(size);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = charcoalBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Path _hexPath(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 180) * (60 * i - 30);
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────────────────────────────────────────
//  2. INFO CARDS (Best Score  ·  Timer)
// ──────────────────────────────────────────────────────────────────────

class InfoCardsRow extends StatelessWidget {
  final ScoreController scoreController;
  final AuthService authService;

  const InfoCardsRow({
    super.key,
    required this.scoreController,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.emoji_events_rounded,
            iconColor: const Color(0xFFFFB300),
            label: '점수',
            child: Obx(() {
              final isLoading = authService.isLoading.value ||
                  scoreController.isSyncing.value;
              if (isLoading) {
                return const SizedBox(
                  height: 32,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: charcoalBlack,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                );
              }
              return Text(
                '${scoreController.highscore.value}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: charcoalBlack,
                  height: 1.0,
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.schedule_rounded,
            iconColor: const Color(0xFF0095FF),
            label: '시간',
            child: Text(
              '59초',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0095FF),
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: charcoalBlack.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  3. COLOR BAR PREVIEW
// ──────────────────────────────────────────────────────────────────────

class ColorBarPreview extends StatelessWidget {
  const ColorBarPreview({super.key});

  @override
  Widget build(BuildContext context) {
    // Static preview of the color bar, using the game palette colors
    final sampleColors = [
      GamePalette.colorFor(GameColor.mint),
      GamePalette.colorFor(GameColor.amber),
      GamePalette.colorFor(GameColor.violet),
      GamePalette.colorFor(GameColor.azure),
      GamePalette.colorFor(GameColor.coral),
      GamePalette.colorFor(GameColor.mint),
      GamePalette.colorFor(GameColor.violet),
      GamePalette.colorFor(GameColor.amber),
      GamePalette.colorFor(GameColor.azure),
      GamePalette.colorFor(GameColor.coral),
      GamePalette.colorFor(GameColor.mint),
      GamePalette.colorFor(GameColor.azure),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '사용한 구간만 사라져요',
                style: TextStyle(
                  color: charcoalBlack.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 4.0;
              final slotW = (constraints.maxWidth -
                      gap * (sampleColors.length - 1)) /
                  sampleColors.length;
              final slotH = slotW * 1.5;

              return SizedBox(
                height: slotH,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: sampleColors.map((c) {
                    return Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.only(right: c == sampleColors.last ? 0 : gap),
                        child: Container(
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color: charcoalBlack, width: 2.0),
                            boxShadow: const [
                              BoxShadow(
                                color: charcoalBlack,
                                offset: Offset(1.5, 1.5),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  4. PRIMARY ACTION BUTTONS
// ──────────────────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 62,
      decoration: BoxDecoration(
        color: charcoalBlack,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0095FF), // Azure blue
          foregroundColor: Colors.white,
          elevation: 0,
          side: const BorderSide(color: charcoalBlack, width: _borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 26, color: Colors.white),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: GoogleFonts.blackHanSans(
                fontSize: 22,
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RankingButton extends StatelessWidget {
  final VoidCallback onPressed;

  const RankingButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 62,
      decoration: BoxDecoration(
        color: charcoalBlack,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: charcoalBlack,
          elevation: 0,
          side: const BorderSide(color: charcoalBlack, width: _borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: charcoalBlack.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '🏆',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '랭킹',
              style: GoogleFonts.blackHanSans(
                fontSize: 18,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: charcoalBlack.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: charcoalBlack,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: charcoalBlack,
          elevation: 0,
          side: const BorderSide(color: charcoalBlack, width: _borderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 22),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.blackHanSans(
                fontSize: 18,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  5. WEEKLY RANKING PREVIEW
// ──────────────────────────────────────────────────────────────────────

class WeeklyRankingPreview extends StatefulWidget {
  final VoidCallback onViewAll;

  const WeeklyRankingPreview({
    super.key,
    required this.onViewAll,
  });

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
      if (!mounted) return;
      setState(() {
        _topScores = List<Map<String, dynamic>>.from(scores.take(3));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 0),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  '주간 랭킹',
                  style: GoogleFonts.blackHanSans(
                    fontSize: 16,
                    color: charcoalBlack,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onViewAll,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: charcoalBlack.withValues(alpha: 0.12),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '전체 보기',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: charcoalBlack.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: charcoalBlack.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: charcoalBlack.withValues(alpha: 0.08),
              height: 20,
            ),
          ),

          // Ranking List
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: charcoalBlack.withValues(alpha: 0.3),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_topScores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'NO DATA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: charcoalBlack.withValues(alpha: 0.2),
                  letterSpacing: 1.5,
                ),
              ),
            )
          else
            ...List.generate(_topScores.length, (i) {
              return _RankRow(
                rank: i + 1,
                data: _topScores[i],
                isLast: i == _topScores.length - 1,
              );
            }),

          const SizedBox(height: 8),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: charcoalBlack.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rankBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: rankFg,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name
          Expanded(
            child: Text(
              nickname.toString().toUpperCase(),
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: charcoalBlack,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Score
          Text(
            _formatScore(score),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: charcoalBlack,
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(dynamic score) {
    final n = score is int ? score : int.tryParse(score.toString()) ?? 0;
    if (n >= 1000) {
      final s = n.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    return n.toString();
  }
}

// ──────────────────────────────────────────────────────────────────────
//  6. SETTINGS BUTTON  &  GAMEPLAY TIP
// ──────────────────────────────────────────────────────────────────────

class SettingsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SettingsButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: _cardDecoration(radius: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.settings_rounded,
              color: charcoalBlack.withValues(alpha: 0.65),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '설정',
              style: GoogleFonts.blackHanSans(
                fontSize: 15,
                color: charcoalBlack.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameplayTip extends StatelessWidget {
  const GameplayTip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FF), // Soft violet tint
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: charcoalBlack.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '게임 방법',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: charcoalBlack.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '같은 색 육각형을 연결하여\n선을 만들면 사용한 구간이 사라집니다.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: charcoalBlack.withValues(alpha: 0.5),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  PROFILE BUTTON (reused from original — settings circle)
// ──────────────────────────────────────────────────────────────────────

class ProfileButton extends StatelessWidget {
  final AuthService authService;
  final VoidCallback onProfileTap;
  final VoidCallback onLoginTap;

  const ProfileButton({
    super.key,
    required this.authService,
    required this.onProfileTap,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (authService.isLoading.value) {
        return Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: const CircularProgressIndicator(
              color: Colors.black, strokeWidth: 2),
        );
      }

      if (authService.loginSuccess.value) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.5 + (value * 0.5),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            );
          },
        );
      }

      return GestureDetector(
        onTap: onProfileTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.settings_rounded,
            color: Colors.black,
          ),
        ),
      );
    });
  }
}

// ──────────────────────────────────────────────────────────────────────
//  LOGIN BUTTON (reused from original)
// ──────────────────────────────────────────────────────────────────────

class LoginButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconSize;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onPressed;

  const LoginButton({
    super.key,
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          side: BorderSide(color: borderColor, width: 2.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTypography.button.copyWith(
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
//  HIGH SCORE CARD (legacy — kept for backwards compat if needed)
// ──────────────────────────────────────────────────────────────────────

class HighScoreCard extends StatelessWidget {
  final ScoreController scoreController;
  final AuthService authService;

  const HighScoreCard({
    super.key,
    required this.scoreController,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final nickname = authService.userNickname.value;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                const Text(
                  'BEST SCORE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final isLoading = authService.isLoading.value ||
                      scoreController.isSyncing.value;
                  if (isLoading) {
                    return const SizedBox(
                      height: 48,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: charcoalBlack,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    );
                  }
                  return Text(
                    '${scoreController.highscore.value}',
                    style: AppTypography.scoreDisplay,
                  );
                }),
              ],
            ),
          ),
          if (nickname != null)
            Positioned(
              top: -14,
              left: 16,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Transform.rotate(
                      angle: -0.05,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: regionColors[2],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: charcoalBlack, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: charcoalBlack,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        color: charcoalBlack,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          nickname,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.blackHanSans(
                            fontSize: 16,
                            color: charcoalBlack,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
