import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../models/storage.dart';
import '../ui/theme.dart';
import '../widgets/background.dart';
import 'settings_screen.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfilePage({super.key, required this.onLogout});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserStats? _s;
  String _profileImagePath = '';
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    try {
      setState(() {
        _s = Storage.getUserStats();
        _profileImagePath = Storage.getProfileImage() ?? '';
      });
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image =
          await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512);
      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressQuality: 85,
          maxWidth: 512,
          maxHeight: 512,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop & Rotate Profile Picture',
              toolbarColor: AppTheme.bg,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: AppTheme.accent,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: 'Crop & Rotate Profile Picture',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );
        if (croppedFile != null) {
          final permPath = await Storage.setProfileImage(croppedFile.path);
          setState(() => _profileImagePath = permPath);
          if (mounted) AppTheme.showSnackBar(context, 'Profile picture updated!');
        }
      }
    } catch (e) {
      debugPrint('Error picking or cropping image: $e');
      if (mounted) {
        AppTheme.showSnackBar(context, 'Failed to update profile picture.');
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.r(28))),
          border: Border(top: BorderSide(color: AppTheme.glassBorder)),
        ),
        padding: Responsive.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: Responsive.w(36),
              height: Responsive.h(4),
              decoration: BoxDecoration(
                color: AppTheme.line,
                borderRadius: BorderRadius.circular(Responsive.r(2)),
              ),
            ),
            SizedBox(height: Responsive.h(24)),
            Text('Profile Photo', style: AppTheme.h2()),
            SizedBox(height: Responsive.h(24)),
            Row(
              children: [
                Expanded(
                  child: SGTouchable(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    child: _imageSourceCard(
                      Icons.camera_alt_rounded,
                      'Take Selfie',
                      AppTheme.accent,
                    ),
                  ),
                ),
                SizedBox(width: Responsive.w(16)),
                Expanded(
                  child: SGTouchable(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                    child: _imageSourceCard(
                      Icons.photo_library_rounded,
                      'Import Photos',
                      AppTheme.cyan,
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

  Widget _imageSourceCard(IconData icon, String label, Color color) {
    return Container(
      padding: Responsive.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Responsive.r(20)),
        border: Border.all(color: color.withValues(alpha: 0.2), width: Responsive.dp(1.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: Responsive.icon(32), color: color),
          SizedBox(height: Responsive.h(12)),
          Text(label, style: AppTheme.label(color: color)),
        ],
      ),
    );
  }

  String _getCharacterTitle(int level, String rank) {
    final r = rank.toUpperCase();
    if (r == 'SS' || r == 'S') return 'Shadow Monarch';
    if (r == 'A') return 'Grand Gladiator';
    if (level >= 30) return 'Vanguard Conqueror';
    if (level >= 20) return 'Iron Champion';
    if (level >= 10) return 'Runic Hunter';
    return 'Novice Leveler';
  }

  @override
  Widget build(BuildContext context) {
    final user = Storage.getCurrentUser() ?? 'Player';
    if (_s == null) {
      return Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }
    final s = _s!;
    final characterTitle = _getCharacterTitle(s.level, s.rank);

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: LivelyBackground(
        child: SGScreenEntrance(
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title & Settings (Top Right, aligned like quest_screen)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Player Profile', style: AppTheme.h1()),
                              const SizedBox(height: 4),
                              Text(
                                'View status and achievements.',
                                style: AppTheme.caption(color: AppTheme.text2),
                              ),
                            ],
                          ),
                          SGTouchable(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SettingsPage())),
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppTheme.text1, width: 1.5),
                              ),
                              child: Icon(Icons.settings_rounded,
                                  size: 18, color: AppTheme.text2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Player Identity Centerpiece Card
                      Center(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(Responsive.r(24)),
                            border: Border.all(
                                color: AppTheme.glassBorder, width: Responsive.dp(1.5)),
                            boxShadow: [
                              BoxShadow(
                                  color: AppTheme.accent.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  spreadRadius: 2),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tab Switcher
                              Padding(
                                padding: Responsive.fromLTRB(16, 16, 16, 0),
                                child: Row(
                                  children: [
                                    _buildTabButton(0, 'STATUS'),
                                    SizedBox(width: Responsive.w(8)),
                                    _buildTabButton(1, 'STATS'),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: Responsive.all(20),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SizeTransition(
                                        sizeFactor: animation,
                                        alignment: Alignment.topCenter,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _currentTab == 0
                                      ? _buildStatusTab(s, user, characterTitle)
                                      : _buildStatsTab(
                                          10 + (s.lifetimeStats['pushups'] ?? 0) + (s.lifetimeStats['bench_press'] ?? 0) + (s.lifetimeStats['squats'] ?? 0) + (s.lifetimeStats['deadlift'] ?? 0),
                                          10 + (s.lifetimeStats['running'] ?? 0) + (s.lifetimeStats['jumping_jacks'] ?? 0) + (s.lifetimeStats['sprints'] ?? 0) + (s.lifetimeStats['mountain_climbers'] ?? 0),
                                          10 + (s.lifetimeStats['total_completed'] ?? 0) + s.level * 3,
                                          10 + (s.lifetimeStats['plank'] ?? 0) + (s.lifetimeStats['wall_sit'] ?? 0) + s.level * 2,
                                          10 + s.level * 4 + s.achievements.length * 10,
                                          s,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.h(28)),

                      // Achievements section
                      if (s.achievements.isNotEmpty) ...[
                        const SGSectionHeader(title: 'Medals of Valor'),
                        SizedBox(height: Responsive.h(10)),
                        _AchievementsDeck(achievements: s.achievements),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final bool isActive = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTab = index;
          });
          AppTheme.tap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: Responsive.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.accent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(Responsive.r(12)),
            border: Border.all(
              color: isActive ? AppTheme.accent : Colors.transparent,
              width: Responsive.dp(1.2),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.pixel(
              color: isActive ? AppTheme.accent : AppTheme.text3,
              size: 10,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTab(UserStats s, String user, String characterTitle) {
    final xpNeeded = RankSystem.getXpNeededForNextLevel(s.rank);
    final xpProgress = (xpNeeded > 0 ? (s.xp / xpNeeded) : 0.0).clamp(0.0, 1.0).toDouble();

    return Column(
      key: const ValueKey('status_tab'),
      children: [
        // Avatar with Ring
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: Responsive.h(130),
              height: Responsive.h(130),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accent.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            _AvatarWidget(
              imagePath: _profileImagePath,
              onTap: _showImageSourcePicker,
              initial: user.isNotEmpty ? user[0].toUpperCase() : 'P',
            ),
          ],
        ),
        SizedBox(height: Responsive.h(16)),
        Text(
          user.toUpperCase(),
          style: AppTheme.h1().copyWith(
            fontSize: Responsive.sp(26),
            letterSpacing: -0.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: Responsive.h(4)),
        Text(
          characterTitle.toUpperCase(),
          style: AppTheme.mono(
            color: AppTheme.accent,
            size: 11,
          ).copyWith(
            letterSpacing: 2.0,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: Responsive.h(20)),

        // Custom RPG XP Bar
        Container(
          padding: Responsive.all(12),
          decoration: BoxDecoration(
            color: AppTheme.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            border: Border.all(color: AppTheme.line.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EXP PROGRESS',
                    style: AppTheme.mono(color: AppTheme.text2, size: 10),
                  ),
                  Text(
                    '${(xpProgress * 100).toInt()}%',
                    style: AppTheme.mono(color: AppTheme.accent, size: 10),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(6)),
              Container(
                width: double.infinity,
                height: Responsive.h(10),
                decoration: BoxDecoration(
                  color: AppTheme.black,
                  borderRadius: BorderRadius.circular(Responsive.r(5)),
                ),
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: constraints.maxWidth * xpProgress,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppTheme.purple,
                              AppTheme.accent,
                            ]),
                            borderRadius: BorderRadius.circular(Responsive.r(5)),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accent.withValues(alpha: 0.4),
                                blurRadius: 6,
                              )
                            ],
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),
              SizedBox(height: Responsive.h(6)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${s.xp} / $xpNeeded XP',
                    style: AppTheme.mono(color: AppTheme.text3, size: 9),
                  ),
                  Text(
                    'RANK ${s.rank}',
                    style: AppTheme.mono(color: AppTheme.cyan, size: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.h(16)),

        // Level & Coins chips
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: Responsive.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Responsive.r(30)),
                border: Border.all(
                  color: AppTheme.cyan.withValues(alpha: 0.25),
                  width: Responsive.dp(1.2),
                ),
              ),
              child: Text(
                'LEVEL ${s.level}',
                style: AppTheme.mono(color: AppTheme.cyan, size: 11).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: Responsive.w(12)),
            Container(
              padding: Responsive.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Responsive.r(30)),
                border: Border.all(
                  color: AppTheme.amber.withValues(alpha: 0.25),
                  width: Responsive.dp(1.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on_rounded, size: Responsive.icon(13), color: AppTheme.amber),
                  SizedBox(width: Responsive.w(4)),
                  Text(
                    '${s.coins} COINS',
                    style: AppTheme.mono(color: AppTheme.amber, size: 11).copyWith(
                      fontWeight: FontWeight.bold,
                ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsTab(int str, int agi, int vit, int sen, int intel, UserStats s) {
    final int combatPower = (s.level * 150) + (str * 2) + (agi * 2) + (vit * 3) + (sen * 2) + (intel * 5);

    return Column(
      key: const ValueKey('stats_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Combat Power Header
        Container(
          width: double.infinity,
          padding: Responsive.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            border: Border.all(color: AppTheme.purple.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COMBAT POWER',
                    style: AppTheme.mono(color: AppTheme.text2, size: 10).copyWith(letterSpacing: 0.5),
                  ),
                  SizedBox(height: Responsive.h(2)),
                  Text(
                    'CP $combatPower',
                    style: AppTheme.pixel(color: AppTheme.purple, size: 13),
                  ),
                ],
              ),
              Icon(Icons.bolt_rounded, color: AppTheme.purple, size: Responsive.icon(28)),
            ],
          ),
        ),
        SizedBox(height: Responsive.h(16)),

        // 5 Core Stats
        _buildStatRow('STR', 'Strength', str, Colors.red, Icons.fitness_center_rounded, 'Boosted by Push-ups, Bench Press, Squats, and Deadlifts.'),
        SizedBox(height: Responsive.h(12)),
        _buildStatRow('AGI', 'Agility', agi, AppTheme.cyan, Icons.directions_run_rounded, 'Boosted by Running, Sprints, Jumping Jacks, and Cardio.'),
        SizedBox(height: Responsive.h(12)),
        _buildStatRow('VIT', 'Vitality', vit, AppTheme.green, Icons.favorite_rounded, 'Boosted by Total Quest Completion & Level Ups.'),
        SizedBox(height: Responsive.h(12)),
        _buildStatRow('SEN', 'Sense', sen, AppTheme.amber, Icons.remove_red_eye_rounded, 'Boosted by Planks, Wall Sits, Core Exercises & Level Ups.'),
        SizedBox(height: Responsive.h(12)),
        _buildStatRow('INT', 'Intelligence', intel, AppTheme.purple, Icons.psychology_rounded, 'Boosted by Level gains & unlockable achievement medals.'),
      ],
    );
  }

  Widget _buildStatRow(String code, String name, int value, Color color, IconData icon, String description) {
    final double pct = (value / 300.0).clamp(0.05, 1.0);

    return SGTouchable(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.r(20)),
              side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
            ),
            title: Row(
              children: [
                Icon(icon, color: color, size: Responsive.icon(24)),
                SizedBox(width: Responsive.w(8)),
                Text('$name ($code)', style: AppTheme.h2(color: color)),
              ],
            ),
            content: Text(
              description,
              style: AppTheme.body(color: AppTheme.text1),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: AppTheme.mono(color: color, size: 14)),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: Responsive.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(Responsive.r(12)),
          border: Border.all(color: AppTheme.line.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: Responsive.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: Responsive.icon(16)),
            ),
            SizedBox(width: Responsive.w(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        code,
                        style: AppTheme.mono(color: AppTheme.text1, size: 11),
                      ),
                      Text(
                        '$value',
                        style: AppTheme.pixel(color: color, size: 10),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.h(4)),
                  Container(
                    width: double.infinity,
                    height: Responsive.h(6),
                    decoration: BoxDecoration(
                      color: AppTheme.black,
                      borderRadius: BorderRadius.circular(Responsive.r(3)),
                    ),
                    child: Stack(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: constraints.maxWidth * pct,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(Responsive.r(3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CUSTOM ROUNDED PROFILE AVATAR WIDGET ──
class _AvatarWidget extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;
  final String initial;

  const _AvatarWidget({
    required this.imagePath,
    required this.onTap,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return SGTouchable(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Single Outer Neon Gradient Border Wrapper
          Container(
            width: Responsive.h(104),
            height: Responsive.h(104),
            padding: Responsive.all(2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Responsive.r(22)),
              gradient: SweepGradient(
                colors: [
                  AppTheme.accent,
                  AppTheme.accent.withValues(alpha: 0.2),
                  AppTheme.purple,
                  AppTheme.accent,
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Responsive.r(19.5)),
                color: AppTheme.black,
                image: imagePath.isNotEmpty && File(imagePath).existsSync()
                    ? DecorationImage(
                        image: FileImage(File(imagePath)), fit: BoxFit.cover)
                    : null,
              ),
              child: imagePath.isEmpty || !File(imagePath).existsSync()
                  ? Center(
                      child: Text(
                        initial,
                        style: AppTheme.h1(color: AppTheme.accent).copyWith(
                            fontSize: Responsive.sp(34), fontWeight: FontWeight.w900),
                      ),
                    )
                  : null,
            ),
          ),
          // Futuristic Edit Badge
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: Responsive.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(Responsive.r(9)),
                border: Border.all(color: AppTheme.black, width: Responsive.dp(2.0)),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1),
                ],
              ),
              child: Icon(Icons.camera_alt_rounded,
                  size: Responsive.icon(12), color: AppTheme.black),
            ),
          ),
        ],
      ),
    );
  }
}

// ── HONORS DECK (ACHIEVEMENTS LIST) ──
class _AchievementsDeck extends StatelessWidget {
  final List<String> achievements;

  const _AchievementsDeck({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Responsive.h(110),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (_, __) => SizedBox(width: Responsive.w(14)),
        itemBuilder: (context, index) {
          final achievementName = achievements[index].toUpperCase();
          return Container(
            width: Responsive.w(100),
            padding: Responsive.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(Responsive.r(20)),
              border: Border.all(
                  color: AppTheme.amber.withValues(alpha: 0.3), width: Responsive.dp(1.5)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.amber.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing Background Effect
                Positioned(
                  top: Responsive.h(-10),
                  child: Container(
                    width: Responsive.h(44),
                    height: Responsive.h(44),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.amber.withValues(alpha: 0.15),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),

                // Content Column
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        color: AppTheme.amber, size: Responsive.icon(30)),
                    SizedBox(height: Responsive.h(8)),
                    Text(
                      achievementName,
                      style: AppTheme.caption(color: AppTheme.text1).copyWith(
                        fontSize: Responsive.sp(8.5),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
