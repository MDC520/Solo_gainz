import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/user_stats.dart';
import '../services/storage.dart';
import '../theme/theme.dart';
import '../widgets/rank_shield.dart';
import 'achievement_screen.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  UserStats? _s;
  ValueListenable<Box>? _statsListenable;

  @override
  void initState() {
    super.initState();
    _load();
    _statsListenable = Storage.watch(Storage.userStatsKey);
    _statsListenable?.addListener(_load);
  }

  @override
  void dispose() {
    _statsListenable?.removeListener(_load);
    super.dispose();
  }

  void _load() {
    try {
      if (mounted) setState(() => _s = Storage.getUserStats());
    } catch (e) {
      debugPrint('Stats load error: $e');
    }
  }

  int get _xpNeed => RankSystem.getXpNeededForNextLevel(_s?.rank ?? 'E');
  int get _maxLvl => RankSystem.rankMaxLevel[_s?.rank ?? 'E'] ?? 8;
  bool get _isMax => _s?.rank == 'SG' && (_s?.level ?? 1) == _maxLvl;
  String get _next =>
      RankSystem.getNextRank(_s?.rank ?? 'E') ?? (_s?.rank ?? 'E');

  @override
  Widget build(BuildContext context) {
    if (_s == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final s = _s!;
    final xpPct = (s.xp / _xpNeed).clamp(0.0, 1.0);

    return CustomScrollView(
      physics: ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // Standardized Header matching Shop/Profile
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Statistics', style: AppTheme.h2()),
                          const SizedBox(height: 4),
                          Text('Your performance and rank progress.',
                              style: AppTheme.caption()),
                        ],
                      ),
                      Row(
                        children: [
                          // Achievement Button
                          SGTouchable(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AchievementScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: AppTheme.line, width: 1.5),
                              ),
                              child: const Icon(Icons.workspace_premium,
                                  color: AppTheme.amber, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Level badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      AppTheme.accent.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'LVL ${s.level}',
                              style: AppTheme.label(color: AppTheme.accent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Rank Hero Section ──────────────────────────────
              SGCard(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: Column(
                  children: [
                    // Rank Shield Display
                    RankShield(rank: s.rank, size: 160),
                    const SizedBox(height: 16),
                    Text(
                      'RANK ${s.rank}',
                      style: AppTheme.h1().copyWith(
                        fontSize: 32,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      _isMax
                          ? 'SUPREME GUARDIAN'
                          : 'Ascending through rank ${s.rank}',
                      style: AppTheme.caption(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── XP Progression ──────────────────────────────
              const SGSectionHeader(title: 'EXPERIENCE'),
              SGCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rank Progress', style: AppTheme.h3()),
                            Text(
                                'LVL ${s.level} ➔ ${s.level == _maxLvl ? _next : "LVL ${s.level + 1}"}',
                                style: AppTheme.caption()),
                          ],
                        ),
                        Text(
                          '${(xpPct * 100).toInt()}%',
                          style: AppTheme.mono(color: AppTheme.amber, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _XPRoad(progress: xpPct),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${s.xp} XP',
                            style: AppTheme.label(color: AppTheme.text1)),
                        Text('$_xpNeed XP NEXT',
                            style: AppTheme.caption(color: AppTheme.text2)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Lifetime Breakdown ──────────────────────────────
              const SGSectionHeader(title: 'LIFETIME BREAKDOWN'),
              SGCard(
                child: s.lifetimeStats.isEmpty
                    ? Center(
                        child: Text('No exercises logged yet',
                            style: AppTheme.caption()))
                    : Column(
                        children: s.lifetimeStats.entries.map((e) {
                          if (e.key == 'total_completed') {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key.replaceFirst('_', ' ').toUpperCase(),
                                    style: AppTheme.label()),
                                Text('${e.value}',
                                    style: AppTheme.mono(
                                        color: AppTheme.accent, size: 14)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 32),

              // ── Progression Roadmap ──────────────────────────────
              const SGSectionHeader(title: 'ROAD TO SUPREME'),
              _TimelineItem(
                title: 'Current Rank: ${s.rank}',
                subtitle: 'Achieved Level ${s.level} of $_maxLvl',
                isCurrent: true,
                isFirst: true,
              ),
              _TimelineItem(
                title: 'Next Promotion: ${_isMax ? "GOD MODE" : _next}',
                subtitle: _isMax
                    ? 'Supreme status unlocked.'
                    : 'Requires Completion of Rank ${s.rank}',
                isLast: true,
                isLocked: !_isMax,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _XPRoad extends StatelessWidget {
  final double progress;
  const _XPRoad({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.line, width: 1.5),
      ),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (ctx, constraints) => AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: SGCurves.easeOutQuart,
              width: constraints.maxWidth * progress,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.amber, Color(0xFFFFD700)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.amber.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCurrent;
  final bool isLocked;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    this.isCurrent = false,
    this.isLocked = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? AppTheme.accent
                    : (isLocked ? AppTheme.line : AppTheme.green),
                border: Border.all(
                  color: isCurrent
                      ? AppTheme.white.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppTheme.line,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.label(
                    color: isCurrent
                        ? AppTheme.accent
                        : (isLocked ? AppTheme.text2 : AppTheme.text1)),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTheme.caption()),
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
