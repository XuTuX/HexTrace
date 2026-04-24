import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/game/game_palette.dart';
import 'package:hexor/game/hex_game_controller.dart';
import 'package:hexor/screens/ranking/ranking_data_loader.dart';
import 'package:hexor/screens/ranking/ranking_period.dart';
import 'package:hexor/screens/ranking/widgets/rank_list_item.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_service.dart';
import 'package:hexor/theme/app_typography.dart';
import 'package:hexor/utils/kst_clock.dart';


class DailyRankingCalendarPage extends StatefulWidget {
  const DailyRankingCalendarPage({
    super.key,
    required this.scoreController,
    required this.authService,
    required this.onStartDaily,
    required this.onShowDailyRanking,
    required this.onRankingTap,
  });

  final ScoreController scoreController;
  final AuthService authService;
  final Future<void> Function() onStartDaily;
  final VoidCallback onShowDailyRanking;
  final VoidCallback onRankingTap;

  @override
  State<DailyRankingCalendarPage> createState() =>
      _DailyRankingCalendarPageState();
}

class _DailyRankingCalendarPageState extends State<DailyRankingCalendarPage> {
  late final Set<String> _selectableDateKeys;
  late final List<_CalendarCellData> _calendarCells;
  late String _selectedDateKey;
  late final Worker _authWorker;
  bool _isRankLoading = false;
  bool _isSelectedRankingLoading = false;
  String? _selectedRankingError;
  Map<String, int> _myDailyRanks = {};
  List<Map<String, dynamic>> _selectedScores = [];

  @override
  void initState() {
    super.initState();
    final recentDateKeys = KstClock.recentDateKeys(days: 30);
    _selectableDateKeys = recentDateKeys.toSet();
    _calendarCells = _buildCurrentMonthCells();
    _selectedDateKey = recentDateKeys.first;
    _loadMyDailyRanks();
    _loadSelectedRanking(_selectedDateKey);
    _authWorker = ever(widget.authService.user, (_) {
      if (mounted) {
        _loadMyDailyRanks();
        _loadSelectedRanking(_selectedDateKey);
      }
    });
  }

  @override
  void dispose() {
    _authWorker.dispose();
    super.dispose();
  }

  void _selectDate(String dateKey) {
    setState(() => _selectedDateKey = dateKey);
    _loadSelectedRanking(dateKey);
  }

  Future<void> _loadMyDailyRanks() async {
    if (!mounted) {
      return;
    }

    if (widget.authService.user.value == null) {
      setState(() {
        _myDailyRanks = {};
        _isRankLoading = false;
      });
      return;
    }

    setState(() => _isRankLoading = true);

    final dbService = Get.find<DatabaseService>();
    final dateKeys = _calendarCells
        .map((cell) => cell.dateKey)
        .whereType<String>()
        .where(_selectableDateKeys.contains)
        .toList(growable: false);

    final entries = await Future.wait(
      dateKeys.map((dateKey) async {
        final rank = await dbService.getMyDailyRank(gameId, dateKey: dateKey);
        return MapEntry(dateKey, rank);
      }),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _myDailyRanks = {
        for (final entry in entries)
          if (entry.value != null) entry.key: entry.value!,
      };
      _isRankLoading = false;
    });
  }

  Future<void> _loadSelectedRanking(String dateKey) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isSelectedRankingLoading = true;
      _selectedRankingError = null;
    });

    try {
      final snapshot = await loadRankingSnapshot(
        scoreController: widget.scoreController,
        authService: widget.authService,
        dbService: Get.find<DatabaseService>(),
        period: RankingPeriod.daily,
        dateKey: dateKey,
      );

      if (!mounted || _selectedDateKey != dateKey) {
        return;
      }

      setState(() {
        _selectedScores = snapshot.scores;
        _isSelectedRankingLoading = false;
      });
    } catch (error) {
      if (!mounted || _selectedDateKey != dateKey) {
        return;
      }

      setState(() {
        _selectedScores = [];
        _selectedRankingError = error.toString();
        _isSelectedRankingLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final isTablet = mediaSize.shortestSide >= 600;
    final horizontalPadding = isTablet ? 40.0 : 24.0;
    final maxWidth = isTablet ? 680.0 : 480.0;
    final myId = widget.authService.user.value?.id;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, isTablet ? 36 : 18,
          horizontalPadding, isTablet ? 36 : 22),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _CalendarHeader(),
                      const SizedBox(height: 20),
                      _MonthlyCalendar(
                        cells: _calendarCells,
                        selectableDateKeys: _selectableDateKeys,
                        selectedDateKey: _selectedDateKey,
                        myDailyRanks: _myDailyRanks,
                        isRankLoading: _isRankLoading,
                        onDateSelected: _selectDate,
                      ),
                      const SizedBox(height: 18),
                      _InlineDailyRankingPanel(
                        dateKey: _selectedDateKey,
                        scores: _selectedScores,
                        myId: myId,
                        isLoading: _isSelectedRankingLoading,
                        error: _selectedRankingError,
                        onRetry: () => _loadSelectedRanking(_selectedDateKey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _DailyPlayButton(
                onPressed: () {
                  widget.onStartDaily();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_CalendarCellData> _buildCurrentMonthCells() {
    final today = KstClock.nowInKst();
    final firstDay = DateTime(today.year, today.month);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final leadingEmptyCells = firstDay.weekday % 7;
    final cells = <_CalendarCellData>[
      for (var index = 0; index < leadingEmptyCells; index++)
        const _CalendarCellData.empty(),
    ];

    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(today.year, today.month, day);
      cells
          .add(_CalendarCellData(dateKey: KstClock.dateKeyFor(date), day: day));
    }

    while (cells.length % 7 != 0) {
      cells.add(const _CalendarCellData.empty());
    }

    return cells;
  }
}

class _DailyPlayButton extends StatefulWidget {
  const _DailyPlayButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_DailyPlayButton> createState() => _DailyPlayButtonState();
}

class _DailyPlayButtonState extends State<_DailyPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

    return Container(
      width: double.infinity,
      height: isTablet ? 80 : 68,
      decoration: BoxDecoration(
        color: charcoalBlack,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, child) {
          return ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: charcoalBlack,
              elevation: 0,
              side: const BorderSide(color: charcoalBlack, width: 2.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: EdgeInsets.zero,
            ),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(_shimmer.value - 1, 0),
                  end: Alignment(_shimmer.value, 0),
                  colors: const [
                    Color(0xFF1A1A1A),
                    Color(0xFF5B3A00),
                    Color(0xFF1A1A1A),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds);
              },
              child: Text(
                '오늘의 도전',
                style: GoogleFonts.blackHanSans(
                  fontSize: isTablet ? 28 : 25,
                  letterSpacing: 0,
                  color: charcoalBlack,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader();

  @override
  Widget build(BuildContext context) {
    final today = KstClock.nowInKst();
    final monthLabel = '${today.year}년 ${today.month}월';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFBEB),
                Color(0xFFFEF3C7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: charcoalBlack, width: 2),
            boxShadow: const [
              BoxShadow(
                color: charcoalBlack,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: Color(0xFFF59E0B),
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘의 퍼즐',
                style: GoogleFonts.blackHanSans(
                  fontSize: 24,
                  color: charcoalBlack,
                  height: 1.0,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                monthLabel,
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: charcoalBlack.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthlyCalendar extends StatelessWidget {
  const _MonthlyCalendar({
    required this.cells,
    required this.selectableDateKeys,
    required this.selectedDateKey,
    required this.myDailyRanks,
    required this.isRankLoading,
    required this.onDateSelected,
  });

  final List<_CalendarCellData> cells;
  final Set<String> selectableDateKeys;
  final String selectedDateKey;
  final Map<String, int> myDailyRanks;
  final bool isRankLoading;
  final ValueChanged<String> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final todayKey = KstClock.currentDateKey();
    const columns = 7;
    const gap = 5.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: charcoalBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chipWidth =
              (constraints.maxWidth - (gap * (columns - 1))) / columns;
          return Column(
            children: [
              Row(
                children: ['일', '월', '화', '수', '목', '금', '토'].map((label) {
                  final isSun = label == '일';
                  final isSat = label == '토';
                  return SizedBox(
                    width: chipWidth,
                    child: Center(
                      child: Text(
                        label,
                        style: AppTypography.tiny.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: isSun
                              ? GamePalette.colorFor(GameColor.coral)
                                  .withValues(alpha: 0.5)
                              : isSat
                                  ? GamePalette.colorFor(GameColor.azure)
                                      .withValues(alpha: 0.5)
                                  : charcoalBlack.withValues(alpha: 0.30),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: cells.map((cell) {
                  final dateKey = cell.dateKey;
                  if (dateKey == null) {
                    return SizedBox(width: chipWidth, height: 54);
                  }

                  final isEnabled = selectableDateKeys.contains(dateKey);
                  return _DateChip(
                    width: chipWidth,
                    day: cell.day,
                    rank: myDailyRanks[dateKey],
                    isSelected: dateKey == selectedDateKey,
                    isToday: dateKey == todayKey,
                    isEnabled: isEnabled,
                    isRankLoading: isRankLoading,
                    onTap: isEnabled ? () => onDateSelected(dateKey) : null,
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.width,
    required this.day,
    required this.rank,
    required this.isSelected,
    required this.isToday,
    required this.isEnabled,
    required this.isRankLoading,
    required this.onTap,
  });

  final double width;
  final int day;
  final int? rank;
  final bool isSelected;
  final bool isToday;
  final bool isEnabled;
  final bool isRankLoading;
  final VoidCallback? onTap;

  /// Subtle dot color based on rank tier — no text, just a small indicator.
  Color get _rankDotColor {
    if (rank == null) return Colors.transparent;
    return switch (rank!) {
      1 => GamePalette.colorFor(GameColor.amber),
      2 => const Color(0xFF94A3B8),
      3 => GamePalette.colorFor(GameColor.coral),
      _ => const Color(0xFF93C5FD),
    };
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? charcoalBlack
        : isToday
            ? const Color(0xFFF8FAFC)
            : const Color(0xFFF8FAFC);
    final foregroundColor = isSelected
        ? Colors.white
        : isEnabled
            ? charcoalBlack
            : charcoalBlack.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: width,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isSelected
                ? charcoalBlack
                : isToday
                    ? charcoalBlack.withValues(alpha: 0.25)
                    : charcoalBlack.withValues(alpha: isEnabled ? 0.08 : 0.03),
            width: isSelected
                ? 2
                : isToday
                    ? 1.8
                    : 1.5,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: charcoalBlack,
                    offset: Offset(2, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.toString(),
              style: GoogleFonts.blackHanSans(
                fontSize: 14,
                color: foregroundColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            if (rank != null)
              // Subtle small dot for rank — no text
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.6)
                      : _rankDotColor.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              )
            else if (isToday)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : charcoalBlack.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              )
            else if (isRankLoading && isEnabled)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.5)
                      : charcoalBlack.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineDailyRankingPanel extends StatelessWidget {
  const _InlineDailyRankingPanel({
    required this.dateKey,
    required this.scores,
    required this.myId,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final String dateKey;
  final List<Map<String, dynamic>> scores;
  final String? myId;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: charcoalBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 15,
                color: charcoalBlack.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatDate(dateKey)} 랭킹',
                style: GoogleFonts.blackHanSans(
                  fontSize: 16,
                  color: charcoalBlack,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  color: charcoalBlack.withValues(alpha: 0.06),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: charcoalBlack,
                    strokeWidth: 3,
                  ),
                ),
              ),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onRetry,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: charcoalBlack, width: 1.5),
                    ),
                    child: Text(
                      '다시 불러오기',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            ...List.generate(
              scores.length > 6 ? 6 : scores.length,
              (index) => RankListItem(
                scoreData: scores[index],
                index: index,
                myId: myId,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      return dateKey;
    }

    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (month == null || day == null) {
      return dateKey;
    }

    return '$month.$day';
  }
}

class _CalendarCellData {
  const _CalendarCellData({
    required this.dateKey,
    required this.day,
  });

  const _CalendarCellData.empty()
      : dateKey = null,
        day = 0;

  final String? dateKey;
  final int day;
}
