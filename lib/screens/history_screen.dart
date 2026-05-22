import '../models/storage.dart';
import '../ui/theme.dart';
import '../widgets/background.dart';
import 'home_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late int _maxWeeks;
  late int _todayIndex;
  late int _currentSundayIndex;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    final todayWeekday = _now.weekday;
    _todayIndex = todayWeekday == 7 ? 0 : todayWeekday;

    final joinDateStr = Storage.getData('join_date');
    DateTime joinDate;
    if (joinDateStr != null) {
      joinDate = DateTime.parse(joinDateStr);
    } else {
      joinDate = _now;
    }

    final joinWeekday = joinDate.weekday;
    final joinSundayIndex = joinWeekday == 7 ? 0 : joinWeekday;
    final joinSunday = DateTime(joinDate.year, joinDate.month, joinDate.day)
        .subtract(Duration(days: joinSundayIndex));

    _currentSundayIndex = todayWeekday == 7 ? 0 : todayWeekday;
    final todaySunday = DateTime(_now.year, _now.month, _now.day)
        .subtract(Duration(days: _currentSundayIndex));

    final diffDays = todaySunday.difference(joinSunday).inDays;
    final int weeksPassed = (diffDays / 7).round();
    _maxWeeks = weeksPassed < 0 ? 0 : weeksPassed;
  }

  DateTime _dateForIndex(int idx, int weekOffset) {
    final todayStart = DateTime(_now.year, _now.month, _now.day);
    return todayStart
        .subtract(Duration(days: _currentSundayIndex + (weekOffset * 7)))
        .add(Duration(days: idx));
  }

  String _getDayLetter(int idx) {
    switch (idx) {
      case 0: return 'S';
      case 1: return 'M';
      case 2: return 'T';
      case 3: return 'W';
      case 4: return 'T';
      case 5: return 'F';
      case 6: return 'S';
      default: return '';
    }
  }

  String _getDayName(int idx) {
    switch (idx) {
      case 0: return 'Sunday';
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      default: return '';
    }
  }

  double _getQuestProgress(int idx, int weekOffset) {
    final date = _dateForIndex(idx, weekOffset);
    final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    if (weekOffset == 0 && idx == _todayIndex) {
      final quests = Storage.getDailyQuests();
      final total = quests.length;
      final completed = quests.where((q) => q.completed).length;
      return total > 0 ? (completed.toDouble() / total.toDouble()) : 0.0;
    }

    final history = Map<String, bool>.from(Storage.getData('quest_completion_history') ?? {});
    final completed = history[key] ?? false;
    return completed ? 1.0 : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return LivelyBackground(
      mode: LivelyBackgroundMode.wood,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: Responsive.fromLTRB(20, 16, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('History'.toUpperCase(),
                            style: AppTheme.h1(color: AppTheme.white)
                                .copyWith(letterSpacing: 2)),
                        Text('Your legacy of gainz',
                            style: AppTheme.caption(color: AppTheme.text2)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: Responsive.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.glassBorder, width: Responsive.dp(1.5)),
                        ),
                        child: Icon(Icons.close,
                            size: Responsive.icon(20), color: AppTheme.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: Responsive.fromLTRB(20, 0, 20, 40),
                itemCount: _maxWeeks + 1,
                itemBuilder: (context, index) {
                  final weekOffset = index; // 0 is current week, 1 is last week, etc.
                  return Padding(
                    padding: EdgeInsets.only(bottom: Responsive.h(20)),
                    child: _buildWeekCard(weekOffset),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekCard(int weekOffset) {
    final days = [0, 1, 2, 3, 4, 5, 6];
    
    // Calculate start and end date of this week
    final startDate = _dateForIndex(0, weekOffset);
    final endDate = _dateForIndex(6, weekOffset);
    final isCurrentWeek = weekOffset == 0;
    
    final String dateRange = "${startDate.month}/${startDate.day} - ${endDate.month}/${endDate.day}";

    return Container(
      padding: Responsive.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        border: Border.all(color: AppTheme.line, width: Responsive.dp(1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCurrentWeek ? 'CURRENT WEEK' : 'WEEK OF $dateRange',
                style: AppTheme.label().copyWith(
                  color: AppTheme.text2,
                  fontSize: Responsive.sp(11),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              if (isCurrentWeek)
                Container(
                  width: Responsive.h(8),
                  height: Responsive.h(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          SizedBox(height: Responsive.h(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: days.map((d) {
              final isToday = (weekOffset == 0) && (d == _todayIndex);
              final isFuture = (weekOffset == 0) && (d > _todayIndex);
              final double progress = _getQuestProgress(d, weekOffset);
              final completed = progress >= 1.0;
              final letter = _getDayLetter(d);
              final name = _getDayName(d);

              Color borderColor;
              Color backgroundColor;
              Color textColor;

              if (isToday) {
                if (completed) {
                  borderColor = AppTheme.green;
                  backgroundColor = AppTheme.green.withValues(alpha: 0.18);
                } else {
                  borderColor = Colors.blue;
                  backgroundColor = Colors.blue.withValues(alpha: 0.15);
                }
                textColor = AppTheme.accent;
              } else if (isFuture) {
                borderColor = AppTheme.line.withValues(alpha: 0.25);
                backgroundColor = AppTheme.surface.withValues(alpha: 0.2);
                textColor = AppTheme.text2.withValues(alpha: 0.5);
              } else {
                if (completed) {
                  borderColor = AppTheme.green.withValues(alpha: 0.6);
                  backgroundColor = AppTheme.surface.withValues(alpha: 0.4);
                } else {
                  borderColor = AppTheme.red.withValues(alpha: 0.4);
                  backgroundColor = AppTheme.surface.withValues(alpha: 0.4);
                }
                textColor = AppTheme.text2.withValues(alpha: 0.8);
              }

              return Tooltip(
                message: '$name: ${completed ? "Completed" : "Not Completed"}',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  width: isToday ? Responsive.h(44) : Responsive.h(34),
                  height: isToday ? Responsive.h(44) : Responsive.h(34),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(Responsive.r(10)),
                  ),
                  child: CustomPaint(
                    painter: ProgressSquarePainter(
                      progress: progress,
                      progressColor: AppTheme.green,
                      backgroundColor: borderColor,
                      strokeWidth: isToday ? Responsive.dp(2.5) : Responsive.dp(1.5),
                      borderRadius: Responsive.r(10),
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: AppTheme.h3().copyWith(
                          fontWeight: isToday ? FontWeight.w900 : FontWeight.bold,
                          fontSize: isToday ? Responsive.sp(16) : Responsive.sp(13),
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
