import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/screens/ranking/ranking_data_loader.dart';
import 'package:hexor/screens/ranking/ranking_period.dart';
import 'package:hexor/screens/ranking/widgets/rank_list_item.dart';
import 'package:hexor/screens/ranking/widgets/ranking_chrome.dart';
import 'package:hexor/screens/ranking/widgets/ranking_states.dart';
import 'package:hexor/services/auth_service.dart';
import 'package:hexor/services/database_service.dart';
import 'package:hexor/theme/app_typography.dart';
import 'package:hexor/utils/kst_clock.dart';
import 'package:hexor/widgets/home_screen/home_components.dart';

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
  bool _isLoading = true;
  String? _error;
  int? _myRank;
  int? _myScore;
  List<Map<String, dynamic>> _scores = [];

  @override
  void initState() {
    super.initState();
    final recentDateKeys = KstClock.recentDateKeys(days: 30);
    _selectableDateKeys = recentDateKeys.toSet();
    _calendarCells = _buildCurrentMonthCells();
    _selectedDateKey = recentDateKeys.first;
    _loadRankingData();
    _authWorker = ever(widget.authService.user, (_) {
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
      final snapshot = await loadRankingSnapshot(
        scoreController: widget.scoreController,
        authService: widget.authService,
        dbService: Get.find<DatabaseService>(),
        period: RankingPeriod.daily,
        dateKey: _selectedDateKey,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _myRank = snapshot.myRank;
        _myScore = snapshot.myScore;
        _scores = snapshot.scores;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  void _selectDate(String dateKey) {
    if (_selectedDateKey == dateKey) {
      return;
    }

    setState(() => _selectedDateKey = dateKey);
    _loadRankingData();
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
              _CalendarHeader(onRankingTap: widget.onRankingTap),
              const SizedBox(height: 14),
              HomeProgressPanel(
                authService: widget.authService,
                onStartDaily: widget.onStartDaily,
                onShowDailyRanking: widget.onShowDailyRanking,
              ),
              const SizedBox(height: 16),
              _MonthlyCalendar(
                cells: _calendarCells,
                selectableDateKeys: _selectableDateKeys,
                selectedDateKey: _selectedDateKey,
                onDateSelected: _selectDate,
              ),
              const SizedBox(height: 14),
              if (_isLoading)
                const Expanded(child: RankingLoadingState())
              else if (_error != null)
                Expanded(child: RankingErrorState(onRetry: _loadRankingData))
              else ...[
                _MyDailyRankSummary(
                  dateKey: _selectedDateKey,
                  rank: _myRank,
                  score: _myScore,
                  isLoggedIn: myId != null,
                ),
                const SizedBox(height: 16),
                const TopPlayersLabel(period: RankingPeriod.daily),
                const SizedBox(height: 8),
                Expanded(
                  child: _scores.isEmpty
                      ? const EmptyRankingState(period: RankingPeriod.daily)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
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

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({required this.onRankingTap});

  final VoidCallback onRankingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
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
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
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
                '날짜를 고르면 내 등수와 순위가 보여요',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: charcoalBlack.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _AllRankingButton(onTap: onRankingTap),
      ],
    );
  }
}

class _AllRankingButton extends StatelessWidget {
  const _AllRankingButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: charcoalBlack,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: charcoalBlack,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              size: 15,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              '전체 랭킹',
              style: GoogleFonts.blackHanSans(
                fontSize: 13,
                color: Colors.white,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyCalendar extends StatelessWidget {
  const _MonthlyCalendar({
    required this.cells,
    required this.selectableDateKeys,
    required this.selectedDateKey,
    required this.onDateSelected,
  });

  final List<_CalendarCellData> cells;
  final Set<String> selectableDateKeys;
  final String selectedDateKey;
  final ValueChanged<String> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final todayKey = KstClock.currentDateKey();
    const columns = 7;
    const gap = 5.0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                  return SizedBox(
                    width: chipWidth,
                    child: Center(
                      child: Text(
                        label,
                        style: AppTypography.tiny.copyWith(
                          fontSize: 10,
                          color: charcoalBlack.withValues(alpha: 0.34),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: cells.map((cell) {
                  final dateKey = cell.dateKey;
                  if (dateKey == null) {
                    return SizedBox(width: chipWidth, height: 38);
                  }

                  final isEnabled = selectableDateKeys.contains(dateKey);
                  return _DateChip(
                    width: chipWidth,
                    day: cell.day,
                    isSelected: dateKey == selectedDateKey,
                    isToday: dateKey == todayKey,
                    isEnabled: isEnabled,
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
    required this.isSelected,
    required this.isToday,
    required this.isEnabled,
    required this.onTap,
  });

  final double width;
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? charcoalBlack
        : isToday
            ? const Color(0xFFE0F2FE)
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
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isSelected
                ? charcoalBlack
                : isToday
                    ? const Color(0xFF2563EB).withValues(alpha: 0.28)
                    : charcoalBlack.withValues(alpha: isEnabled ? 0.1 : 0.04),
            width: isSelected ? 2 : 1,
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              day.toString(),
              style: GoogleFonts.blackHanSans(
                fontSize: 14,
                color: foregroundColor,
                height: 1.0,
              ),
            ),
            if (isToday)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MyDailyRankSummary extends StatelessWidget {
  const _MyDailyRankSummary({
    required this.dateKey,
    required this.rank,
    required this.score,
    required this.isLoggedIn,
  });

  final String dateKey;
  final int? rank;
  final int? score;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    final isToday = dateKey == KstClock.currentDateKey();
    final hasRank = rank != null && score != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: charcoalBlack, width: 2),
        boxShadow: const [
          BoxShadow(
            color: charcoalBlack,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? '오늘 내 등수' : '${dateKey.replaceAll('-', '.')} 내 등수',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: charcoalBlack.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _message(hasRank: hasRank),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: charcoalBlack.withValues(alpha: 0.48),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          if (hasRank)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$rank',
                  style: GoogleFonts.blackHanSans(
                    fontSize: 38,
                    color: const Color(0xFF2563EB),
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '등',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: charcoalBlack54,
                  ),
                ),
              ],
            )
          else
            Icon(
              isLoggedIn
                  ? Icons.sentiment_satisfied_alt_rounded
                  : Icons.lock_outline_rounded,
              color: charcoalBlack.withValues(alpha: 0.24),
              size: 30,
            ),
        ],
      ),
    );
  }

  String _message({required bool hasRank}) {
    if (!isLoggedIn) {
      return '로그인하면 내 등수를 볼 수 있어요';
    }
    if (!hasRank) {
      return '이 날짜에는 아직 기록이 없어요';
    }
    return '${_formatScore(score!)}점으로 기록됐어요';
  }

  String _formatScore(int value) {
    final digits = value.toString();
    if (digits.length <= 3) return digits;
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
