import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/user_stats.dart';
import '../services/storage.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';

import 'account_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class ProfilePage extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfilePage({super.key, required this.onLogout});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserStats? _s;
  String _profileImagePath = '';
  String _avatarStyle = 'circle';
  Timer? _longPressTimer;
  bool _loading = false;
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    try {
      setState(() {
        _s = Storage.getUserStats();
        _profileImagePath =
            Storage.getData('profile_image_path', defaultValue: '');
        _avatarStyle = Storage.getData('avatar_style', defaultValue: 'circle');
      });
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    // Request permission first
    if (Platform.isAndroid || Platform.isIOS) {
      // On Android 13+, this might need specific handling, but image_picker usually manages it.
    }

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024, // Optimized for upload
      maxHeight: 1024,
    );

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
            statusBarColor: AppTheme.bg,
            activeControlsWidgetColor: AppTheme.accent,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() => _loading = true);
        try {
          final user = Storage.getCurrentUser() ?? 'Unknown';
          if (Storage.isLoggedIn()) {
            final publicUrl = await _auth.uploadAvatar(croppedFile.path, user);
            if (publicUrl != null) {
              setState(() => _profileImagePath = publicUrl);
              await Storage.saveData('profile_image_path', publicUrl);
            } else {
              // Fallback to local path if upload skipped or failed
              setState(() => _profileImagePath = croppedFile.path);
              await Storage.saveData('profile_image_path', croppedFile.path);
            }
            if (mounted) {
              AppTheme.showSnackBar(context, 'Profile picture updated!');
            }
          } else {
            setState(() => _profileImagePath = croppedFile.path);
            await Storage.saveData('profile_image_path', croppedFile.path);
          }
        } catch (e) {
          if (mounted) {
            AppTheme.showSnackBar(context, e.toString(), isError: true);
          }
        } finally {
          if (mounted) setState(() => _loading = false);
        }
      }
    }
  }

  Future<void> _contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'originalsadiqteam@gmail.com',
      query: 'subject=Solo Gainz Support Request',
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
        AppTheme.showSnackBar(context, 'Could not open email app',
            isError: true);
      }
    }
  }

  void _startLongPressTimer() {
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(milliseconds: 1385), () {
      _showAvatarStyleMenu();
    });
  }

  void _cancelLongPressTimer() {
    _longPressTimer?.cancel();
  }

  void _showAvatarStyleMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Avatar Style', style: AppTheme.h3()),
        message: const Text('Choose how your profile picture appears.'),
        actions: [
          CupertinoActionSheetAction(
            child: Text('Circular',
                style: AppTheme.label(
                    color: _avatarStyle == 'circle'
                        ? AppTheme.accent
                        : AppTheme.text1)),
            onPressed: () {
              Navigator.pop(ctx);
              _updateAvatarStyle('circle');
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Rounded Square',
                style: AppTheme.label(
                    color: _avatarStyle == 'square'
                        ? AppTheme.accent
                        : AppTheme.text1)),
            onPressed: () {
              Navigator.pop(ctx);
              _updateAvatarStyle('square');
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancel', style: AppTheme.label(color: AppTheme.red)),
          onPressed: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  void _updateAvatarStyle(String style) {
    Storage.saveData('avatar_style', style);
    setState(() {
      _avatarStyle = style;
    });
    AppTheme.showSnackBar(context, 'Avatar style updated!');
  }

  Future<void> _launchAboutWebsite() async {
    final Uri url = Uri.parse('https://sologainz.netlify.app');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        AppTheme.showSnackBar(context, 'Could not open website', isError: true);
      }
    }
  }

  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.glassLight,
                border: Border(
                    top: BorderSide(color: AppTheme.glassBorder, width: 1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Help & Support', style: AppTheme.h2()),
                  const SizedBox(height: 8),
                  Text(
                      'Have a problem or suggestion? Contact our team directly.',
                      style: AppTheme.body()),
                  const SizedBox(height: 24),
                  SGCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.elevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.email_outlined,
                              color: AppTheme.accent),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email Support', style: AppTheme.label()),
                              Text('originalsadiqteam@gmail.com',
                                  style: AppTheme.caption()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SGButton(
                    label: 'SEND EMAIL',
                    icon: Icons.send,
                    onTap: () {
                      Navigator.pop(ctx);
                      _contactSupport();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle,
      {VoidCallback? onTap}) {
    return SGTouchable(
      onTap: onTap ?? () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: SGCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.glassMedium,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppTheme.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.h3()),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTheme.caption()),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSettingItem(IconData icon, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: SGCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.glassMedium,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppTheme.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.h3()),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTheme.caption()),
                ],
              ),
            ),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppTheme.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.h1(color: AppTheme.white).copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.caption(color: AppTheme.muted).copyWith(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Storage.getCurrentUser() ?? 'Unknown';
    if (_s == null) return const Center(child: CircularProgressIndicator());
    final s = _s!;

    return CustomScrollView(
      physics: ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                          Text('Profile', style: AppTheme.h2()),
                          const SizedBox(height: 4),
                          Text('Account & achievements.',
                              style: AppTheme.caption()),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Top Profile Identity
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      onTapDown: (_) => _startLongPressTimer(),
                      onTapUp: (_) => _cancelLongPressTimer(),
                      onTapCancel: () => _cancelLongPressTimer(),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: _avatarStyle == 'circle'
                                  ? BoxShape.circle
                                  : BoxShape.rectangle,
                              borderRadius: _avatarStyle == 'circle'
                                  ? null
                                  : BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  spreadRadius: -5,
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: _avatarStyle == 'circle'
                                  ? BorderRadius.circular(50)
                                  : BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.glassLight,
                                    border: Border.all(
                                        color: AppTheme.accent
                                            .withValues(alpha: 0.5),
                                        width: 1),
                                    shape: _avatarStyle == 'circle'
                                        ? BoxShape.circle
                                        : BoxShape.rectangle,
                                    borderRadius: _avatarStyle == 'circle'
                                        ? null
                                        : BorderRadius.circular(24),
                                    image: _profileImagePath.isNotEmpty
                                        ? DecorationImage(
                                            image: _profileImagePath
                                                    .startsWith('http')
                                                ? NetworkImage(
                                                        _profileImagePath)
                                                    as ImageProvider
                                                : FileImage(
                                                    File(_profileImagePath)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _profileImagePath.isEmpty
                                      ? Center(
                                          child: Text(
                                            user.isNotEmpty
                                                ? user[0].toUpperCase()
                                                : 'U',
                                            style: AppTheme.h1(
                                                    color: AppTheme.accent)
                                                .copyWith(fontSize: 40),
                                          ),
                                        )
                                      : _loading
                                          ? const Center(
                                              child: CircularProgressIndicator(
                                                  color: AppTheme.accent))
                                          : null,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.glassLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppTheme.glassBorder, width: 1),
                          ),
                          child: Text(
                            user.toUpperCase(),
                            style: AppTheme.h2().copyWith(letterSpacing: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Status Window Header
              const SGSectionHeader(title: 'STATUS WINDOW'),
              const SizedBox(height: 8),

              // RPG Attributes Grid
              SGCard(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  children: [
                    _buildAttributeRow('STRENGTH', _calculateStrength(s),
                        Icons.fitness_center),
                    const SizedBox(height: 12),
                    _buildAttributeRow(
                        'AGILITY', _calculateAgility(s), Icons.speed),
                    const SizedBox(height: 12),
                    _buildAttributeRow('VITALITY', _calculateVitality(s),
                        Icons.favorite_rounded),
                    const SizedBox(height: 12),
                    _buildAttributeRow('INTELLIGENCE',
                        _calculateIntelligence(s), Icons.psychology),
                    const SizedBox(height: 12),
                    _buildAttributeRow('SENSE', _calculateSense(s),
                        Icons.remove_red_eye_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Settings Items
              const SGSectionHeader(title: 'GENERAL'),
              _buildSettingItem(
                Icons.manage_accounts,
                'Profile Settings',
                'Manage your display name and avatar',
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) =>
                        AccountSettingsPage(onLogout: widget.onLogout),
                  ),
                ),
              ),
              _buildToggleSettingItem(
                Icons.auto_awesome_motion_outlined,
                'Floating Navbar',
                'Toggle floating or fixed dock',
                Storage.isNavbarFloating(),
                (v) async {
                  await Storage.setNavbarFloating(v);
                  if (mounted) setState(() {});
                },
              ),

              _buildSettingItem(
                Icons.language,
                'Language',
                'English',
              ),

              const SizedBox(height: 24),
              const SGSectionHeader(title: 'SUPPORT'),
              _buildSettingItem(
                Icons.help_outline,
                'Help & Support',
                'FAQ and contact',
                onTap: _showHelpSheet,
              ),
              _buildSettingItem(
                Icons.info_outline,
                'About Solo Gainz',
                'Pre Alpha',
                onTap: _launchAboutWebsite,
              ),

              const SizedBox(height: 36),

              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  double _calculateStrength(UserStats s) {
    final pushups = (s.lifetimeStats ?? {})['pushups'] ?? 0;
    final squats = (s.lifetimeStats ?? {})['squats'] ?? 0;
    final bench = (s.lifetimeStats ?? {})['bench_press'] ?? 0;
    return (pushups * 0.5 + squats * 0.3 + bench * 0.8 + 10)
        .toDouble()
        .clamp(10.0, 999.0);
  }

  double _calculateAgility(UserStats s) {
    final running = ((s.lifetimeStats ?? {})['running'] ?? 0) / 60;
    final jacks = ((s.lifetimeStats ?? {})['jumping_jacks'] ?? 0) / 60;
    final sprints = ((s.lifetimeStats ?? {})['sprints'] ?? 0) / 30;
    return (running * 1.5 + jacks * 2.0 + sprints * 5.0 + 10)
        .toDouble()
        .clamp(10.0, 999.0);
  }

  double _calculateVitality(UserStats s) {
    final plank = ((s.lifetimeStats ?? {})['plank'] ?? 0) / 60;
    final situps = (s.lifetimeStats ?? {})['situps'] ?? 0;
    final wall = ((s.lifetimeStats ?? {})['wall_sit'] ?? 0) / 60;
    return (plank * 5.0 + situps * 0.4 + wall * 3.0 + 10)
        .toDouble()
        .clamp(10.0, 999.0);
  }

  double _calculateIntelligence(UserStats s) {
    final quests = (s.lifetimeStats ?? {})['total_completed'] ?? 0;
    return (quests * 1.2 + 10).toDouble().clamp(10.0, 999.0);
  }

  double _calculateSense(UserStats s) {
    final boxing = ((s.lifetimeStats ?? {})['shadow_boxing'] ?? 0) / 60;
    final burpees = (s.lifetimeStats ?? {})['burpees'] ?? 0;
    return (boxing * 4.0 + burpees * 2.0 + 10).toDouble().clamp(10.0, 999.0);
  }

  Widget _buildAttributeRow(String name, double value, IconData icon) {
    final progress = (value / 999).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.accent),
            const SizedBox(width: 10),
            Text(name, style: AppTheme.label(color: AppTheme.text1)),
            const Spacer(),
            Text(
              value.toInt().toString(),
              style: AppTheme.mono(color: AppTheme.accent, size: 14)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
