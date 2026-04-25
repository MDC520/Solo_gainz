import 'package:flutter/cupertino.dart';
import '../background.dart';
import '../models/user_stats.dart';
import '../services/storage.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../widgets/rank_shield.dart';

class Country {
  final String name;
  final String flag;
  const Country(this.name, this.flag);

  @override
  String toString() => '$flag $name';
}

class LoginScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  const LoginScreen({super.key, required this.onSuccess});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _loginNameCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _signUpNameCtrl = TextEditingController();
  final _signUpPassCtrl = TextEditingController();
  Country? _country;
  int _tab = 0; // 0=in 1=up
  bool _loading = false;
  bool _obscure = true;
  String? _userStatus;
  String? _error;

  late AnimationController _ctrl;
  late Animation<double> _fade;

  static const _countries = [
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

  bool get _signUp => _tab == 1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this)
      ..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _signUpNameCtrl.addListener(_checkUser);
    _loginNameCtrl.addListener(_checkUser);
  }

  Future<void> _checkUser() async {
    final text = _signUp ? _signUpNameCtrl.text : _loginNameCtrl.text;
    if (text.isNotEmpty) {
      final exists = await _auth.checkUsernameExists(text);
      if (mounted) {
        setState(() {
          if (_signUp) {
            _userStatus = exists ? 'taken' : 'ok';
          } else {
            _userStatus = exists ? 'ok' : 'missing';
          }
        });
      }
    } else {
      if (mounted) setState(() => _userStatus = null);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    if (_signUp) {
      if (_signUpPassCtrl.text.length < 6) {
        _err('Password must be at least 6 characters');
        return;
      }
      if (_country == null) {
        _err('Please select your country');
        return;
      }
      if (_userStatus != 'ok') {
        _err('Username is not available');
        return;
      }
      final r = await _auth.signUp(
          _signUpNameCtrl.text, _signUpPassCtrl.text, _country!.name);
      _handle(r);
    } else {
      final r = await _auth.signIn(_loginNameCtrl.text, _loginPassCtrl.text);
      _handle(r);
    }
  }

  Map? _loggedInUser;

  void _handle(Map r) {
    if (r['success'] == true) {
      if (r['user'] != null) {
        if (mounted) {
          setState(() {
            _loggedInUser = r['user'];
            _loading = false;
          });
        }
      } else {
        if (mounted) widget.onSuccess();
      }
    } else {
      _err(r['message'] ?? 'Something went wrong');
    }
  }

  Future<void> _finalizeLogin() async {
    if (_loggedInUser == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Clear everything to start clean
      await Storage.clearAll();
      await Storage.init();

      final u = _loggedInUser!;
      final username = u['username'];

      // 2. Fetch fresh data from cloud to ensure it's 100% up to date
      // This also acts as a connection check
      final userData = await _auth.client
          .from('user_data')
          .select()
          .eq('username', username)
          .maybeSingle();

      final userBase = await _auth.client
          .from('users')
          .select()
          .eq('username', username)
          .maybeSingle();

      if (userData == null || userBase == null) {
        throw 'Sync failed: Cloud data missing';
      }

      // 3. Save base info
      await Storage.saveData('current_user', username);
      await Storage.saveData('current_country', userBase['country']);
      await Storage.saveData('is_logged_in', true);

      // 4. Initialize and Save UserStats
      final stats = UserStats(
        coins: userData['coins'] ?? 0,
        progress: userData['progress'] ?? 0,
        rank: userData['rank'] ?? 'E',
        level: userData['level'] ?? 1,
        xp: userData['xp'] ?? 0,
      );
      await Storage.saveUserStats(stats);

      // 5. Save Avatar if exists
      if (userData['avatar_url'] != null) {
        await Storage.saveData('profile_image_path', userData['avatar_url']);
      }

      // Small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) widget.onSuccess();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed: Need stable connection to sync data';
        });
      }
    }
  }

  void _err(String msg) {
    if (mounted) {
      setState(() {
        _error = msg;
        _loading = false;
      });
    }
  }

  void _showPicker() {
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
                border: Border.all(color: AppTheme.line, width: 1),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
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
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close,
                                size: 20, color: AppTheme.text2),
                          ),
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
                        border: Border.all(color: AppTheme.line),
                      ),
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
                              hintStyle: AppTheme.body(color: AppTheme.text2),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
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
                        final isSelected = country == _country;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: SGTouchable(
                            onTap: () {
                              setState(() => _country = country);
                              Navigator.pop(context);
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
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(country.flag,
                                      style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(country.name,
                                        style: AppTheme.body(
                                            color: isSelected
                                                ? AppTheme.text1
                                                : AppTheme.text1
                                                    .withValues(alpha: 0.8))),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle,
                                        size: 20, color: AppTheme.accent),
                                ],
                              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: LivelyBackground(
        child: FadeTransition(
          opacity: _fade,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 30),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_loggedInUser != null)
                              SGCard(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 40),
                                child: _welcomeView(),
                              )
                            else
                              SGCard(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 32),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_signUp ? 'Create Account' : 'Sign In',
                                        style: AppTheme.h1()),
                                    const SizedBox(height: 8),
                                    Text(
                                        _signUp
                                            ? 'Join Solo Gainz.'
                                            : 'Good to have you back.',
                                        style: AppTheme.body()),
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      width: double.infinity,
                                      child:
                                          CupertinoSlidingSegmentedControl<int>(
                                        backgroundColor: AppTheme.bg,
                                        thumbColor: AppTheme.elevated,
                                        groupValue: _tab,
                                        onValueChanged: (v) {
                                          if (v != null) {
                                            setState(() {
                                              _tab = v;
                                              _error = null;
                                              _userStatus = null;
                                            });
                                          }
                                        },
                                        children: {
                                          0: _seg('Sign In', 0),
                                          1: _seg('Sign Up', 1),
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    _fieldLabel('Username'),
                                    const SizedBox(height: 8),
                                    _field(
                                        ctrl: _signUp
                                            ? _signUpNameCtrl
                                            : _loginNameCtrl,
                                        hint: 'Enter username',
                                        trail: _userStatus != null &&
                                                (_signUp
                                                        ? _signUpNameCtrl
                                                        : _loginNameCtrl)
                                                    .text
                                                    .isNotEmpty
                                            ? Icon(
                                                _userStatus == 'ok'
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                size: 16,
                                                color: _userStatus == 'ok'
                                                    ? AppTheme.green
                                                    : AppTheme.red)
                                            : null),
                                    const SizedBox(height: 18),
                                    _fieldLabel('Password'),
                                    const SizedBox(height: 8),
                                    _field(
                                        ctrl: _signUp
                                            ? _signUpPassCtrl
                                            : _loginPassCtrl,
                                        hint: _signUp
                                            ? 'Min 6 characters'
                                            : 'Enter password',
                                        obscure: _obscure,
                                        trail: SGTouchable(
                                            onTap: () => setState(
                                                () => _obscure = !_obscure),
                                            child: Icon(
                                                _obscure
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                size: 16,
                                                color: AppTheme.text2))),
                                    if (_signUp) ...[
                                      const SizedBox(height: 18),
                                      _fieldLabel('Country'),
                                      const SizedBox(height: 8),
                                      SGTouchable(
                                        onTap: _showPicker,
                                        child: Container(
                                          height: 48,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14),
                                          decoration: BoxDecoration(
                                              color: AppTheme.bg,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: AppTheme.line)),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                    _country?.toString() ??
                                                        'Select country',
                                                    style: AppTheme.body(
                                                        color: _country != null
                                                            ? AppTheme.text1
                                                            : AppTheme.text2)),
                                              ),
                                              Icon(Icons.keyboard_arrow_down,
                                                  size: 18,
                                                  color: AppTheme.text2),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (_error != null) ...[
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                            color: AppTheme.surface,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: AppTheme.red)),
                                        child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 1),
                                                  child: Icon(Icons.error,
                                                      size: 14,
                                                      color: AppTheme.red)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: Text(_error!,
                                                      style: AppTheme.caption(
                                                          color:
                                                              AppTheme.red))),
                                            ]),
                                      ),
                                    ],
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      width: double.infinity,
                                      child: SGButton(
                                        label: _signUp
                                            ? 'Create Account'
                                            : 'Sign In',
                                        onTap: _submit,
                                        loading: _loading,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _seg(String t, int i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(t,
            style: AppTheme.label(
                color: _tab == i ? AppTheme.text1 : AppTheme.text2),
            textAlign: TextAlign.center),
      );

  Widget _fieldLabel(String t) => Text(t.toUpperCase(),
      style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.text2,
          letterSpacing: 0.8));

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    bool obscure = false,
    Widget? trail,
  }) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.line)),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        Expanded(
            child: CupertinoTextField(
          controller: ctrl,
          obscureText: obscure,
          enabled: !_loading,
          placeholder: hint,
          placeholderStyle: AppTheme.body(),
          style: AppTheme.body(color: AppTheme.text1),
          padding: EdgeInsets.zero,
          decoration: const BoxDecoration(),
          cursorColor: AppTheme.accent,
          cursorWidth: 1.5,
        )),
        if (trail != null) ...[const SizedBox(width: 10), trail],
      ]),
    );
  }

  String _greeting() {
    if (_signUp) return 'Welcome';
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _welcomeView() {
    final u = _loggedInUser!;
    final avatar = u['avatar_url'];
    final stats = u['stats'] ?? {};
    final rank = stats['rank'] ?? 'E';

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(_greeting(), style: AppTheme.h1()),
          const SizedBox(height: 8),
          Text('Ready to continue your journey?', style: AppTheme.body()),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Animated Pulsing Glow (simplified with a static one but better colors)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.2),
                      AppTheme.accent.withValues(alpha: 0.05),
                      AppTheme.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              // Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.elevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accent, width: 1),
                  image: avatar != null
                      ? DecorationImage(
                          image: NetworkImage(avatar), fit: BoxFit.cover)
                      : null,
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.3),
                        blurRadius: 25,
                        spreadRadius: -2),
                  ],
                ),
                child: avatar == null
                    ? Center(
                        child: Text(u['username'][0].toUpperCase(),
                            style: AppTheme.h1(color: Colors.white)
                                .copyWith(fontSize: 44)))
                    : null,
              ),
              // Rank Badge
              Positioned(
                bottom: -2,
                right: -2,
                child: RankShield(rank: rank, size: 46),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(u['username'],
              style: AppTheme.h1().copyWith(fontSize: 24, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on,
                  size: 14, color: AppTheme.text2.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(u['country'] ?? '',
                  style: AppTheme.body(color: AppTheme.text2)),
            ],
          ),
          if (!_signUp && u['stats'] != null) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.line.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _stat(Icons.monetization_on,
                      stats['coins']?.toString() ?? '0', AppTheme.amber),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.red.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, size: 16, color: AppTheme.red),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_error!,
                          style: AppTheme.caption(color: AppTheme.red))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: SGButton(
              label: 'Sync & Continue',
              onTap: _finalizeLogin,
              loading: _loading,
            ),
          ),
          const SizedBox(height: 20),
          SGTouchable(
            onTap: () => setState(() => _loggedInUser = null),
            child: Text('Not you? Switch account',
                style: AppTheme.caption(color: AppTheme.accent)
                    .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2)),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String val, Color color) => Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(val, style: AppTheme.h3()),
        ],
      );

  Widget _sep() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 16,
        width: 1,
        color: AppTheme.line,
      );

  @override
  void dispose() {
    _ctrl.dispose();
    _loginNameCtrl.dispose();
    _loginPassCtrl.dispose();
    _signUpNameCtrl.dispose();
    _signUpPassCtrl.dispose();
    super.dispose();
  }
}
