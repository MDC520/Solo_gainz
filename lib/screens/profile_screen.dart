import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/user_stats.dart';
import '../services/storage.dart';
import '../theme/theme.dart';
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

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Profile', style: AppTheme.h1().copyWith(fontSize: 32)),
                          const SizedBox(height: 4),
                          Text('Account & achievements', style: AppTheme.caption(color: AppTheme.text2)),
                        ],
                      ),
                      SGTouchable(
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const SettingsPage())),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: const Icon(Icons.settings_rounded, size: 24, color: AppTheme.text2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── PROFILE ID CARD ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.line, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [
                                      AppTheme.accent, 
                                      AppTheme.accent.withValues(alpha: 0.1), 
                                      AppTheme.accent
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.bg,
                                  border: Border.all(color: AppTheme.line, width: 2),
                                ),
                                child: ClipOval(
                                  child: _profileImagePath.isNotEmpty
                                      ? Image.file(File(_profileImagePath), fit: BoxFit.cover)
                                      : Container(
                                          color: AppTheme.surface,
                                          child: Center(
                                            child: Text(
                                              user.isNotEmpty ? user[0].toUpperCase() : 'P',
                                              style: AppTheme.h1(color: AppTheme.accent).copyWith(fontSize: 28),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.line, width: 1.5),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppTheme.accent),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.toUpperCase(),
                                style: AppTheme.h2().copyWith(fontSize: 24, letterSpacing: -0.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'LEVEL ${s.level}',
                                  style: AppTheme.mono(color: AppTheme.accent, size: 12).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // ── RANK SHIELD ──
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: AppTheme.line, width: 1.5),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Larger aura behind shield
                              Container(
                                width: 180, height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [AppTheme.accent.withValues(alpha: 0.25), Colors.transparent],
                                  ),
                                ),
                              ),
                              Image.asset(
                                'Assets/Rank Shields/${s.rank} Rank.png',
                                height: 160,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield_rounded, color: AppTheme.accent, size: 160),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'CURRENT RANK',
                            style: AppTheme.label(color: AppTheme.text3).copyWith(letterSpacing: 2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${s.rank} RANK',
                            style: AppTheme.h1().copyWith(fontSize: 28, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // ── EXPERIENCE BAR ──
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.line, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppTheme.accent, size: 20),
                                const SizedBox(width: 8),
                                Text('EXPERIENCE', style: AppTheme.label(color: AppTheme.text2)),
                              ],
                            ),
                            Text('${s.xp} / $xpNeeded', style: AppTheme.mono(color: AppTheme.accent, size: 14)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppTheme.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.line.withValues(alpha: 0.2)),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: xpProgress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppTheme.accent.withValues(alpha: 0.5), AppTheme.accent],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

