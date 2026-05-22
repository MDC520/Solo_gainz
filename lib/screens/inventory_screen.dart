import 'dart:async';
import '../models/storage.dart';
import '../services/notifications.dart';
import '../ui/theme.dart';
import '../widgets/background.dart';
import '../widgets/chest.dart';
import '../main.dart';
import 'history_screen.dart';
import 'open_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>?> _slots = [];
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (mounted) {
        await Storage.refreshInventoryStatuses();
        if (mounted) setState(() => _slots = Storage.getInventorySlots());
      }
    });
  }

  Future<void> _load() async {
    await Storage.refreshInventoryStatuses();
    if (mounted) setState(() => _slots = Storage.getInventorySlots());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LivelyBackground(
      mode: LivelyBackgroundMode.wood,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const ClampingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: Responsive.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vault'.toUpperCase(),
                                  style: AppTheme.h1(color: AppTheme.white)
                                      .copyWith(letterSpacing: 2)),
                              Text('Secure storage for your gains',
                                  style:
                                      AppTheme.caption(color: AppTheme.text2)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                                child: Container(
                                  padding: Responsive.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppTheme.glassBorder, width: 1.5),
                                  ),
                                  child: Icon(Icons.history,
                                      size: Responsive.icon(20), color: AppTheme.white),
                                ),
                              ),
                              SizedBox(width: Responsive.w(12)),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: Responsive.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppTheme.glassBorder, width: 1.5),
                                  ),
                                  child: Icon(Icons.close,
                                      size: Responsive.icon(20), color: AppTheme.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: Responsive.fromLTRB(20, 40, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildBench(index * 4),
                      childCount: (Storage.maxSlots / 4).ceil(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBench(int startIndex) {
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.h(30)),
      child: SizedBox(
        height: Responsive.h(140),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 0,
              left: -Responsive.w(15),
              right: -Responsive.w(15),
              child: Container(
                height: Responsive.h(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFF94A3B8),
                      AppTheme.isDark
                          ? const Color(0xFF1F2937)
                          : const Color(0xFF475569),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.isDark
                        ? Colors.black
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: const [],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: Responsive.h(28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(4, (i) {
                  final idx = startIndex + i;
                  if (idx >= _slots.length) {
                    return const Expanded(child: SizedBox());
                  }
                  return Expanded(child: _buildBenchSlot(idx));
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchSlot(int index) {
    final slot = _slots[index];

    if (slot == null) {
      return DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != index,
        onAcceptWithDetails: (details) => _onMove(details.data, index),
        builder: (context, candidateData, rejectedData) {
          return GestureDetector(
            onTap: () {
              AppShell.navigateTo(3);
              Navigator.pop(context);
            },
            child: Opacity(
              opacity: 0.15,
              child: Container(
                alignment: Alignment.bottomCenter,
                padding: EdgeInsets.only(bottom: Responsive.h(25)),
                child: Icon(Icons.add_circle_outline,
                    color: AppTheme.text1, size: Responsive.icon(30)),
              ),
            ),
          );
        },
      );
    }

    final type = slot['type'] as String;
    final status = slot['status'] as String;
    final spriteType = type == 'wooden_chest'
        ? 'wooden'
        : type == 'iron_chest'
            ? 'iron'
            : type == 'gold_chest'
                ? 'gold'
                : 'mysterious';

    return LongPressDraggable<int>(
      data: index,
      delay: const Duration(milliseconds: 600),
      feedback: _ShakingChest(spriteType: spriteType),
      childWhenDragging: Opacity(
          opacity: 0.3, child: _buildSlotUI(index, type, status, spriteType)),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) => details.data != index,
        onAcceptWithDetails: (details) => _onMove(details.data, index),
        builder: (context, candidate, rejected) {
          return SGTouchable(
            onTap: () {
              if (status == 'locked') {
                _showUnlockDialog(index, type);
              } else if (status == 'unlocking') {
                final skipCost = type == 'wooden_chest'
                    ? 250
                    : type == 'iron_chest'
                        ? 500
                        : type == 'gold_chest'
                            ? 1500
                            : 3000;
                _showSkipDialog(index, type, skipCost);
              } else {
                _openChest(index, type);
              }
            },
            child: _buildSlotUI(index, type, status, spriteType),
          );
        },
      ),
    );
  }

  Widget _buildSlotUI(
      int index, String type, String status, String spriteType) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: Responsive.h(28),
          child: Center(
            child: _buildSlotFooter(status, index, type),
          ),
        ),
        SizedBox(height: Responsive.h(6)),
        Hero(
          tag: 'chest_$index',
          child: ChestSprite(
            chestType: spriteType,
            animation: 'Idle',
            fps: 8,
            size: 78, // Already scaled inside ChestSprite based on size parameter
          ),
        ),
      ],
    );
  }

  void _onMove(int from, int to) {
    final slots = Storage.getInventorySlots();
    final item = slots[from];
    slots[from] = slots[to];
    slots[to] = item;
    Storage.saveInventorySlots(slots);
    _load();
    HapticFeedback.mediumImpact();
  }

  Widget _buildSlotFooter(String status, int index, String type) {
    final isReady = status == 'ready';
    final isUnlocking = status == 'unlocking';

    if (isReady) {
      return Container(
        padding: Responsive.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.cyan.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(Responsive.r(4)),
          boxShadow: [
            BoxShadow(
                color: AppTheme.cyan.withValues(alpha: 0.3), blurRadius: 8),
          ],
        ),
        child: Text('READY',
            style: AppTheme.label(color: Colors.white).copyWith(fontSize: Responsive.sp(9))),
      );
    }

    String timeStr = "";
    if (isUnlocking) {
      final remaining = Storage.getRemainingUnlockTime(index);
      timeStr = _formatDuration(remaining);
    } else {
      timeStr = type == 'wooden_chest'
          ? '2h 00m'
          : type == 'iron_chest'
              ? '4h 00m'
              : type == 'gold_chest'
                  ? '8h 00m'
                  : '12h 00m';
    }

    return Container(
      padding: Responsive.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            AppTheme.isDark ? const Color(0xFF0A0A0A) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(Responsive.r(4)),
        border: Border.all(
            color: isUnlocking
                ? AppTheme.amber
                : (AppTheme.isDark
                    ? AppTheme.glassBorder
                    : Colors.white.withValues(alpha: 0.2)),
            width: Responsive.dp(1.5)),
      ),
      child: Text(timeStr,
          style: AppTheme.mono(
                  color: isUnlocking
                      ? AppTheme.amber
                      : AppTheme.text3,
                  size: 11)
              .copyWith(fontWeight: FontWeight.w900)),
    );
  }

  String _formatDuration(Duration d) {
    String h = d.inHours.toString().padLeft(2, '0');
    String m = (d.inMinutes % 60).toString().padLeft(2, '0');
    String s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _showUnlockDialog(int index, String chestType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ChestUnlockSheet(
        chestType: chestType,
        onUnlock: () {
          Storage.startUnlocking(index);
          final duration = Storage.getUnlockDuration(chestType);
          NotificationService.scheduleChestUnlock(index, chestType, duration);
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  void _showSkipDialog(int index, String chestType, int skipCost) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ChestSkipSheet(
        index: index,
        chestType: chestType,
        skipCost: skipCost,
        onDone: () => _load(),
      ),
    );
  }

  void _openChest(int index, String chestType) {
    NotificationService.cancelChestUnlock(index);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OpenScreen(slotIndex: index, chestType: chestType),
      ),
    ).then((_) => _load());
  }
}

class _ChestUnlockSheet extends StatefulWidget {
  final String chestType;
  final VoidCallback onUnlock;
  const _ChestUnlockSheet({required this.chestType, required this.onUnlock});

  @override
  State<_ChestUnlockSheet> createState() => _ChestUnlockSheetState();
}

class _ChestUnlockSheetState extends State<_ChestUnlockSheet> {
  int _visibleSegments = 0;
  bool _showInfo = false; // Toggle for complex gacha gacha info split-screen view

  static const _segmentColors = [
    Color(0xFFE53935),
    Color(0xFFFF7043),
    Color(0xFFFFD600),
    Color(0xFF76FF03),
    Color(0xFF00E676),
  ];

  late int _filledSegments;
  late String _name;
  late String _duration;

  @override
  void initState() {
    super.initState();
    final isWooden = widget.chestType == 'wooden_chest';
    final isIron = widget.chestType == 'iron_chest';
    final isGold = widget.chestType == 'gold_chest';
    _filledSegments = isWooden
        ? 1
        : isIron
            ? 3
            : isGold
                ? 4
                : 5;
    _name = isWooden
        ? 'Wooden Chest'
        : isIron
            ? 'Iron Chest'
            : isGold
                ? 'Gold Chest'
                : 'What a Chest';
    _duration = isWooden
        ? '02:00:00'
        : isIron
            ? '04:00:00'
            : isGold
                ? '08:00:00'
                : '12:00:00';
    _animateSegments();
  }

  void _animateSegments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (int i = 1; i <= _filledSegments; i++) {
      await Future.delayed(const Duration(milliseconds: 180));
      if (mounted) setState(() => _visibleSegments = i);
    }
  }

  Map<String, List<Map<String, dynamic>>> get _gachaData {
    return {
      'wooden_chest': [
        {'name': 'Troll Loot (Unlucky)', 'chance': '5%', 'range': '\$2 - \$10', 'color': const Color(0xFFEF5350)},
        {'name': 'Common Loot', 'chance': '65%', 'range': '\$25 - \$60', 'color': const Color(0xFF94A3B8)},
        {'name': 'Rare Hoard', 'chance': '20%', 'range': '\$65 - \$110', 'color': const Color(0xFF00E5FF)},
        {'name': 'Epic Artifact', 'chance': '9%', 'range': '\$120 - \$200', 'color': const Color(0xFFD500F9)},
        {'name': '★ JACKPOT ★', 'chance': '1%', 'range': '\$350', 'color': const Color(0xFFFFD600)},
      ],
      'iron_chest': [
        {'name': 'Troll Loot (Unlucky)', 'chance': '5%', 'range': '\$15 - \$40', 'color': const Color(0xFFEF5350)},
        {'name': 'Common Loot', 'chance': '60%', 'range': '\$70 - \$130', 'color': const Color(0xFF94A3B8)},
        {'name': 'Rare Hoard', 'chance': '23%', 'range': '\$140 - \$220', 'color': const Color(0xFF00E5FF)},
        {'name': 'Epic Artifact', 'chance': '10%', 'range': '\$230 - \$380', 'color': const Color(0xFFD500F9)},
        {'name': '★ JACKPOT ★', 'chance': '2%', 'range': '\$600', 'color': const Color(0xFFFFD600)},
      ],
      'gold_chest': [
        {'name': 'Troll Loot (Unlucky)', 'chance': '5%', 'range': '\$50 - \$120', 'color': const Color(0xFFEF5350)},
        {'name': 'Common Loot', 'chance': '55%', 'range': '\$220 - \$380', 'color': const Color(0xFF94A3B8)},
        {'name': 'Rare Hoard', 'chance': '25%', 'range': '\$400 - \$650', 'color': const Color(0xFF00E5FF)},
        {'name': 'Epic Artifact', 'chance': '12%', 'range': '\$700 - \$1100', 'color': const Color(0xFFD500F9)},
        {'name': '★ JACKPOT ★', 'chance': '3%', 'range': '\$2000', 'color': const Color(0xFFFFD600)},
      ],
      'mysterious_chest': [
        {'name': 'Troll Loot (Unlucky)', 'chance': '5%', 'range': '\$150 - \$350', 'color': const Color(0xFFEF5350)},
        {'name': 'Common Loot', 'chance': '50%', 'range': '\$500 - \$850', 'color': const Color(0xFF94A3B8)},
        {'name': 'Rare Hoard', 'chance': '27%', 'range': '\$900 - \$1400', 'color': const Color(0xFF00E5FF)},
        {'name': 'Epic Artifact', 'chance': '14%', 'range': '\$1500 - \$2500', 'color': const Color(0xFFD500F9)},
        {'name': '★ JACKPOT ★', 'chance': '4%', 'range': '\$5000', 'color': const Color(0xFFFFD600)},
      ],
    };
  }

  Widget _buildComplexInfoView() {
    final list = _gachaData[widget.chestType] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GACHA PROBABILITIES',
                  style: AppTheme.caption(color: AppTheme.accent).copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_name Odds & Ranges',
                  style: AppTheme.h2().copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => setState(() => _showInfo = false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.line, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, size: 14, color: AppTheme.text2),
                    const SizedBox(width: 6),
                    Text(
                      'BACK',
                      style: AppTheme.label(color: AppTheme.text1).copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.line, width: 1.2),
          ),
          child: Column(
            children: [
              for (int i = 0; i < list.length; i++) ...[
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: list[i]['color'] as Color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        list[i]['name'] as String,
                        style: AppTheme.body().copyWith(
                          fontWeight: FontWeight.bold,
                          color: list[i]['color'] as Color,
                        ),
                      ),
                    ),
                    Text(
                      list[i]['range'] as String,
                      style: AppTheme.mono(color: AppTheme.text1, size: 13),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 52,
                      alignment: Alignment.centerRight,
                      child: Text(
                        list[i]['chance'] as String,
                        style: AppTheme.mono(color: AppTheme.accent, size: 13).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (i < list.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: AppTheme.line.withValues(alpha: 0.5), height: 1, thickness: 1),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.line.withValues(alpha: 0.5), width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.casino_outlined, color: AppTheme.amber, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Rewards are calculated via server-grade gacha rolls. Best of luck!',
                  style: AppTheme.caption(color: AppTheme.text2).copyWith(fontSize: 10.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildStandardUnlockView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                _name.toUpperCase(),
                style: AppTheme.h1()
                    .copyWith(color: AppTheme.white, letterSpacing: 2),
              ),
              const SizedBox(height: 6),
              Text(
                'A rare find from the depths of the dungeon.',
                style: AppTheme.caption(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UNLOCK TIME',
                    style: AppTheme.caption()
                        .copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 16, color: AppTheme.amber),
                    const SizedBox(width: 6),
                    Text(_duration,
                        style: AppTheme.mono(color: AppTheme.amber, size: 18)
                            .copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() => _showInfo = true),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface,
                          border: Border.all(color: AppTheme.line, width: 1.2),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LOOT TIER',
                      style: AppTheme.caption().copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_downward,
                      size: 12,
                      color: AppTheme.text2.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBattery(),
        const SizedBox(height: 40),
        SGButton(
          label: 'START UNLOCKING',
          icon: Icons.vpn_key_outlined,
          onTap: widget.onUnlock,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppTheme.line, width: 1.5),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_showInfo)
              _buildComplexInfoView()
            else
              _buildStandardUnlockView(),
          ],
        ),
      ),
    );
  }

  Widget _buildBattery() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.line,
                width: 1.5,
              ),
            ),
            child: Row(
              children: List.generate(5, (i) {
                final isLit = i < _visibleSegments;
                final color = _segmentColors[i];
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350), // Snappy and ultra-smooth color cascade shift
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.only(right: i < 4 ? 3 : 0),
                    decoration: BoxDecoration(
                      color: isLit ? color : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: isLit
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.6),
                                blurRadius: 6, // Pulsing rich glow
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        Container(
          width: 5,
          height: 14,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: AppTheme.line,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(3)),
          ),
        ),
      ],
    );
  }
}

class _ChestSkipSheet extends StatelessWidget {
  final int index;
  final String chestType;
  final int skipCost;
  final VoidCallback onDone;

  const _ChestSkipSheet({
    required this.index,
    required this.chestType,
    required this.skipCost,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final stats = Storage.getUserStats();
    final hasCoins = stats.coins >= skipCost;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppTheme.line, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('INSTANT UNLOCK',
              style: AppTheme.h1().copyWith(letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(
            'Sacrifice $skipCost T coins to instantly\nreveal the treasures within.',
            textAlign: TextAlign.center,
            style: AppTheme.body(color: AppTheme.text2),
          ),
          const SizedBox(height: 32),
          SGButton(
            label: hasCoins ? 'PAY $skipCost COINS' : 'INSUFFICIENT FUNDS',
            icon: Icons.monetization_on_outlined,
            onTap: hasCoins
                ? () {
                    stats.coins -= skipCost;
                    Storage.saveUserStats(stats);
                    final slots = Storage.getInventorySlots();
                    if (index < slots.length && slots[index] != null) {
                      slots[index]!['status'] = 'ready';
                      Storage.saveInventorySlots(slots);
                    }
                    NotificationService.cancelChestUnlock(index);
                    Navigator.pop(context);
                    onDone();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _ShakingChest extends StatefulWidget {
  final String spriteType;
  const _ShakingChest({required this.spriteType});

  @override
  State<_ShakingChest> createState() => _ShakingChestState();
}

class _ShakingChestState extends State<_ShakingChest>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150))
      ..repeat(reverse: true);
    _shake = Tween<double>(begin: -0.05, end: 0.05)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          return Transform.rotate(
            angle: _shake.value,
            child: Transform.scale(
              scale: 1.2,
              child: child,
            ),
          );
        },
        child: ChestSprite(
          chestType: widget.spriteType,
          animation: 'Idle',
          fps: 12,
          size: 90,
        ),
      ),
    );
  }
}
