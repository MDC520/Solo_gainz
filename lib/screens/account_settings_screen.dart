import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/auth_service.dart';
import '../services/storage.dart';
import '../theme/theme.dart';
import '../screens/login_screen.dart' show Country;

class AccountSettingsPage extends StatefulWidget {
  final VoidCallback onLogout;
  const AccountSettingsPage({super.key, required this.onLogout});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

const _countries = [
  Country('Afghanistan', '🇦🇫'),
  Country('Albania', '🇦🇱'),
  Country('Algeria', '🇩🇿'),
  Country('Andorra', '🇦🇩'),
  Country('Angola', '🇦🇴'),
  Country('Antigua and Barbuda', '🇦🇬'),
  Country('Argentina', '🇦🇷'),
  Country('Armenia', '🇦🇲'),
  Country('Australia', '🇦🇺'),
  Country('Austria', '🇦🇹'),
  Country('Azerbaijan', '🇦🇿'),
  Country('Bahamas', '🇧🇸'),
  Country('Bahrain', '🇧🇭'),
  Country('Bangladesh', '🇧🇩'),
  Country('Barbados', '🇧🇧'),
  Country('Belarus', '🇧🇾'),
  Country('Belgium', '🇧🇪'),
  Country('Belize', '🇧🇿'),
  Country('Benin', '🇧🇯'),
  Country('Bhutan', '🇧🇹'),
  Country('Bolivia', '🇧🇴'),
  Country('Bosnia and Herzegovina', '🇧🇦'),
  Country('Botswana', '🇧🇼'),
  Country('Brazil', '🇧🇷'),
  Country('Brunei', '🇧🇳'),
  Country('Bulgaria', '🇧🇬'),
  Country('Burkina Faso', '🇧🇫'),
  Country('Burundi', '🇧🇮'),
  Country('Cabo Verde', '🇨🇻'),
  Country('Cambodia', '🇰🇭'),
  Country('Cameroon', '🇨🇲'),
  Country('Canada', '🇨🇦'),
  Country('Central African Republic', '🇨🇫'),
  Country('Chad', '🇹🇩'),
  Country('Chile', '🇨🇱'),
  Country('China', '🇨🇳'),
  Country('Colombia', '🇨🇴'),
  Country('Comoros', '🇰🇲'),
  Country('Congo', '🇨🇬'),
  Country('Costa Rica', '🇨🇷'),
  Country('Croatia', '🇭🇷'),
  Country('Cuba', '🇨🇺'),
  Country('Cyprus', '🇨🇾'),
  Country('Czech Republic', '🇨🇿'),
  Country('Denmark', '🇩🇰'),
  Country('Djibouti', '🇩🇯'),
  Country('Dominica', '🇩🇲'),
  Country('Dominican Republic', '🇩🇴'),
  Country('Ecuador', '🇪🇨'),
  Country('Egypt', '🇪🇬'),
  Country('El Salvador', '🇸🇻'),
  Country('Equatorial Guinea', '🇬🇶'),
  Country('Eritrea', '🇪🇷'),
  Country('Estonia', '🇪🇪'),
  Country('Eswatini', '🇸🇿'),
  Country('Ethiopia', '🇪🇹'),
  Country('Fiji', '🇫🇯'),
  Country('Finland', '🇫🇮'),
  Country('France', '🇫🇷'),
  Country('Gabon', '🇬🇦'),
  Country('Gambia', '🇬🇲'),
  Country('Georgia', '🇬🇪'),
  Country('Germany', '🇩🇪'),
  Country('Ghana', '🇬🇭'),
  Country('Greece', '🇬🇷'),
  Country('Grenada', '🇬🇩'),
  Country('Guatemala', '🇬🇹'),
  Country('Guinea', '🇬🇳'),
  Country('Guinea-Bissau', '🇬🇼'),
  Country('Guyana', '🇬🇾'),
  Country('Haiti', '🇭🇹'),
  Country('Honduras', '🇭🇳'),
  Country('Hungary', '🇭🇺'),
  Country('Iceland', '🇮🇸'),
  Country('India', '🇮🇳'),
  Country('Indonesia', '🇮🇩'),
  Country('Iran', '🇮🇷'),
  Country('Iraq', '🇮🇶'),
  Country('Ireland', '🇮🇪'),
  Country('Israel', '🇮🇱'),
  Country('Italy', '🇮🇹'),
  Country('Jamaica', '🇯🇲'),
  Country('Japan', '🇯🇵'),
  Country('Jordan', '🇯🇴'),
  Country('Kazakhstan', '🇰🇿'),
  Country('Kenya', '🇰🇪'),
  Country('Kiribati', '🇰🇮'),
  Country('Kuwait', '🇰🇼'),
  Country('Kyrgyzstan', '🇰🇬'),
  Country('Laos', '🇱🇦'),
  Country('Latvia', '🇱🇻'),
  Country('Lebanon', '🇱🇧'),
  Country('Lesotho', '🇱🇸'),
  Country('Liberia', '🇱🇷'),
  Country('Libya', '🇱🇾'),
  Country('Liechtenstein', '🇱🇮'),
  Country('Lithuania', '🇱🇹'),
  Country('Luxembourg', '🇱🇺'),
  Country('Madagascar', '🇲🇬'),
  Country('Malawi', '🇲🇼'),
  Country('Malaysia', '🇲🇾'),
  Country('Maldives', '🇲🇻'),
  Country('Mali', '🇲🇱'),
  Country('Malta', '🇲🇹'),
  Country('Marshall Islands', '🇲🇭'),
  Country('Mauritania', '🇲🇷'),
  Country('Mauritius', '🇲🇺'),
  Country('Mexico', '🇲🇽'),
  Country('Micronesia', '🇫🇲'),
  Country('Moldova', '🇲🇩'),
  Country('Monaco', '🇲🇨'),
  Country('Mongolia', '🇲🇳'),
  Country('Montenegro', '🇲🇪'),
  Country('Morocco', '🇲🇦'),
  Country('Mozambique', '🇲🇿'),
  Country('Myanmar', '🇲🇲'),
  Country('Namibia', '🇳🇦'),
  Country('Nauru', '🇳🇷'),
  Country('Nepal', '🇳🇵'),
  Country('Netherlands', '🇳🇱'),
  Country('New Zealand', '🇳🇿'),
  Country('Nicaragua', '🇳🇮'),
  Country('Niger', '🇳🇪'),
  Country('Nigeria', '🇳🇬'),
  Country('North Korea', '🇰🇵'),
  Country('North Macedonia', '🇲🇰'),
  Country('Norway', '🇳🇴'),
  Country('Oman', '🇴🇲'),
  Country('Pakistan', '🇵🇰'),
  Country('Palau', '🇵🇼'),
  Country('Panama', '🇵🇦'),
  Country('Papua New Guinea', '🇵🇬'),
  Country('Paraguay', '🇵🇾'),
  Country('Peru', '🇵🇪'),
  Country('Philippines', '🇵🇭'),
  Country('Poland', '🇵🇱'),
  Country('Portugal', '🇵🇹'),
  Country('Qatar', '🇶🇦'),
  Country('Romania', '🇷🇴'),
  Country('Russia', '🇷🇺'),
  Country('Rwanda', '🇷🇼'),
  Country('Saint Kitts and Nevis', '🇰🇳'),
  Country('Saint Lucia', '🇱🇨'),
  Country('Saint Vincent and the Grenadines', '🇻🇨'),
  Country('Samoa', '🇼🇸'),
  Country('San Marino', '🇸🇲'),
  Country('Sao Tome and Principe', '🇸🇹'),
  Country('Saudi Arabia', '🇸🇦'),
  Country('Senegal', '🇸🇳'),
  Country('Serbia', '🇷🇸'),
  Country('Seychelles', '🇸🇨'),
  Country('Sierra Leone', '🇸🇱'),
  Country('Singapore', '🇸🇬'),
  Country('Slovakia', '🇸🇰'),
  Country('Slovenia', '🇸🇮'),
  Country('Solomon Islands', '🇸🇧'),
  Country('Somalia', '🇸🇴'),
  Country('South Africa', '🇿🇦'),
  Country('South Korea', '🇰🇷'),
  Country('South Sudan', '🇸🇸'),
  Country('Spain', '🇪🇸'),
  Country('Sri Lanka', '🇱🇰'),
  Country('Sudan', '🇸🇩'),
  Country('Suriname', '🇸🇷'),
  Country('Sweden', '🇸🇪'),
  Country('Switzerland', '🇨🇭'),
  Country('Syria', '🇸🇾'),
  Country('Taiwan', '🇹🇼'),
  Country('Tajikistan', '🇹🇯'),
  Country('Tanzania', '🇹🇿'),
  Country('Thailand', '🇹🇭'),
  Country('Timor-Leste', '🇹🇱'),
  Country('Togo', '🇹🇬'),
  Country('Tonga', '🇹🇴'),
  Country('Trinidad and Tobago', '🇹🇹'),
  Country('Tunisia', '🇹🇳'),
  Country('Turkey', '🇹🇷'),
  Country('Turkmenistan', '🇹🇲'),
  Country('Tuvalu', '🇹🇻'),
  Country('Uganda', '🇺🇬'),
  Country('Ukraine', '🇺🇦'),
  Country('United Arab Emirates', '🇦🇪'),
  Country('United Kingdom', '🇬🇧'),
  Country('United States', '🇺🇸'),
  Country('Uruguay', '🇺🇾'),
  Country('Uzbekistan', '🇺🇿'),
  Country('Vanuatu', '🇻🇺'),
  Country('Vatican City', '🇻🇦'),
  Country('Venezuela', '🇻🇪'),
  Country('Vietnam', '🇻🇳'),
  Country('Yemen', '🇾🇪'),
  Country('Zambia', '🇿🇲'),
  Country('Zimbabwe', '🇿🇼'),
];

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  String _profileImagePath = '';
  String _avatarStyle = 'circle';
  bool _loading = false;
  String _createdAt = 'Loading...';
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _profileImagePath = Storage.getData('profile_image_path', defaultValue: '');
    _avatarStyle = Storage.getData('avatar_style', defaultValue: 'circle');
    _isVerified = Storage.getData('is_verified', defaultValue: false);
    _loadCreatedAt();
  }

  Future<void> _loadCreatedAt() async {
    final user = Storage.getCurrentUser() ?? '';
    final date = await AuthService().getAccountCreatedAt(user);
    if (date != null && mounted) {
      final DateTime dt = DateTime.parse(date);
      setState(() {
        _createdAt =
            "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      });
    } else {
      if (mounted) setState(() => _createdAt = 'Unknown');
    }
  }

  void _showSignOutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Sign Out', style: AppTheme.h3()),
        content:
            Text('Are you sure you want to sign out?', style: AppTheme.body()),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: AppTheme.body(color: AppTheme.text2)),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Sign Out', style: AppTheme.label(color: AppTheme.red)),
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await AuthService().logout();
              widget.onLogout();
            },
          ),
        ],
      ),
    );
  }

  void _editField(String title, String fieldKey, String currentValue) {
    final TextEditingController controller =
        TextEditingController(text: currentValue);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Edit $title', style: AppTheme.h3()),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: CupertinoTextField(
            controller: controller,
            style: const TextStyle(color: Colors.black),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.line, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            obscureText: fieldKey == 'password',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: AppTheme.body(color: AppTheme.text2)),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            child: Text('Save', style: AppTheme.label(color: AppTheme.accent)),
            onPressed: () async {
              Navigator.pop(ctx);
              final newValue = controller.text.trim();
              if (newValue.isNotEmpty && newValue != currentValue) {
                setState(() => _loading = true);
                final user = Storage.getCurrentUser() ?? '';
                bool success = false;
                if (fieldKey == 'username') {
                  success = await AuthService()
                      .updateUserInfo(user, newUsername: newValue);
                } else if (fieldKey == 'country') {
                  success = await AuthService()
                      .updateUserInfo(user, newCountry: newValue);
                } else if (fieldKey == 'password') {
                  success = await AuthService()
                      .updateUserInfo(user, newPassword: newValue);
                }
                if (mounted) setState(() => _loading = false);
                if (success && mounted) {
                  AppTheme.showSnackBar(
                      context, '$title updated successfully!');
                } else if (mounted) {
                  AppTheme.showSnackBar(context, 'Failed to update $title',
                      isError: true);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCountryPicker(String currentCountry) {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCountries = searchQuery.isEmpty
                ? _countries
                : _countries
                    .where((country) => country.name
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase()))
                    .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                  color: AppTheme.bg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: AppTheme.line, width: 1)),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppTheme.line,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: AppTheme.line, width: 1))),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Country', style: AppTheme.h2()),
                        SGTouchable(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  shape: BoxShape.circle),
                              child: Icon(Icons.close,
                                  size: 20, color: AppTheme.text2)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.line, width: 1)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        Icon(Icons.search, size: 20, color: AppTheme.text2),
                        const SizedBox(width: 12),
                        Expanded(
                            child: TextField(
                                onChanged: (v) =>
                                    setModalState(() => searchQuery = v),
                                style: AppTheme.body(color: AppTheme.text1),
                                decoration: InputDecoration(
                                    hintText: 'Search...',
                                    hintStyle:
                                        AppTheme.body(color: AppTheme.text2),
                                    border: InputBorder.none,
                                    isDense: true))),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        final isSelected = country.name == currentCountry;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: SGTouchable(
                            onTap: () async {
                              Navigator.pop(context);
                              if (country.name != currentCountry) {
                                setState(() => _loading = true);
                                final user = Storage.getCurrentUser() ?? '';
                                final success = await AuthService()
                                    .updateUserInfo(user,
                                        newCountry: country.name);
                                if (mounted) setState(() => _loading = false);
                                if (success && mounted) {
                                  AppTheme.showSnackBar(
                                      context, 'Country updated successfully!');
                                } else if (mounted) {
                                  AppTheme.showSnackBar(
                                      context, 'Failed to update Country',
                                      isError: true);
                                }
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.elevated
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isSelected
                                          ? AppTheme.accent
                                          : Colors.transparent,
                                      width: 1)),
                              child: Row(children: [
                                Text(country.flag,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: Text(country.name,
                                        style: AppTheme.body(
                                            color: isSelected
                                                ? AppTheme.text1
                                                : AppTheme.text1
                                                    .withValues(alpha: 0.8)))),
                                if (isSelected)
                                  Icon(Icons.check_circle,
                                      size: 20, color: AppTheme.accent)
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _verifyAccount() {
    final TextEditingController controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Verify Account', style: AppTheme.h3()),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Enter verification code',
            style: const TextStyle(color: Colors.black),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.line, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel', style: AppTheme.body(color: AppTheme.text2)),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            child:
                Text('Verify', style: AppTheme.label(color: AppTheme.accent)),
            onPressed: () async {
              Navigator.pop(ctx);
              if (controller.text.trim() == 'MDC3MK') {
                await Storage.saveData('is_verified', true);
                if (mounted) {
                  setState(() => _isVerified = true);
                  AppTheme.showSnackBar(context, 'Account verified!');
                }
              } else if (mounted) {
                AppTheme.showSnackBar(context, 'Invalid code', isError: true);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _changePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);

    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop Picture',
              toolbarColor: AppTheme.bg,
              toolbarWidgetColor: Colors.white,
              activeControlsWidgetColor: AppTheme.accent),
          IOSUiSettings(title: 'Crop Picture', aspectRatioLockEnabled: true),
        ],
      );

      if (croppedFile != null) {
        setState(() => _loading = true);
        try {
          final user = Storage.getCurrentUser() ?? 'Unknown';
          if (Storage.isLoggedIn()) {
            final publicUrl =
                await AuthService().uploadAvatar(croppedFile.path, user);
            if (publicUrl != null) {
              setState(() => _profileImagePath = publicUrl);
              await Storage.saveData('profile_image_path', publicUrl);
            } else {
              setState(() => _profileImagePath = croppedFile.path);
              await Storage.saveData('profile_image_path', croppedFile.path);
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

  @override
  Widget build(BuildContext context) {
    final user = Storage.getCurrentUser() ?? 'User';
    final country = Storage.getData('current_country', defaultValue: 'Unknown');

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
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
                              border:
                                  Border.all(color: AppTheme.line, width: 1),
                            ),
                            child: Icon(Icons.arrow_back_ios_new,
                                size: 20, color: AppTheme.text1),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Account Settings', style: AppTheme.h2()),
                            const SizedBox(height: 4),
                            Text('Manage your personal data.',
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Identity Header
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Column(
                      children: [
                        _buildAvatar(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(user.toUpperCase(),
                                style:
                                    AppTheme.h2().copyWith(letterSpacing: 2)),
                            if (_isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 6.0),
                                child: Icon(Icons.verified,
                                    color: Colors.blue, size: 18),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('ID: ${user.hashCode.toString().padLeft(8, '0')}',
                            style:
                                AppTheme.mono(color: AppTheme.muted, size: 10)),
                      ],
                    ),
                  ),
                ),

                // Section: Profile Info
                _buildSectionHeader('PERSONAL INFORMATION'),
                SGCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildSettingsTile(
                          icon: Icons.person_outline,
                          label: 'Username',
                          value: user,
                          color: AppTheme.accent,
                          onTap: () =>
                              _editField('Username', 'username', user)),
                      _buildDivider(),
                      _buildSettingsTile(
                          icon: Icons.public_outlined,
                          label: 'Country / Region',
                          value: country,
                          color: AppTheme.cyan,
                          onTap: () => _showCountryPicker(country)),
                      _buildDivider(),
                      _buildSettingsTile(
                          icon: Icons.verified_user_outlined,
                          label: 'Account Status',
                          value:
                              _isVerified ? 'Verified Player' : 'Not Verified',
                          color: _isVerified ? Colors.blue : AppTheme.green,
                          onTap: _isVerified ? null : _verifyAccount),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                _buildSectionHeader('SECURITY'),
                SGCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildSettingsTile(
                          icon: Icons.lock_outline,
                          label: 'Password',
                          value: '••••••••',
                          color: AppTheme.amber,
                          onTap: () => _editField('Password', 'password', '')),
                      _buildDivider(),
                      _buildSettingsTile(
                          icon: Icons.history_edu_outlined,
                          label: 'Account Created',
                          value: _createdAt,
                          color: AppTheme.text2),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
                Center(
                    child: Text(
                        'All progress is stored locally on this device.',
                        style: AppTheme.caption(color: AppTheme.muted))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final user = Storage.getCurrentUser() ?? 'U';
    return SGTouchable(
      onTap: _changePicture,
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: _avatarStyle == 'circle'
                  ? BoxShape.circle
                  : BoxShape.rectangle,
              borderRadius:
                  _avatarStyle == 'circle' ? null : BorderRadius.circular(18),
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.accent, width: 1),
              image: _profileImagePath.isNotEmpty
                  ? DecorationImage(
                      image: _profileImagePath.startsWith('http')
                          ? NetworkImage(_profileImagePath)
                          : FileImage(File(_profileImagePath)) as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _profileImagePath.isEmpty
                ? Center(
                    child: Text(user[0].toUpperCase(),
                        style: AppTheme.h1(color: Colors.white)
                            .copyWith(fontSize: 32)))
                : _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration:
                  BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
              child: const Icon(Icons.edit, size: 12, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title,
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.text2,
              letterSpacing: 1.5)),
    );
  }

  Widget _buildDivider() => Padding(
      padding: const EdgeInsets.only(left: 54),
      child: Divider(color: AppTheme.line, height: 1));

  Widget _buildSettingsTile(
      {required IconData icon,
      required String label,
      required String value,
      required Color color,
      VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: color)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: AppTheme.caption(color: AppTheme.muted)
                          .copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(value, style: AppTheme.label().copyWith(fontSize: 14))
                ])),
            if (onTap != null)
              Icon(Icons.edit, size: 14, color: AppTheme.muted)
            else
              Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }
}
