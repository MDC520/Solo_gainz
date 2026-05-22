import 'dart:async';
import 'dart:math' as math;
import '../ui/theme.dart';
import '../widgets/player.dart';
import '../models/storage.dart';
import '../engine/combat_engine.dart';

// ── Campaign Data ───────────────────────────────────────────────────────────

class StoryChapter {
  final String id;
  final String title;
  final String description;
  final String bossName;
  final Color themeColor;
  final List<StoryStage> stages;

  const StoryChapter({
    required this.id,
    required this.title,
    required this.description,
    required this.bossName,
    required this.themeColor,
    required this.stages,
  });
}

class StoryStage {
  final String id;
  final String title;
  final String narrative;
  final String enemyAnimation;
  final int enemyHp;
  final int xpReward;
  final int coinReward;
  final String? chestReward;

  const StoryStage({
    required this.id,
    required this.title,
    required this.narrative,
    required this.enemyAnimation,
    required this.enemyHp,
    this.xpReward = 50,
    this.coinReward = 20,
    this.chestReward,
  });
}

// ── Campaign Definition ─────────────────────────────────────────────────────

class CampaignData {
  static const List<StoryChapter> chapters = [
    StoryChapter(
      id: 'chapter_1',
      title: 'The Awakening',
      description: 'You wake up in a dark dungeon. Find your way out.',
      bossName: 'Rattus the Rat King',
      themeColor: Color(0xFF4CAF50),
      stages: [
        StoryStage(
          id: 'c1s1',
          title: 'First Steps',
          narrative: 'The cold stone floor greets you as you rise. A single torch flickers on the wall. In the shadows, something stirs... A giant rat scurries toward you! Defend yourself!',
          enemyAnimation: 'Kick01',
          enemyHp: 30,
          xpReward: 20,
          coinReward: 10,
        ),
        StoryStage(
          id: 'c1s2',
          title: 'The Gatekeeper',
          narrative: 'You enter a wider chamber. Iron bars block the exit. A hulking goblin warden stands guard, cracking his knuckles. There is no negotiation — only combat.',
          enemyAnimation: 'Punch01',
          enemyHp: 50,
          xpReward: 35,
          coinReward: 15,
        ),
        StoryStage(
          id: 'c1s3',
          title: 'Rat King\'s Lair',
          narrative: 'The stench of decay fills the throne room. Rattus the Rat King sits upon a mound of bones, twitching his whiskers. "Another fool seeking freedom? I think not!" He lunges with supernatural speed.',
          enemyAnimation: 'Kick01',
          enemyHp: 80,
          xpReward: 60,
          coinReward: 30,
          chestReward: 'wooden_chest',
        ),
      ],
    ),
    StoryChapter(
      id: 'chapter_2',
      title: 'The Shadow Wood',
      description: 'Escape the dungeon into an enchanted forest.',
      bossName: 'Vorthos the Wraith',
      themeColor: Color(0xFF9C27B0),
      stages: [
        StoryStage(
          id: 'c2s1',
          title: 'Into the Woods',
          narrative: 'Moonlight filters through twisted branches. The forest hums with an unnatural energy. Twisted roots animate and lash out at your feet. You must cut through.',
          enemyAnimation: 'Kick01',
          enemyHp: 60,
          xpReward: 40,
          coinReward: 20,
        ),
        StoryStage(
          id: 'c2s2',
          title: 'The Clearing',
          narrative: 'A ring of mushrooms glows in a clearing. At its center kneels a cloaked figure, chanting. Dark energy pulses from the ground. The figure rises — a cultist bound to the Shadow Wood.',
          enemyAnimation: 'Punch01',
          enemyHp: 90,
          xpReward: 55,
          coinReward: 25,
        ),
        StoryStage(
          id: 'c2s3',
          title: 'Wraith Encounter',
          narrative: 'The air grows cold. Vorthos the Wraith materializes from the darkness itself, a shimmering silhouette of pure malice. "You carry a spark of life... I will feast on it." His icy tendrils reach for your soul.',
          enemyAnimation: 'Kick01',
          enemyHp: 130,
          xpReward: 90,
          coinReward: 45,
          chestReward: 'iron_chest',
        ),
      ],
    ),
    StoryChapter(
      id: 'chapter_3',
      title: 'The Iron Fortress',
      description: 'Storm the fortress and confront the Warlord.',
      bossName: 'General Ironhide',
      themeColor: Color(0xFFF44336),
      stages: [
        StoryStage(
          id: 'c3s1',
          title: 'Breach the Gates',
          narrative: 'The iron portcullis looms before you. Guards patrol the ramparts. You take a deep breath and charge — the assault has begun.',
          enemyAnimation: 'Punch01',
          enemyHp: 100,
          xpReward: 60,
          coinReward: 30,
        ),
        StoryStage(
          id: 'c3s2',
          title: 'Armory',
          narrative: 'Inside the fortress walls, you find the armory. Weapons line the walls, but so do the soldiers. They grab their blades and advance in formation.',
          enemyAnimation: 'Kick01',
          enemyHp: 140,
          xpReward: 80,
          coinReward: 40,
        ),
        StoryStage(
          id: 'c3s3',
          title: 'Throne Room Duel',
          narrative: 'General Ironhide sits on a throne of salvaged steel. His armor is scarred from a hundred battles. He rises, drawing a massive greatsword. "You have grit, I\'ll give you that. Let\'s see if it\'s enough."',
          enemyAnimation: 'Punch01',
          enemyHp: 200,
          xpReward: 120,
          coinReward: 60,
          chestReward: 'gold_chest',
        ),
      ],
    ),
  ];

  static String get storageKey => 'story_progress';
  static String xpKey(int stageIndex) => 'story_xp_$stageIndex';

  static Map<String, dynamic> getProgress() {
    final data = Storage.getData(storageKey);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  static bool isStageUnlocked(int stageIndex) {
    final progress = getProgress();
    final completed = progress['completed_stages'] as List? ?? [];
    if (stageIndex == 0) return true;
    return completed.contains((stageIndex - 1).toString());
  }

  static bool isStageCompleted(int stageIndex) {
    final progress = getProgress();
    final completed = progress['completed_stages'] as List? ?? [];
    return completed.contains(stageIndex.toString());
  }

  static Future<void> completeStage(int stageIndex) async {
    final progress = getProgress();
    final completed = List<String>.from(progress['completed_stages'] as List? ?? []);
    if (!completed.contains(stageIndex.toString())) {
      completed.add(stageIndex.toString());
    }
    progress['completed_stages'] = completed;
    await Storage.saveData(storageKey, progress);
  }

  static int totalStages() {
    int count = 0;
    for (var ch in chapters) {
      count += ch.stages.length;
    }
    return count;
  }
}

// ── Story Screen ────────────────────────────────────────────────────────────

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Story Mode', style: AppTheme.h2()),
      ),
      body: ListView.builder(
        padding: Responsive.all(20),
        itemCount: CampaignData.chapters.length,
        itemBuilder: (context, chIndex) {
          final chapter = CampaignData.chapters[chIndex];
          return _ChapterCard(
            chapter: chapter,
            chapterIndex: chIndex,
            bgCtrl: _bgCtrl,
            onStageTap: (stageIndex) {
              _startBattle(chapter, stageIndex, chIndex);
            },
          );
        },
      ),
    );
  }

  void _startBattle(StoryChapter chapter, int stageIndex, int chIndex) {
    final stage = chapter.stages[stageIndex];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BattleScreen(
          chapter: chapter,
          stage: stage,
          stageIndex: stageIndex,
          chIndex: chIndex,
        ),
      ),
    );
  }
}

// ── Chapter Card ────────────────────────────────────────────────────────────

class _ChapterCard extends StatelessWidget {
  final StoryChapter chapter;
  final int chapterIndex;
  final AnimationController bgCtrl;
  final void Function(int stageIndex) onStageTap;

  const _ChapterCard({
    required this.chapter,
    required this.chapterIndex,
    required this.bgCtrl,
    required this.onStageTap,
  });

  @override
  Widget build(BuildContext context) {
    int offset = 0;
    for (int i = 0; i < chapterIndex; i++) {
      offset += CampaignData.chapters[i].stages.length;
    }

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.h(20)),
      decoration: BoxDecoration(
        color: chapter.themeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Responsive.r(20)),
        border: Border.all(color: chapter.themeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: Responsive.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chapter.title.toUpperCase(),
                  style: AppTheme.mono(color: chapter.themeColor, size: 16)),
                SizedBox(height: Responsive.h(4)),
                Text(chapter.description,
                  style: AppTheme.caption(color: AppTheme.text2)),
                SizedBox(height: Responsive.h(4)),
                Text('Boss: ${chapter.bossName}',
                  style: AppTheme.mono(color: AppTheme.text3, size: 10)),
              ],
            ),
          ),
          ...List.generate(chapter.stages.length, (sIndex) {
            final globalIndex = offset + sIndex;
            final stage = chapter.stages[sIndex];
            final unlocked = CampaignData.isStageUnlocked(globalIndex);
            final completed = CampaignData.isStageCompleted(globalIndex);

            return Container(
              margin: Responsive.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: completed
                    ? chapter.themeColor.withValues(alpha: 0.15)
                    : AppTheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(Responsive.r(12)),
                border: Border.all(
                  color: completed
                      ? chapter.themeColor.withValues(alpha: 0.5)
                      : AppTheme.line,
                ),
              ),
              child: ListTile(
                dense: true,
                leading: Icon(
                  completed ? Icons.check_circle : (unlocked ? Icons.play_circle_outline : Icons.lock_outline),
                  color: completed ? chapter.themeColor : (unlocked ? AppTheme.accent : AppTheme.text3),
                ),
                title: Text(
                  stage.title,
                  style: AppTheme.body(color: completed ? AppTheme.text1 : AppTheme.text2),
                ),
                subtitle: Text(
                  '${stage.xpReward} XP  •  ${stage.coinReward} coins${stage.chestReward != null ? '  •  🎁 ${stage.chestReward!.replaceAll('_chest', '').toUpperCase()} Chest' : ''}',
                  style: AppTheme.caption(color: AppTheme.text3),
                ),
                trailing: completed
                    ? Icon(Icons.check_rounded, color: chapter.themeColor, size: 20)
                    : (unlocked ? Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.accent, size: 16) : null),
                enabled: unlocked,
                onTap: unlocked && !completed ? () => onStageTap(globalIndex) : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Battle Screen ───────────────────────────────────────────────────────────

class _BattleScreen extends StatefulWidget {
  final StoryChapter chapter;
  final StoryStage stage;
  final int stageIndex;
  final int chIndex;

  const _BattleScreen({
    required this.chapter,
    required this.stage,
    required this.stageIndex,
    required this.chIndex,
  });

  @override
  State<_BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<_BattleScreen> with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  bool _showNarrative = true;
  bool _battleStarted = false;
  bool _battleOver = false;
  bool _victory = false;
  int _enemyHp = 0;
  int _playerHp = 100;
  String _log = '';
  Timer? _enemyAttackTimer;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _enemyHp = widget.stage.enemyHp;
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _enemyAttackTimer?.cancel();
    super.dispose();
  }

  void _startBattle() {
    setState(() {
      _showNarrative = false;
      _battleStarted = true;
      _log = '⚔️ Battle begins!';
    });
    _startEnemyAttacks();
  }

  void _startEnemyAttacks() {
    _enemyAttackTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _battleOver) return;
      final dmg = 5 + math.Random().nextInt(10);
      setState(() {
        _playerHp = (_playerHp - dmg).clamp(0, 100);
        _log = '👊 Enemy hits you for $dmg damage!';
      });
      if (_playerHp <= 0) {
        _endBattle(false);
      }
    });
  }

  void _playerAttack() {
    if (_battleOver || !_battleStarted) return;
    final dmg = 8 + math.Random().nextInt(15);
    setState(() {
      _enemyHp = (_enemyHp - dmg).clamp(0, widget.stage.enemyHp);
      _log = '💥 You strike for $dmg damage!';
    });
    if (_enemyHp <= 0) {
      _endBattle(true);
    }
  }

  Future<void> _endBattle(bool won) async {
    _battleOver = true;
    _enemyAttackTimer?.cancel();
    if (won) {
      await CampaignData.completeStage(widget.stageIndex);
      await Storage.addXp(widget.stage.xpReward);
      await Storage.addCoins(widget.stage.coinReward);
      if (widget.stage.chestReward != null) {
        await Storage.addChestToInventory(widget.stage.chestReward!);
      }
    }
    if (mounted) {
      setState(() {
        _victory = won;
        if (won) {
          _log = '🎉 Victory! +${widget.stage.xpReward} XP, +${widget.stage.coinReward} coins${widget.stage.chestReward != null ? ', +${widget.stage.chestReward!.replaceAll('_chest', '')} Chest' : ''}';
        } else {
          _log = '💀 Defeated... Try again!';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (context, _) => CustomPaint(
                painter: NotebookPainter(_bgCtrl.value, lineColor: widget.chapter.themeColor.withValues(alpha: 0.05)),
              ),
            ),
          ),

          if (_showNarrative)
            _buildNarrativeView()
          else
            _buildBattleView(),
        ],
      ),
    );
  }

  Widget _buildNarrativeView() {
    return Center(
      child: Padding(
        padding: Responsive.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.stage.title.toUpperCase(),
              style: AppTheme.mono(color: widget.chapter.themeColor, size: 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.h(24)),
            Container(
              padding: Responsive.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(Responsive.r(16)),
                border: Border.all(color: widget.chapter.themeColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                widget.stage.narrative,
                style: AppTheme.body(color: AppTheme.text1),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: Responsive.h(40)),
            SGTouchable(
              onTap: _startBattle,
              child: Container(
                padding: Responsive.symmetric(horizontal: 48, vertical: 16),
                decoration: BoxDecoration(
                  color: widget.chapter.themeColor,
                  borderRadius: BorderRadius.circular(Responsive.r(16)),
                ),
                child: Text('FIGHT!', style: AppTheme.label(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleView() {
    return Column(
      children: [
        // Enemy area
        Expanded(
          flex: 3,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Player(
                    animation: widget.stage.enemyAnimation,
                    size: 160,
                    fps: 8,
                    loop: true,
                  ),
                ),
                SizedBox(height: Responsive.h(12)),
                // Enemy HP bar
                Container(
                  width: 200,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.chapter.themeColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(
                          width: 200 * (_enemyHp / widget.stage.enemyHp),
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [widget.chapter.themeColor, widget.chapter.themeColor.withValues(alpha: 0.5)],
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            '$_enemyHp / ${widget.stage.enemyHp}',
                            style: AppTheme.mono(color: Colors.white, size: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Responsive.h(8)),
                Text(widget.stage.title, style: AppTheme.mono(color: widget.chapter.themeColor, size: 12)),
              ],
            ),
          ),
        ),

        // Battle log
        Container(
          padding: Responsive.all(12),
          margin: Responsive.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(Responsive.r(12)),
          ),
          child: Text(_log, style: AppTheme.mono(color: AppTheme.text2, size: 11), textAlign: TextAlign.center),
        ),

        // Player area
        Expanded(
          flex: 3,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Player(
                    animation: _playerHp <= 0 ? 'Hit' : (_battleOver ? 'Idle' : 'Idle'),
                    size: 120,
                    fps: 8,
                    loop: true,
                  ),
                ),
                SizedBox(height: Responsive.h(8)),
                // Player HP bar
                Container(
                  width: 200,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.accent),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(
                          width: 200 * (_playerHp / 100),
                          height: 20,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF00E676), Color(0xFF00B8D4)],
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            '$_playerHp / 100',
                            style: AppTheme.mono(color: Colors.white, size: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Responsive.h(20)),
              ],
            ),
          ),
        ),

        // Actions
        Padding(
          padding: Responsive.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_battleOver)
                SGTouchable(
                  onTap: _playerAttack,
                  child: Container(
                    padding: Responsive.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.red,
                      borderRadius: BorderRadius.circular(Responsive.r(16)),
                      boxShadow: [BoxShadow(color: AppTheme.red.withValues(alpha: 0.3), blurRadius: 12)],
                    ),
                    child: Text('ATTACK', style: AppTheme.label(color: Colors.white)),
                  ),
                ),
              if (_battleOver)
                SGTouchable(
                  onTap: () {
                    if (_victory) {
                      Navigator.pop(context);
                    } else {
                      setState(() {
                        _enemyHp = widget.stage.enemyHp;
                        _playerHp = 100;
                        _battleOver = false;
                        _log = '⚔️ Battle renewed!';
                      });
                      _startEnemyAttacks();
                    }
                  },
                  child: Container(
                    padding: Responsive.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      color: _victory ? AppTheme.accent : AppTheme.red,
                      borderRadius: BorderRadius.circular(Responsive.r(16)),
                    ),
                    child: Text(
                      _victory ? 'CONTINUE' : 'RETRY',
                      style: AppTheme.label(color: Colors.black),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
