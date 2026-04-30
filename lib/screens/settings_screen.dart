import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storage.dart';
import '../theme/theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Support', style: AppTheme.h2()),
            const SizedBox(height: 8),
            Text('Need help or found a bug? Send us an email.', style: AppTheme.body()),
            const SizedBox(height: 24),
            SGButton(
              label: 'EMAIL US',
              icon: Icons.mail,
              onTap: () {
                Navigator.pop(ctx);
                _contactSupport();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _contactSupport() async {
    final Uri uri = Uri(scheme: 'mailto', path: 'originalsadiqteam@gmail.com', query: 'subject=Solo Gainz Support');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchAbout() async {
    final Uri url = Uri.parse('https://sologainz.netlify.app');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: AppTheme.caption(color: AppTheme.text2).copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.h3().copyWith(fontSize: 16, color: isDestructive ? color : null)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTheme.caption(color: AppTheme.muted)),
                ],
              ),
            ),
            if (trailing != null) trailing
            else if (onTap != null) Icon(Icons.chevron_right, size: 20, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 64, right: 16),
      child: Divider(color: AppTheme.line, height: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                      children: [
                        SGTouchable(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.line, width: 1),
                            ),
                            child: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.text1),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Settings', style: AppTheme.h2()),
                            const SizedBox(height: 4),
                            Text('App preferences & system.', style: AppTheme.caption()),
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
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('INTERFACE'),
                SGCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.auto_awesome_motion,
                        title: 'Floating Interface',
                        subtitle: 'Enable beautiful aura effects',
                        color: AppTheme.cyan,
                        trailing: CupertinoSwitch(
                          value: Storage.isNavbarFloating(),
                          activeTrackColor: AppTheme.accent,
                          onChanged: (v) async {
                            await Storage.setNavbarFloating(v);
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                _buildSectionHeader('SYSTEM'),
                SGCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.help_outline,
                        title: 'Support',
                        subtitle: 'Contact us or view FAQs',
                        color: AppTheme.amber,
                        onTap: _showHelp,
                      ),
                      _buildDivider(),
                      _buildSettingItem(
                        icon: Icons.info_outline,
                        title: 'About',
                        subtitle: 'Version 1.0.0-Alpha',
                        color: AppTheme.purple,
                        onTap: _launchAbout,
                      ),
                    ],
                  ),
                ),



                const SizedBox(height: 60),
                Center(
                  child: Text(
                    'All progress is stored locally on this device.',
                    style: AppTheme.caption(color: AppTheme.muted),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
