import 'dart:async';
import '../background.dart';
import '../services/storage.dart';
import '../theme/theme.dart';
import '../widgets/chest_sprite.dart';
import 'open_chest_screen.dart';

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

  int get _filledCount => _slots.where((s) => s != null).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LivelyBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header Section ───────────────────────────────────────
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SGTouchable(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: AppTheme.line, width: 1),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Icon(Icons.chevron_left,
                                  color: AppTheme.text1, size: 24),
                            ),
                          ),
                          Text('INVENTORY', style: AppTheme.h1()),
                          Container(width: 48), // Spacer
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildCapacityBar(),
                    ],
                  ),
                ),
              ),
            ),

            // ── Inventory Grid ───────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildSlot(index),
                  childCount: _slots.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityBar() {
    final double progress = (_filledCount / Storage.maxSlots).clamp(0.0, 1.0);
    final bool isFull = _filledCount >= Storage.maxSlots;

    return SGCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 16, color: isFull ? AppTheme.red : AppTheme.accent),
                  const SizedBox(width: 8),
                  Text('STORAGE CAPACITY',
                      style: AppTheme.label(
                          color: isFull ? AppTheme.red : AppTheme.text1)),
                ],
              ),
              Text('$_filledCount / ${Storage.maxSlots}',
                  style: AppTheme.mono(
                      color: isFull ? AppTheme.red : AppTheme.accent,
                      size: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.black,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 8,
                width: MediaQuery.of(context).size.width * 0.75 * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFull
                        ? [AppTheme.red, const Color(0xFFFF5252)]
                        : [AppTheme.accent, AppTheme.accentDim],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: (isFull ? AppTheme.red : AppTheme.accent)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlot(int index) {
    final slot = _slots[index];

    if (slot == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppTheme.line.withValues(alpha: 0.5), width: 1),
        ),
        child: Center(
          child: Icon(Icons.add,
              color: AppTheme.line.withValues(alpha: 0.3), size: 24),
        ),
      );
    }

    final type = slot['type'] as String;
    final status = slot['status'] as String;
    final spriteType = type == 'wooden_chest' ? 'wooden' : 'iron';
    final isWooden = type == 'wooden_chest';

    final Color rarityColor = isWooden ? AppTheme.amber : AppTheme.cyan;
    final Color glowColor = rarityColor.withValues(alpha: 0.15);

    return SGTouchable(
      onTap: () {
        if (status == 'locked') {
          _showUnlockDialog(index, type);
        } else if (status == 'unlocking') {
          final skipCost = type == 'wooden_chest' ? 50 : 100;
          _showSkipDialog(index, type, skipCost);
        } else {
          _openChest(index, type);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: AppTheme.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: status == 'ready'
                  ? AppTheme.green
                  : rarityColor.withValues(alpha: 0.4),
              width: 1),
          boxShadow: [
            if (status == 'ready')
              BoxShadow(
                  color: AppTheme.green.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 2)
            else
              BoxShadow(color: glowColor, blurRadius: 10, spreadRadius: -2),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: rarityColor.withValues(alpha: 0.1),
                        blurRadius: 25,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Hero(
                  tag: 'chest_$index',
                  child: ChestSprite(
                    chestType: spriteType,
                    animation: 'Idle',
                    fps: status == 'ready' ? 12 : 8,
                    size: 60,
                  ),
                ),
              ),
            ),
            if (status == 'locked')
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.lock_outline, size: 12, color: AppTheme.text2),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSlotFooter(status, index, type),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotFooter(String status, int index, String type) {
    if (status == 'ready') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: const BoxDecoration(
          color: AppTheme.green,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(17)),
        ),
        child: Center(
          child: Text('OPEN',
              style: AppTheme.mono(color: Colors.black, size: 10)
                  .copyWith(fontWeight: FontWeight.w900)),
        ),
      );
    }

    if (status == 'unlocking') {
      final remaining = Storage.getRemainingUnlockTime(index);
      final timeStr = _formatDuration(remaining);

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.black.withValues(alpha: 0.7),
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(17)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 10, color: AppTheme.amber),
            const SizedBox(width: 4),
            Text(timeStr, style: AppTheme.mono(color: AppTheme.amber, size: 9)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.black.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
      ),
      child: Center(
        child: Text(
          type == 'wooden_chest' ? 'WOODEN' : 'IRON',
          style: AppTheme.caption(color: AppTheme.text2).copyWith(
              fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }

  void _showUnlockDialog(int index, String chestType) {
    final isWooden = chestType == 'wooden_chest';
    final duration = isWooden ? '2h' : '4h';
    final skipCost = isWooden ? 50 : 100;

    showDialog(
      context: context,
      builder: (ctx) => _GameDialog(
        title: 'UNEARTHED CHEST',
        child: Column(
          children: [
            ChestSprite(
                chestType: isWooden ? 'wooden' : 'iron',
                animation: 'Idle',
                size: 100),
            const SizedBox(height: 16),
            Text(isWooden ? 'WOODEN CHEST' : 'IRON CHEST',
                style: AppTheme.h2(
                    color: isWooden ? AppTheme.amber : AppTheme.cyan)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDialogStat(
                    Icons.timer_outlined, 'TIME', duration, AppTheme.amber),
                const SizedBox(width: 24),
                _buildDialogStat(
                    Icons.auto_awesome, 'LOOT', 'RANDOM', AppTheme.accent),
              ],
            ),
            const SizedBox(height: 32),
            SGButton(
              label: 'START UNLOCKING',
              icon: Icons.vpn_key_outlined,
              onTap: () {
                Storage.startUnlocking(index);
                Navigator.pop(ctx);
                _load();
              },
            ),
            const SizedBox(height: 12),
            SGButton(
              label: 'SKIP FOR $skipCost',
              icon: Icons.bolt,
              outlined: true,
              onTap: () {
                Navigator.pop(ctx);
                _showSkipDialog(index, chestType, skipCost);
              },
            ),
          ],
        ),
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

  Widget _buildDialogStat(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(label, style: AppTheme.caption()),
        Text(value, style: AppTheme.mono(color: color, size: 14)),
      ],
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
          border: Border.all(color: AppTheme.line, width: 1),
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
