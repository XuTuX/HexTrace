import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hexor/constant.dart';
import 'package:hexor/controllers/score_controller.dart';
import 'package:hexor/screens/ranking/ranking_data_loader.dart';
import 'package:hexor/screens/ranking/ranking_period.dart';
import 'package:hexor/screens/ranking/widgets/rank_list_item.dart';
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
              PrimaryButton(
                label: '게임 시작',
                icon: Icons.play_arrow_rounded,
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

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
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
        height: 54,
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
            const SizedBox(height: 4),
            if (rank != null)
              Text(
                '$rank등',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.tiny.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.86)
                      : const Color(0xFF2563EB),
                ),
              )
            else if (isToday)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFF2563EB),
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
        borderRadius: BorderRadius.circular(20),
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
                  color: charcoalBlack.withValues(alpha: 0.08),
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
