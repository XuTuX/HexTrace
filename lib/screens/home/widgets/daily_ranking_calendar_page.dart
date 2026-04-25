import 'package:flutter/foundation.dart';
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

class DailyRankingCalendarPage extends StatefulWidget {
  const DailyRankingCalendarPage({
    super.key,
    required this.scoreController,
    required this.authService,
    required this.onStartDaily,
    required this.onStartDailyTest,
    required this.onShowDailyRanking,
    required this.onRankingTap,
    required this.isVisible,
  });

  final ScoreController scoreController;
  final AuthService authService;
  final Future<void> Function() onStartDaily;
  final Future<void> Function() onStartDailyTest;
  final VoidCallback onShowDailyRanking;
  final VoidCallback onRankingTap;
  final bool isVisible;

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
  bool _isLaunching = false;
  bool _isLaunchingTest = false;
  bool _hasLoadedVisibleData = false;
  String? _selectedRankingError;
  Map<String, int> _myDailyRanks = {};
  List<Map<String, dynamic>> _selectedScores = [];
  int _rankLoadRequestId = 0;
  int _selectedRankingRequestId = 0;

  @override
  void initState() {
    super.initState();
    final recentDateKeys = KstClock.recentDateKeys(days: 30);
    _selectableDateKeys = recentDateKeys.toSet();
    _calendarCells = _buildCurrentMonthCells();
    _selectedDateKey = recentDateKeys.first;
    _authWorker = ever(widget.authService.user, (_) {
      if (mounted && widget.isVisible) {
        _hasLoadedVisibleData = false;
        _ensureVisibleDataLoaded(force: true);
      }
    });
    _ensureVisibleDataLoaded();
  }

  @override
  void dispose() {
    _authWorker.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DailyRankingCalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && (!oldWidget.isVisible || !_hasLoadedVisibleData)) {
      _ensureVisibleDataLoaded();
    }
  }

  void _ensureVisibleDataLoaded({bool force = false}) {
    if (!widget.isVisible) {
      return;
    }
    if (_hasLoadedVisibleData && !force) {
      return;
    }

    _hasLoadedVisibleData = true;
    _loadMyDailyRanks();
    _loadSelectedRanking(_selectedDateKey);
  }

  void _selectDate(String dateKey) {
    setState(() => _selectedDateKey = dateKey);
    _loadSelectedRanking(dateKey);
  }

  Future<void> _loadMyDailyRanks() async {
    if (!mounted) {
      return;
    }

    final requestId = ++_rankLoadRequestId;

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

    final ranks = <String, int>{};
    for (final dateKey in dateKeys) {
      final rank = await dbService.getMyDailyRank(gameId, dateKey: dateKey);
      if (!mounted || requestId != _rankLoadRequestId) {
        return;
      }
      if (rank != null) {
        ranks[dateKey] = rank;
      }
    }

    if (!mounted || requestId != _rankLoadRequestId) {
      return;
    }

    setState(() {
      _myDailyRanks = ranks;
      _isRankLoading = false;
    });
  }

  Future<void> _loadSelectedRanking(String dateKey) async {
    if (!mounted) {
      return;
    }

    final requestId = ++_selectedRankingRequestId;

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

      if (!mounted ||
          _selectedDateKey != dateKey ||
          requestId != _selectedRankingRequestId) {
        return;
      }

      setState(() {
        _selectedScores = snapshot.scores;
        _isSelectedRankingLoading = false;
      });
    } catch (error) {
      if (!mounted ||
          _selectedDateKey != dateKey ||
          requestId != _selectedRankingRequestId) {
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
    final sw = mediaSize.width;
    final sh = mediaSize.height;
    final horizontalPadding = isTablet
        ? (sw * 0.06).clamp(32.0, 60.0)
        : (sw * 0.06).clamp(16.0, 28.0);
    final maxWidth = isTablet ? 680.0 : 480.0;
    final myId = widget.authService.user.value?.id;
    final topPad = isTablet
        ? (sh * 0.03).clamp(24.0, 44.0)
        : (sh * 0.02).clamp(12.0, 22.0);
    final bottomPad = isTablet
        ? (sh * 0.03).clamp(24.0, 44.0)
        : (sh * 0.025).clamp(14.0, 26.0);
    final sectionGap = isTablet
        ? (sh * 0.02).clamp(14.0, 24.0)
        : (sh * 0.02).clamp(10.0, 20.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          horizontalPadding, topPad, horizontalPadding, bottomPad),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _CalendarHeader(),
                      SizedBox(height: sectionGap * 0.7),
                      _MonthlyCalendar(
                        cells: _calendarCells,
                        selectableDateKeys: _selectableDateKeys,
                        selectedDateKey: _selectedDateKey,
                        myDailyRanks: _myDailyRanks,
                        isRankLoading: _isRankLoading,
                        onDateSelected: _selectDate,
                      ),
                      SizedBox(height: sectionGap),
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
              SizedBox(height: sectionGap * 0.8),
              _DailyPlayButton(
                isLoading: _isLaunching,
                onPressed: _handleStartDaily,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 10),
                _DailyTestButton(
                  isLoading: _isLaunchingTest,
                  onPressed: _handleStartDailyTest,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleStartDaily() async {
    if (_isLaunching) {
      return;
    }

    setState(() => _isLaunching = true);
    try {
      await widget.onStartDaily();
    } finally {
      if (mounted) {
        setState(() => _isLaunching = false);
      }
    }
  }

  Future<void> _handleStartDailyTest() async {
    if (_isLaunchingTest) {
      return;
    }

    setState(() => _isLaunchingTest = true);
    try {
      await widget.onStartDailyTest();
    } finally {
      if (mounted) {
        setState(() => _isLaunchingTest = false);
      }
    }
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
  const _DailyPlayButton({
    required this.onPressed,
    required this.isLoading,
  });

  final Future<void> Function() onPressed;
  final bool isLoading;

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
    final ms = MediaQuery.sizeOf(context);
    final isTablet = ms.shortestSide >= 600;
    final btnH = isTablet
        ? (ms.height * 0.07).clamp(64.0, 88.0)
        : (ms.height * 0.078).clamp(52.0, 72.0);
    final btnFs = isTablet
        ? (ms.width * 0.032).clamp(22.0, 30.0)
        : (ms.width * 0.06).clamp(18.0, 26.0);
    final br = isTablet ? 28.0 : (ms.width * 0.06).clamp(18.0, 26.0);

    return Container(
      width: double.infinity,
      height: btnH,
      decoration: BoxDecoration(
        color: charcoalBlack,
        borderRadius: BorderRadius.circular(br),
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
            onPressed: widget.isLoading
                ? null
                : () {
                    widget.onPressed();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: charcoalBlack,
              elevation: 0,
              side: const BorderSide(color: charcoalBlack, width: 2.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(br),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading) ...[
                    SizedBox(
                      width: btnFs * 0.8,
                      height: btnFs * 0.8,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: charcoalBlack,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.isLoading ? '입장 중...' : '오늘의 퍼즐',
                    style: GoogleFonts.blackHanSans(
                      fontSize: btnFs,
                      letterSpacing: 0,
                      color: charcoalBlack,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DailyTestButton extends StatelessWidget {
  const _DailyTestButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading
          ? null
          : () {
              onPressed();
            },
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: charcoalBlack,
              ),
            )
          : const Icon(Icons.science_rounded),
      label: Text(isLoading ? '테스트 준비 중' : '테스트 플레이'),
      style: OutlinedButton.styleFrom(
        foregroundColor: charcoalBlack,
        side: const BorderSide(color: charcoalBlack, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 13),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader();

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final headerFs = (sw * 0.055).clamp(17.0, 26.0);
    final subFs = (sw * 0.035).clamp(11.0, 16.0);
    final today = KstClock.nowInKst();
    final monthLabel =
        '${today.year}.${today.month.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '오늘의 퍼즐',
          style: GoogleFonts.blackHanSans(
            fontSize: headerFs,
            color: charcoalBlack,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          monthLabel,
          style: GoogleFonts.notoSans(
            fontSize: subFs,
            fontWeight: FontWeight.w800,
            color: charcoalBlack.withValues(alpha: 0.2),
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
    const gap = 4.0;
    final sh = MediaQuery.sizeOf(context).height;
    // Proportional cell height
    final cellH = (sh * 0.055).clamp(36.0, 56.0);

    return Container(
      padding: const EdgeInsets.all(10),
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
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: cells.map((cell) {
                  final dateKey = cell.dateKey;
                  if (dateKey == null) {
                    return SizedBox(width: chipWidth, height: cellH);
                  }

                  final isEnabled = selectableDateKeys.contains(dateKey);
                  return _DateChip(
                    width: chipWidth,
                    height: cellH,
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
    required this.height,
    required this.day,
    required this.rank,
    required this.isSelected,
    required this.isToday,
    required this.isEnabled,
    required this.isRankLoading,
    required this.onTap,
  });

  final double width;
  final double height;
  final int day;
  final int? rank;
  final bool isSelected;
  final bool isToday;
  final bool isEnabled;
  final bool isRankLoading;
  final VoidCallback? onTap;

  /// Subtle dot color based on rank tier — no text, just a small indicator.
  Color get _rankBackgroundColor {
    if (rank == null) return Colors.transparent;
    return switch (rank!) {
      1 => const Color(0xFFFB7185), // Coral Red (1st)
      2 => const Color(0xFFFB923C), // Orange (2nd)
      3 => const Color(0xFFFBBF24), // Amber Yellow (3rd)
      _ => const Color(0xFFE2E8F0), // Participation (Subtle Slate)
    };
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? charcoalBlack
        : (rank != null)
            ? _rankBackgroundColor
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
        height: height,
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
                fontSize: 13,
                color: foregroundColor,
                height: 1.0,
              ),
            ),
            if (isToday) ...[
              const SizedBox(height: 3),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : charcoalBlack.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ] else if (isRankLoading && isEnabled) ...[
              const SizedBox(height: 3),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.5)
                      : charcoalBlack.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
              ),
            ],
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
    final sw = MediaQuery.sizeOf(context).width;
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final panelPad = isTablet
        ? (sw * 0.02).clamp(12.0, 20.0)
        : (sw * 0.036).clamp(12.0, 18.0);
    final headerFs = isTablet
        ? (sw * 0.02).clamp(14.0, 18.0)
        : (sw * 0.042).clamp(13.0, 17.0);

    return Container(
      padding:
          EdgeInsets.fromLTRB(panelPad, panelPad, panelPad, panelPad * 0.4),
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
                size: headerFs - 1,
                color: charcoalBlack.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatDate(dateKey)} 랭킹',
                style: GoogleFonts.blackHanSans(
                  fontSize: headerFs,
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
          SizedBox(height: panelPad * 0.85),
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
