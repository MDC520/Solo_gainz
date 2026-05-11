import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/user_stats.dart';
import '../services/storage.dart';
import '../theme/theme.dart';
import '../background.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    try {
      setState(() {
        _s = Storage.getUserStats();
        _profileImagePath = Storage.getData('profile_image_path', defaultValue: '');
      });
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
        uiSettings: [
          AndroidUiSettings(toolbarTitle: 'Crop Profile Picture', toolbarColor: AppTheme.bg, toolbarWidgetColor: Colors.white, activeControlsWidgetColor: AppTheme.accent),
          IOSUiSettings(title: 'Crop Profile Picture'),
        ],
      );
      if (croppedFile != null) {
        setState(() => _profileImagePath = croppedFile.path);
        await Storage.saveData('profile_image_path', croppedFile.path);
        if (mounted) AppTheme.showSnackBar(context, 'Profile picture updated!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Storage.getCurrentUser() ?? 'Player';
    if (_s == null) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    final s = _s!;
    final xpNeeded = RankSystem.getXpNeededForNextLevel(s.rank);
    final xpProgress = (s.xp / xpNeeded).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: LivelyBackground(
        child: SGScreenEntrance(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── SLIVER APP BAR (HEADER) ──
              SliverAppBar(
                expandedHeight: 280,
                collapsedHeight: 100,
                pinned: true,
                stretch: true,
                backgroundColor: AppTheme.black.withValues(alpha: 0.8),
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  background: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background Glow
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.accent.withValues(alpha: 0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Profile Picture Section
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          _AvatarWidget(
                            imagePath: _profileImagePath,
                            onTap: _pickImage,
                            initial: user.isNotEmpty ? user[0].toUpperCase() : 'P',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.toUpperCase(),
                            style: AppTheme.h1().copyWith(fontSize: 28, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  'LEVEL ${s.level}',
                                  style: AppTheme.mono(color: AppTheme.accent, size: 10),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.amber.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.monetization_on_rounded, size: 12, color: AppTheme.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${s.coins}',
                                      style: AppTheme.mono(color: AppTheme.amber, size: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SGTouchable(
                      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const SettingsPage())),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: const Icon(Icons.settings_rounded, size: 22, color: AppTheme.text1),
                      ),
                    ),
                  ),
                ],
              ),

              // ── MAIN CONTENT ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── RANK CARD ──
                    _RankCard(rank: s.rank),
                    const SizedBox(height: 24),

                    // ── PROGRESS SECTION ──
                    _ProgressCard(
                      xp: s.xp,
                      xpNeeded: xpNeeded,
                      progress: xpProgress,
                    ),
                    const SizedBox(height: 24),

                    // ── STATS GRID ──
                    const SGSectionHeader(title: 'Lifetime Stats'),
                    const SizedBox(height: 8),
                    _StatsGrid(stats: s.lifetimeStats),
                    const SizedBox(height: 24),

                    // ── RECENT ACHIEVEMENTS ──
                    if (s.achievements.isNotEmpty) ...[
                      const SGSectionHeader(title: 'Achievements'),
                      const SizedBox(height: 8),
                      _AchievementsList(achievements: s.achievements),
                      const SizedBox(height: 32),
                    ],

                    // ── LOGOUT BUTTON ──
                    SGButton(
                      label: 'LOG OUT',
                      danger: true,
                      outlined: true,
                      onTap: widget.onLogout,
                      icon: Icons.logout_rounded,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
          // Outer Ring
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3), width: 1.5),
            ),
          ),
          // Inner Spinning/Glow Ring
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  AppTheme.accent,
                  AppTheme.accent.withValues(alpha: 0.1),
                  AppTheme.accent,
                ],
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.black,
              ),
            ),
          ),
          // Actual Image
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface,
              image: imagePath.isNotEmpty
                  ? DecorationImage(image: FileImage(File(imagePath)), fit: BoxFit.cover)
                  : null,
            ),
            child: imagePath.isEmpty
                ? Center(
                    child: Text(
                      initial,
                      style: AppTheme.h1(color: AppTheme.accent).copyWith(fontSize: 32),
                    ),
                  )
                : null,
          ),
          // Camera Icon
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.black, width: 2),
                boxShadow: [
                  BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppTheme.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final String rank;

  const _RankCard({required this.rank});

  @override
  Widget build(BuildContext context) {
    return SGCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppTheme.accent.withValues(alpha: 0.2), Colors.transparent],
                  ),
                ),
              ),
              Image.asset(
                'Assets/Rank Shields/$rank Rank.png',
                height: 70,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.shield_rounded, color: AppTheme.accent, size: 60),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CURRENT RANK', style: AppTheme.caption(color: AppTheme.text3)),
                const SizedBox(height: 4),
                Text(
                  '$rank RANK',
                  style: AppTheme.h1().copyWith(fontSize: 24, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.cyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ON TRACK FOR NEXT RANK',
                    style: AppTheme.label(color: AppTheme.cyan).copyWith(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int xp;
  final int xpNeeded;
  final double progress;

  const _ProgressCard({
    required this.xp,
    required this.xpNeeded,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SGCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('XP PROGRESS', style: AppTheme.label(color: AppTheme.text2)),
              Text('$xp / $xpNeeded', style: AppTheme.mono(color: AppTheme.accent, size: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.line),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.6)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(progress * 100).toInt()}% to next level',
            style: AppTheme.caption(color: AppTheme.text3),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, int> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final entries = stats.entries.toList();
    if (entries.isEmpty) {
      return SGCard(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.fitness_center_rounded, color: AppTheme.text3.withValues(alpha: 0.3), size: 48),
              const SizedBox(height: 16),
              Text(
                'NO TRAINING DATA YET',
                style: AppTheme.label(color: AppTheme.text3),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete exercises to track your progress',
                style: AppTheme.caption(color: AppTheme.text3),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return SGCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.key.replaceAll('_', ' ').toUpperCase(),
                style: AppTheme.caption(color: AppTheme.text2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                entry.value.toString(),
                style: AppTheme.mono(color: AppTheme.text1, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AchievementsList extends StatelessWidget {
  final List<String> achievements;

  const _AchievementsList({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Container(
            width: 80,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.line),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppTheme.amber, size: 28),
                const SizedBox(height: 8),
                Text(
                  achievements[index].toUpperCase(),
                  style: AppTheme.caption(color: AppTheme.text1).copyWith(fontSize: 8),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

