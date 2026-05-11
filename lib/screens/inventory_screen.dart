import 'dart:async';
import '../services/storage.dart';
import '../theme/theme.dart';
import '../main.dart';
import '../widgets/chest_sprite.dart';
import 'open_chest_screen.dart';
import '../background.dart';

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
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        Storage.refreshInventoryStatuses();
        setState(() => _slots = Storage.getInventorySlots());
      }
    });
  }

  void _load() {
    Storage.refreshInventoryStatuses();
    setState(() => _slots = Storage.getInventorySlots());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LivelyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        body: Stack(
          children: [
            CustomScrollView(
              physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vault'.toUpperCase(), style: AppTheme.h1(color: AppTheme.white).copyWith(letterSpacing: 2)),
                              Text('Secure storage for your gains', style: AppTheme.caption(color: AppTheme.text2)),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.glassBorder, width: 1.5),
                              ),
                              child: Icon(Icons.close, size: 20, color: AppTheme.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildBench(index * 4),
                      childCount: 4,
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
      padding: const EdgeInsets.only(bottom: 30),
      child: SizedBox(
        height: 140, 
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 0,
              left: -15,
              right: -15,
              child: Column(
                children: [
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.accent.withValues(alpha: 0.1),
                          AppTheme.glassBorder,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.glassBorder.withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 118,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(4, (i) {
                  final idx = startIndex + i;
                  if (idx >= _slots.length) return const Expanded(child: SizedBox());
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
      return GestureDetector(
        onTap: () {
          AppShell.navigateTo(3); 
          Navigator.pop(context); 
        },
        child: Opacity(
          opacity: 0.15,
          child: Container(
            height: 104,
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 25),
            child: Icon(Icons.add_circle_outline, color: AppTheme.text3, size: 22),
          ),
        ),
      );
    }

    final type = slot['type'] as String;
    final status = slot['status'] as String;
    final spriteType = type == 'wooden_chest' ? 'wooden' : type == 'iron_chest' ? 'iron' : 'gold';

    return SGTouchable(
      onTap: () {
        if (status == 'locked') {
          _showUnlockDialog(index, type);
        } else if (status == 'unlocking') {
          final skipCost = type == 'wooden_chest' ? 50 : type == 'iron_chest' ? 100 : 300;
          _showSkipDialog(index, type, skipCost);
        } else {
          _openChest(index, type);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 20,
            child: Center(
              child: _buildSlotFooter(status, index, type),
            ),
          ),
          const SizedBox(height: 6),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 0,
                child: Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: const BorderRadius.all(Radius.elliptical(40, 6)),
                  ),
                ),
              ),
              Hero(
                tag: 'chest_$index',
                child: ChestSprite(
                  chestType: spriteType,
                  animation: 'Idle',
                  fps: status == 'ready' ? 12 : 8,
                  size: 78,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlotFooter(String status, int index, String type) {
    final isUnlocking = status == 'unlocking';
    final isReady = status == 'ready';

    if (isReady) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.cyan.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.3), blurRadius: 8),
          ],
        ),
        child: Text('COLLECT',
            style: AppTheme.label(color: Colors.white).copyWith(fontSize: 9)),
      );
    }

    String timeStr = "";
    if (isUnlocking) {
      final remaining = Storage.getRemainingUnlockTime(index);
      timeStr = _formatDuration(remaining);
    } else {
      timeStr = type == 'wooden_chest' ? '2h 00m' : type == 'iron_chest' ? '4h 00m' : '8h 00m';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocking ? AppTheme.amber : AppTheme.glassBorder, 
          width: 1.5
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUnlocking ? Icons.timer : Icons.lock_outline, 
            size: 11, 
            color: isUnlocking ? AppTheme.amber : AppTheme.text3
          ),
          const SizedBox(width: 5),
          Text(
            timeStr, 
            style: AppTheme.mono(
              color: isUnlocking ? AppTheme.amber : AppTheme.text3, 
              size: 10
            )
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
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
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  void _showSkipDialog(int index, String chestType, int skipCost) {
    final stats = Storage.getUserStats();
    final hasCoins = stats.coins >= skipCost;

    showDialog(
      context: context,
      builder: (ctx) => _GameDialog(
        title: 'INSTANT UNLOCK',
        child: Column(
          children: [
            Icon(Icons.bolt, color: AppTheme.amber, size: 64),
            const SizedBox(height: 16),
            Text('SPEED UP PROCESS?', style: AppTheme.h2()),
            const SizedBox(height: 12),
            Text(
              'Sacrifice $skipCost T coins to instantly\nreveal the treasures within.',
              textAlign: TextAlign.center,
              style: AppTheme.body(),
            ),
            const SizedBox(height: 24),
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
                      Navigator.pop(ctx);
                      _load();
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            SGButton(
              label: 'WAIT IT OUT',
              outlined: true,
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _openChest(int index, String chestType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OpenChestScreen(slotIndex: index, chestType: chestType),
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
    _filledSegments = isWooden ? 1 : isIron ? 3 : 5;
    _name = isWooden ? 'Wooden Chest' : isIron ? 'Iron Chest' : 'Gold Chest';
    _duration = isWooden ? '2h' : isIron ? '4h' : '8h';
    _animateSegments();
  }

  void _animateSegments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (int i = 1; i <= _filledSegments; i++) {
      await Future.delayed(const Duration(milliseconds: 180));
      if (mounted) setState(() => _visibleSegments = i);
    }
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

          Center(
            child: Column(
              children: [
                Text(
                  _name.toUpperCase(),
                  style: AppTheme.h1().copyWith(color: AppTheme.white, letterSpacing: 2),
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
                  Text('UNLOCK TIME', style: AppTheme.caption().copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: AppTheme.amber),
                      const SizedBox(width: 6),
                      Text(_duration, style: AppTheme.mono(color: AppTheme.amber, size: 18).copyWith(fontWeight: FontWeight.w900)),
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
                      Text('LOOT TIER', style: AppTheme.caption().copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_downward, size: 12, color: AppTheme.text2.withValues(alpha: 0.5)),
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
              border: Border.all(color: AppTheme.line, width: 1.5),
            ),
            child: Row(
              children: List.generate(5, (i) {
                final isLit = i < _visibleSegments;
                final color = _segmentColors[i];
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    margin: EdgeInsets.only(right: i < 4 ? 3 : 0),
                    decoration: BoxDecoration(
                      color: isLit ? color : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: isLit ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ] : null,
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
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
          ),
        ),
      ],
    );
  }
}

class _GameDialog extends StatelessWidget {
  final String title;
  final Widget child;

  const _GameDialog({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.line, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: 5)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: AppTheme.label(color: AppTheme.accent)
                    .copyWith(letterSpacing: 3)),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
