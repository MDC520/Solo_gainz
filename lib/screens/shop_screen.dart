import 'package:flutter/cupertino.dart';
import '../models/user_stats.dart';
import '../screens/buy_coins_screen.dart';
import '../services/storage.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/chest_sprite.dart';


class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late UserStats _s;
  int _tab = 0;
  int _woodenQty = 1;
  int _ironQty = 1;


  static const _tabs = ['Boosts', 'Premium', 'Cosmetics', 'Chests'];

  @override
  void initState() {
    super.initState();
    _s = Storage.getUserStats();
    _load();
  }

  void _load() => setState(() => _s = Storage.getUserStats());

  void _openBuyCoins() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BuyCoinsScreen()),
    ).then((value) {
      if (value != null) {
        _load();
      }
    });
  }



  // ── Chest Purchase Flow ──────────────────────────────────────
  void _buyChest(String chestType, String chestName, int unitPrice, int qty) {
    final totalPrice = unitPrice * qty;
    final availableSlots =
        Storage.getInventorySlots().where((s) => s == null).length;

    // 1. Check inventory space
    if (availableSlots < qty) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('Not Enough Space', style: AppTheme.h3()),
          content: Text(
            'You only have $availableSlots empty slots, but you want to buy $qty chests.',
            style: AppTheme.body(),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('OK', style: AppTheme.label(color: AppTheme.accent)),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Check coins
    if (_s.coins < totalPrice) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('Not enough coins', style: AppTheme.h3()),
          content: Text(
            'You need ${totalPrice - _s.coins} more T coins to buy $qty chests.',
            style: AppTheme.body(),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('OK', style: AppTheme.label(color: AppTheme.accent)),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return;
    }

    // 3. Confirmation popup
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Buy $chestName${qty > 1 ? " x$qty" : ""}',
            style: AppTheme.h3()),
        content: Text(
          'This will cost $totalPrice T coins.\nThe chest${qty > 1 ? "s" : ""} will be placed in your inventory.',
          style: AppTheme.body(),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: AppTheme.body(color: AppTheme.text2)),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child:
                Text('Purchase', style: AppTheme.label(color: AppTheme.accent)),
            onPressed: () async {
              // Deduct coins
              _s.coins -= totalPrice;
              await Storage.saveUserStats(_s);
              await AuthService().syncData();
              // Add chests to inventory
              for (int i = 0; i < qty; i++) {
                await Storage.addChestToInventory(chestType);
              }
              if (!context.mounted) return;
              Navigator.pop(ctx);
              _load();
              // Show chest arrival animation
              _showChestArrival(chestType, chestName, qty);
            },
          ),
        ],
      ),
    );
  }

  void _showChestArrival(String chestType, String chestName, int qty) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim, anim2) {
        return _ChestArrivalPopup(
          chestType: chestType,
          chestName: chestName,
          qty: qty,
          onDone: () => Navigator.pop(ctx),
        );
      },
      transitionBuilder: (ctx, anim, anim2, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isChestTab = _tab == 3;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
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
                          Text('Gear Shop', style: AppTheme.h1()),
                          const SizedBox(height: 4),
                          Text(
                            'Exchange coins for elite upgrades.',
                            style: AppTheme.caption(),
                          ),
                        ],
                      ),
                      // Balance chip
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.amber.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.generating_tokens_rounded,
                                  size: 16,
                                  color: AppTheme.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_s.coins}',
                                  style: AppTheme.label().copyWith(
                                    color: AppTheme.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _openBuyCoins,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.line,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Segment tabs
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.silver, width: 1.5),
                    ),
                    child: CupertinoSlidingSegmentedControl<int>(
                      backgroundColor: AppTheme.surface,
                      thumbColor: AppTheme.accent,
                      groupValue: _tab,
                      onValueChanged: (v) {
                        if (v != null) setState(() => _tab = v);
                      },
                      children: {
                        for (int i = 0; i < _tabs.length; i++)
                          i: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _tabs[i],
                              style: AppTheme.label(
                                color: _tab == i ? Colors.black : AppTheme.text2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isChestTab)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _chestCard(
                  chestType: 'wooden',
                  name: 'Wooden Chest',
                  desc: 'A sturdy wooden chest. Rewards 6–399 T coins. Rare drops above 100.',
                  price: 900,
                  qty: _woodenQty,
                  onQtyChanged: (v) => setState(() => _woodenQty = v),
                ),
                const SizedBox(height: 16),
                _chestCard(
                  chestType: 'iron',
                  name: 'Iron Chest',
                  desc: 'A reinforced iron chest. Rewards 6–399 T coins. Better drop rates.',
                  price: 1600,
                  qty: _ironQty,
                  onQtyChanged: (v) => setState(() => _ironQty = v),
                ),
              ]),
            ),
          )
        else
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 64,
                    color: AppTheme.text2.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'COMING SOON',
                    style: AppTheme.h2().copyWith(letterSpacing: 4, color: AppTheme.text2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The blacksmith is still forging these items.',
                    style: AppTheme.caption(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _chestCard({
    required String chestType,
    required String name,
    required String desc,
    required int price,
    required int qty,
    required ValueChanged<int> onQtyChanged,
  }) {
    final totalCost = price * qty;
    final canTotal = _s.coins >= totalCost;
    final chestTypeKey = chestType == 'wooden' ? 'wooden_chest' : 'iron_chest';
    final availableSlots = Storage.getInventorySlots().where((s) => s == null).length;

    return SGCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Chest Visual
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.glassMedium,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.line, width: 1),
                ),
                child: Center(
                  child: ChestSprite(
                    chestType: chestType,
                    animation: 'Idle',
                    fps: 8,
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name & Desc
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTheme.h3()),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: AppTheme.caption(),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Quantity Row (Wide Card)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.line, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('QUANTITY', style: AppTheme.label(color: AppTheme.text2)),
                Row(
                  children: [
                    _qtyBtn(
                      icon: Icons.remove,
                      onTap: qty > 1 ? () => onQtyChanged(qty - 1) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '$qty',
                        style: AppTheme.mono(size: 18, color: AppTheme.white)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _qtyBtn(
                      icon: Icons.add,
                      onTap: qty < availableSlots && qty < 99 ? () => onQtyChanged(qty + 1) : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Buy Button (Full Width)
          SGTouchable(
            onTap: () => _buyChest(chestTypeKey, name, price, qty),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: canTotal && availableSlots >= qty ? AppTheme.accent : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: canTotal && availableSlots >= qty ? null : Border.all(color: AppTheme.line, width: 1.5),
                boxShadow: canTotal && availableSlots >= qty
                    ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 10)]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    availableSlots == 0 ? 'INVENTORY FULL' : 'BUY FOR ',
                    style: AppTheme.label(color: canTotal && availableSlots >= qty ? Colors.black : AppTheme.muted),
                  ),
                  if (availableSlots > 0) ...[
                    Text(
                      '$totalCost',
                      style: AppTheme.mono(size: 14, color: canTotal && availableSlots >= qty ? Colors.black : AppTheme.muted)
                          .copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.generating_tokens_rounded,
                      size: 16,
                      color: canTotal && availableSlots >= qty ? Colors.black : AppTheme.muted,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, VoidCallback? onTap}) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: disabled ? Colors.transparent : AppTheme.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon,
            size: 14,
            color: disabled
                ? AppTheme.muted.withValues(alpha: 0.3)
                : AppTheme.white),
      ),
    );
  }
}

// ── Chest Arrival Animation Popup ──────────────────────────────
class _ChestArrivalPopup extends StatefulWidget {
  final String chestType;
  final String chestName;
  final int qty;
  final VoidCallback onDone;

  const _ChestArrivalPopup({
    required this.chestType,
    required this.chestName,
    required this.qty,
    required this.onDone,
  });

  @override
  State<_ChestArrivalPopup> createState() => _ChestArrivalPopupState();
}

class _ChestArrivalPopupState extends State<_ChestArrivalPopup>
    with TickerProviderStateMixin {
  late AnimationController _arriveCtrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  bool _showButton = false;

  @override
  void initState() {
    super.initState();

    // Chest flies in from far away
    _arriveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scale = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _arriveCtrl, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _arriveCtrl,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 3), end: Offset.zero).animate(
      CurvedAnimation(parent: _arriveCtrl, curve: Curves.easeOutBack),
    );

    // Glow pulse
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _arriveCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _showButton = true);
      });
    });
  }

  @override
  void dispose() {
    _arriveCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chestSpriteType =
        widget.chestType == 'wooden_chest' ? 'wooden' : 'iron';
    final glowColor =
        chestSpriteType == 'wooden' ? AppTheme.amber : AppTheme.cyan;

    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: AppTheme.body(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              AnimatedBuilder(
                animation: _arriveCtrl,
                builder: (context, child) => Opacity(
                  opacity: _opacity.value,
                  child: Text(
                    widget.qty > 1
                        ? '${widget.qty} Chests Acquired!'
                        : 'Chest Acquired!',
                    style: AppTheme.h1(color: AppTheme.accent)
                        .copyWith(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Animated chest with glow
              AnimatedBuilder(
                animation: Listenable.merge([_arriveCtrl, _glowCtrl]),
                builder: (context, child) => SlideTransition(
                  position: _slide,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Opacity(
                      opacity: _opacity.value.clamp(0.0, 1.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow Effect
                          Transform.scale(
                            scale: _glowAnim.value * 2.0,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: glowColor.withValues(
                                        alpha: 0.4 * _glowAnim.value),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Chest
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: Center(
                              child: ChestSprite(
                                chestType: chestSpriteType,
                                animation: 'Idle',
                                fps: 10,
                                size: 120,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _arriveCtrl,
                builder: (context, child) => Opacity(
                  opacity: _opacity.value,
                  child: Text(
                    '${widget.chestName}${widget.qty > 1 ? " x${widget.qty}" : ""}',
                    style: AppTheme.h2(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _arriveCtrl,
                builder: (context, child) => Opacity(
                  opacity: _opacity.value,
                  child: Text(
                    'Added to your inventory',
                    style: AppTheme.caption(color: AppTheme.text2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Done button
              AnimatedOpacity(
                opacity: _showButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: SGTouchable(
                  onTap: widget.onDone,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Continue',
                        style: AppTheme.label(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
