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
    if (_s == null) return const Center(child: CircularProgressIndicator());
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Profile', style: AppTheme.h1()),
                          const SizedBox(height: 4),
                          Text(
                            'Account & achievements.',
                            style: AppTheme.caption(),
                          ),
                        ],
                      ),
                      SGTouchable(
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const SettingsPage())),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.line)),
                          child: const Icon(Icons.settings, size: 22, color: AppTheme.accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // ── NEW MINIMAL DESIGN ───────────────────────────
                  // 1. Header Row (No Card)
                  Row(
                    children: [
                      // Profile Picture
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.silver, width: 1),
                          ),
                          child: ClipOval(
                            child: _profileImagePath.isNotEmpty
                                ? Image.file(File(_profileImagePath), fit: BoxFit.cover)
                                : Container(
                                    color: AppTheme.surface,
                                    child: Center(
                                      child: Text(
                                        user.isNotEmpty ? user[0].toUpperCase() : 'P',
                                        style: AppTheme.h1(color: AppTheme.accent).copyWith(fontSize: 24),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name & Level
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.toUpperCase(),
                              style: AppTheme.h2().copyWith(fontSize: 22, letterSpacing: 1),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LEVEL ${s.level}',
                              style: AppTheme.caption(color: AppTheme.accent).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 2. Rank Shield Card
                  SGCard(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'Assets/Rank Shields/${s.rank} Rank.png',
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield, color: AppTheme.accent, size: 100),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'CURRENT RANK',
                            style: AppTheme.caption(color: AppTheme.text2).copyWith(letterSpacing: 1.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${s.rank} RANK',
                            style: AppTheme.h1(color: AppTheme.accent).copyWith(fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // 3. Experience Card
                  SGCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('EXPERIENCE', style: AppTheme.label().copyWith(fontWeight: FontWeight.bold)),
                            Text('${s.xp} / $xpNeeded', style: AppTheme.mono(color: AppTheme.text2, size: 12)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: xpProgress,
                            minHeight: 6,
                            backgroundColor: AppTheme.surface,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
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

