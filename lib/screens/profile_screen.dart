import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../services/storage.dart';
import '../theme/theme.dart';
import '../theme/background.dart';
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
        _profileImagePath = Storage.getProfileImage() ?? '';
      });
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512);
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: AppTheme.bg,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppTheme.accent,
          ),
          IOSUiSettings(title: 'Crop Profile Picture'),
        ],
      );
      if (croppedFile != null) {
        setState(() => _profileImagePath = croppedFile.path);
        await Storage.setProfileImage(croppedFile.path);
        if (mounted) AppTheme.showSnackBar(context, 'Profile picture updated!');
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppTheme.glassBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text('Profile Photo', style: AppTheme.h2()),
            const SizedBox(height: 24),
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
                const SizedBox(width: 16),
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
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
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
    if (_s == null) return Center(child: CircularProgressIndicator(color: AppTheme.accent));
    final s = _s!;
    final characterTitle = _getCharacterTitle(s.level, s.rank);

    return Scaffold(
      backgroundColor: AppTheme.black,
      body: LivelyBackground(
        child: SGScreenEntrance(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 120),
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
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.text1, width: 1.5),
                              ),
                              child: Icon(Icons.settings_rounded, size: 18, color: AppTheme.text2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Player Identity Centerpiece Card
                      Center(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.glassBorder, width: 1.5),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Radial Aura Glow Behind Avatar
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 140,
                                    height: 140,
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
                                  _AvatarWidget(
                                    imagePath: _profileImagePath,
                                    onTap: _showImageSourcePicker,
                                    initial: user.isNotEmpty ? user[0].toUpperCase() : 'P',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                user.toUpperCase(),
                                style: AppTheme.h1().copyWith(
                                  fontSize: 28,
                                  letterSpacing: -0.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                characterTitle.toUpperCase(),
                                style: AppTheme.mono(
                                  color: AppTheme.accent,
                                  size: 12,
                                ).copyWith(
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Level and Coins Chips Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cyan.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.25), width: 1),
                                    ),
                                    child: Text(
                                      'LEVEL ${s.level}',
                                      style: AppTheme.mono(color: AppTheme.cyan, size: 10).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.amber.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: AppTheme.amber.withValues(alpha: 0.25), width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.monetization_on_rounded, size: 12, color: AppTheme.amber),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${s.coins} COINS',
                                          style: AppTheme.mono(color: AppTheme.amber, size: 10).copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Achievements section
                      if (s.achievements.isNotEmpty) ...[
                        const SGSectionHeader(title: 'Medals of Valor'),
                        const SizedBox(height: 10),
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
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
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
                borderRadius: BorderRadius.circular(19.5),
                color: AppTheme.black,
                image: imagePath.isNotEmpty
                    ? DecorationImage(image: FileImage(File(imagePath)), fit: BoxFit.cover)
                    : null,
              ),
              child: imagePath.isEmpty
                  ? Center(
                      child: Text(
                        initial,
                        style: AppTheme.h1(color: AppTheme.accent).copyWith(fontSize: 34, fontWeight: FontWeight.w900),
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppTheme.black, width: 2.0),
                boxShadow: [
                  BoxShadow(color: AppTheme.accent.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1),
                ],
              ),
              child: Icon(Icons.camera_alt_rounded, size: 12, color: AppTheme.black),
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
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final achievementName = achievements[index].toUpperCase();
          return Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3), width: 1.5),
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
                  top: -10,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppTheme.amber.withValues(alpha: 0.15), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                
                // Content Column
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_rounded, color: AppTheme.amber, size: 30),
                    const SizedBox(height: 8),
                    Text(
                      achievementName,
                      style: AppTheme.caption(color: AppTheme.text1).copyWith(
                        fontSize: 8.5,
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
