import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (image != null) {
        final permPath = await Storage.setProfileImage(image.path);
        setState(() => _profileImagePath = permPath);
        if (mounted) {
          AppTheme.showSnackBar(context, 'Profile picture updated!');
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile content directly without card
                      Center(
                        child: _buildStatusTab(s, user, characterTitle),
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

  Widget _buildStatusTab(UserStats s, String user, String characterTitle) {
    return Column(
      key: const ValueKey('status_tab'),
      crossAxisAlignment: CrossAxisAlignment.center,
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
      ],
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
              borderRadius: BorderRadius.zero,
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
                borderRadius: BorderRadius.zero,
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
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: Responsive.sp(34),
                          fontWeight: FontWeight.normal,
                        ),
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
