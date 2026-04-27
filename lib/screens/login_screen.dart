import 'package:flutter/cupertino.dart';
import '../background.dart';
import '../services/auth_service.dart';
import '../services/storage.dart';
import '../services/data_serializer.dart';
import '../services/security_service.dart';
import '../theme/theme.dart';

// ── Country model ──────────────────────────────────────────────────
class Country {
  final String name;
  final String flag;
  const Country(this.name, this.flag);
  @override
  String toString() => '$flag $name';
}

class LoginScreen extends StatefulWidget {
  final VoidCallback onSignUpSuccess;
  final VoidCallback onSignInSuccess;
  const LoginScreen({
    super.key,
    required this.onSignUpSuccess,
    required this.onSignInSuccess,
  });

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
  int _tab = 0;
  bool _loading = false;
  bool _obscureLogin = true;
  bool _obscureSignUp = true;
  String? _userStatus;
  String? _error;

  late AnimationController _ctrl;
  late Animation<double> _fade;

  // Countries list (abbreviated — same full list as before)
  static const _countries = [
    Country('Afghanistan', '🇦🇫'),
    Country('Albania', '🇦🇱'),
    Country('Algeria', '🇩🇿'),
    Country('Andorra', '🇦🇩'),
    Country('Angola', '🇦🇴'),
    Country('Argentina', '🇦🇷'),
    Country('Armenia', '🇦🇲'),
    Country('Australia', '🇦🇺'),
    Country('Austria', '🇦🇹'),
    Country('Azerbaijan', '🇦🇿'),
    Country('Bahrain', '🇧🇭'),
    Country('Bangladesh', '🇧🇩'),
    Country('Belarus', '🇧🇾'),
    Country('Belgium', '🇧🇪'),
    Country('Bolivia', '🇧🇴'),
    Country('Bosnia and Herzegovina', '🇧🇦'),
    Country('Brazil', '🇧🇷'),
    Country('Bulgaria', '🇧🇬'),
    Country('Cambodia', '🇰🇭'),
    Country('Cameroon', '🇨🇲'),
    Country('Canada', '🇨🇦'),
    Country('Chile', '🇨🇱'),
    Country('China', '🇨🇳'),
    Country('Colombia', '🇨🇴'),
    Country('Croatia', '🇭🇷'),
    Country('Cuba', '🇨🇺'),
    Country('Czech Republic', '🇨🇿'),
    Country('Denmark', '🇩🇰'),
    Country('Ecuador', '🇪🇨'),
    Country('Egypt', '🇪🇬'),
    Country('Ethiopia', '🇪🇹'),
    Country('Finland', '🇫🇮'),
    Country('France', '🇫🇷'),
    Country('Georgia', '🇬🇪'),
    Country('Germany', '🇩🇪'),
    Country('Ghana', '🇬🇭'),
    Country('Greece', '🇬🇷'),
    Country('Guatemala', '🇬🇹'),
    Country('Hungary', '🇭🇺'),
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
    Country('Kuwait', '🇰🇼'),
    Country('Lebanon', '🇱🇧'),
    Country('Libya', '🇱🇾'),
    Country('Malaysia', '🇲🇾'),
    Country('Mexico', '🇲🇽'),
    Country('Morocco', '🇲🇦'),
    Country('Myanmar', '🇲🇲'),
    Country('Nepal', '🇳🇵'),
    Country('Netherlands', '🇳🇱'),
    Country('New Zealand', '🇳🇿'),
    Country('Nigeria', '🇳🇬'),
    Country('North Korea', '🇰🇵'),
    Country('Norway', '🇳🇴'),
    Country('Oman', '🇴🇲'),
    Country('Pakistan', '🇵🇰'),
    Country('Palestine', '🇵🇸'),
    Country('Panama', '🇵🇦'),
    Country('Peru', '🇵🇪'),
    Country('Philippines', '🇵🇭'),
    Country('Poland', '🇵🇱'),
    Country('Portugal', '🇵🇹'),
    Country('Qatar', '🇶🇦'),
    Country('Romania', '🇷🇴'),
    Country('Russia', '🇷🇺'),
    Country('Rwanda', '🇷🇼'),
    Country('Saudi Arabia', '🇸🇦'),
    Country('Senegal', '🇸🇳'),
    Country('Serbia', '🇷🇸'),
    Country('Singapore', '🇸🇬'),
    Country('Somalia', '🇸🇴'),
    Country('South Africa', '🇿🇦'),
    Country('South Korea', '🇰🇷'),
    Country('Spain', '🇪🇸'),
    Country('Sri Lanka', '🇱🇰'),
    Country('Sudan', '🇸🇩'),
    Country('Sweden', '🇸🇪'),
    Country('Switzerland', '🇨🇭'),
    Country('Syria', '🇸🇾'),
    Country('Taiwan', '🇹🇼'),
    Country('Tanzania', '🇹🇿'),
    Country('Thailand', '🇹🇭'),
    Country('Tunisia', '🇹🇳'),
    Country('Turkey', '🇹🇷'),
    Country('Uganda', '🇺🇬'),
    Country('Ukraine', '🇺🇦'),
    Country('United Arab Emirates', '🇦🇪'),
    Country('United Kingdom', '🇬🇧'),
    Country('United States', '🇺🇸'),
    Country('Uruguay', '🇺🇾'),
    Country('Uzbekistan', '🇺🇿'),
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
          _userStatus =
              _signUp ? (exists ? 'taken' : 'ok') : (exists ? 'ok' : 'missing');
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
      if (_signUpPassCtrl.text.length < 6)
        return _err('Password must be at least 6 characters');
      if (_country == null) return _err('Please select your country');
      if (_userStatus != 'ok') return _err('Username is not available');

      final r = await _auth.signUp(
          _signUpNameCtrl.text, _signUpPassCtrl.text, _country!.name);
      if (r['success'] == true) {
        await Storage.saveData('current_user', r['username']);
        await Storage.saveData('current_country', r['country']);
        await Storage.saveData('is_logged_in', true);
        await Storage.saveData('is_onboarded', false);
        if (mounted) widget.onSignUpSuccess();
      } else {
        _err(r['message'] ?? 'Something went wrong');
      }
    } else {
      final r = await _auth.signIn(_loginNameCtrl.text, _loginPassCtrl.text);
      if (r['success'] == true) {
        await _finalizeSignIn(r);
      } else {
        _err(r['message'] ?? 'Something went wrong');
      }
    }
  }

  Future<void> _finalizeSignIn(Map<String, dynamic> r) async {
    try {
      final username = r['username'] as String;
      final country = r['country'] as String? ?? '';
      final rawData = r['data'] as String? ?? '{}';

      await Storage.saveData('current_user', username);
      await Storage.saveData('current_country', country);
      await Storage.saveData('is_logged_in', true);
      await Storage.saveData('is_onboarded', true);

      // Decrypt + apply all cloud data
      final password = _loginPassCtrl.text;
      final jsonStr = rawData == '{}' || rawData.isEmpty
          ? rawData
          : SecurityService.decrypt(rawData, password);
      await DataSerializer.decodeAndApplyData(jsonStr);

      AppTheme.success();
      if (mounted) widget.onSignInSuccess();
    } catch (e) {
      _err('Failed to load your data. Please try again.');
    }
  }

  void _err(String msg) {
    if (mounted)
      setState(() {
        _error = msg;
        _loading = false;
      });
  }

  void _showPicker() {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = searchQuery.isEmpty
              ? _countries
              : _countries
                  .where((c) =>
                      c.name.toLowerCase().contains(searchQuery.toLowerCase()))
                  .toList();
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppTheme.silver.withValues(alpha: 0.4), width: 1),
            ),
            child: Column(children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.line,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
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
                            color: AppTheme.surface, shape: BoxShape.circle),
                        child:
                            Icon(Icons.close, size: 20, color: AppTheme.text2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.silver.withValues(alpha: 0.3)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(children: [
                    Icon(Icons.search, size: 18, color: AppTheme.text2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CupertinoTextField(
                        onChanged: (v) => setModalState(() => searchQuery = v),
                        style: AppTheme.body(color: AppTheme.text1),
                        placeholder: 'Search...',
                        placeholderStyle: AppTheme.body(color: AppTheme.text2),
                        padding: EdgeInsets.zero,
                        decoration: const BoxDecoration(),
                        cursorColor: AppTheme.accent,
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final country = filtered[index];
                    final isSelected = country == _country;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SGTouchable(
                        onTap: () {
                          setState(() => _country = country);
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
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
                          child: Row(children: [
                            Text(country.flag,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(country.name,
                                  style: AppTheme.body(color: AppTheme.text1)),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle,
                                  size: 18, color: AppTheme.accent),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]),
          );
        },
      ),
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
              builder: (context, constraints) => SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Text('SOLO GAINZ',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.accent,
                                letterSpacing: 4,
                              )),
                          const SizedBox(height: 8),
                          Text('Level up your body.',
                              style: AppTheme.caption(color: AppTheme.text2)),
                          const SizedBox(height: 40),

                          SGCard(
                            glowColor: AppTheme.silver,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_signUp ? 'Create Account' : 'Sign In',
                                    style:
                                        AppTheme.h1().copyWith(fontSize: 26)),
                                const SizedBox(height: 6),
                                Text(
                                    _signUp
                                        ? 'Join the grind.'
                                        : 'Good to have you back.',
                                    style: AppTheme.body()),
                                const SizedBox(height: 28),

                                // Segment control
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.silver.withValues(alpha: 0.3)),
                                  ),
                                  child: CupertinoSlidingSegmentedControl<int>(
                                    backgroundColor: AppTheme.bg.withValues(alpha: 0.5),
                                    thumbColor: AppTheme.accent,
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
                                const SizedBox(height: 24),

                                _label('Username'),
                                const SizedBox(height: 8),
                                _field(
                                  ctrl: _signUp
                                      ? _signUpNameCtrl
                                      : _loginNameCtrl,
                                  hint: 'Enter username',
                                  trail: _userStatus != null
                                      ? Icon(
                                          _userStatus == 'ok'
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 16,
                                          color: _userStatus == 'ok'
                                              ? AppTheme.accent
                                              : AppTheme.red)
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                _label('Password'),
                                const SizedBox(height: 8),
                                _field(
                                  ctrl: _signUp
                                      ? _signUpPassCtrl
                                      : _loginPassCtrl,
                                  hint: _signUp
                                      ? 'Min 6 characters'
                                      : 'Enter password',
                                  obscure:
                                      _signUp ? _obscureSignUp : _obscureLogin,
                                  trail: SGTouchable(
                                    onTap: () => setState(() {
                                      if (_signUp) {
                                        _obscureSignUp = !_obscureSignUp;
                                      } else {
                                        _obscureLogin = !_obscureLogin;
                                      }
                                    }),
                                    child: Icon(
                                      (_signUp ? _obscureSignUp : _obscureLogin)
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: 16,
                                      color: AppTheme.text2,
                                    ),
                                  ),
                                ),

                                if (_signUp) ...[
                                  const SizedBox(height: 16),
                                  _label('Country'),
                                  const SizedBox(height: 8),
                                  SGTouchable(
                                    onTap: _showPicker,
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: AppTheme.bg,
                                        borderRadius: BorderRadius.circular(10),
                                        border:
                                            Border.all(color: AppTheme.silver.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(children: [
                                        Expanded(
                                          child: Text(
                                            _country?.toString() ??
                                                'Select country',
                                            style: AppTheme.body(
                                                color: _country != null
                                                    ? AppTheme.text1
                                                    : AppTheme.text2),
                                          ),
                                        ),
                                        Icon(Icons.keyboard_arrow_down,
                                            size: 18, color: AppTheme.text2),
                                      ]),
                                    ),
                                  ),
                                ],

                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border:
                                            Border.all(color: AppTheme.red)),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 1),
                                          child: Icon(Icons.error,
                                              size: 14, color: AppTheme.red),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(_error!,
                                                style: AppTheme.caption(
                                                    color: AppTheme.red))),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 28),
                                SizedBox(
                                  width: double.infinity,
                                  child: SGButton(
                                    label:
                                        _signUp ? 'Create Account' : 'Sign In',
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
              ),
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
                color: _tab == i ? AppTheme.black : AppTheme.text2),
            textAlign: TextAlign.center),
      );

  Widget _label(String t) => Text(t.toUpperCase(),
      style: AppTheme.caption(color: AppTheme.text2)
          .copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2));

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    bool obscure = false,
    Widget? trail,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.silver.withValues(alpha: 0.3))),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        Expanded(
          child: CupertinoTextField(
            controller: ctrl,
            obscureText: obscure,
            enabled: !_loading,
            placeholder: hint,
            placeholderStyle: AppTheme.body(color: AppTheme.text2),
            style: AppTheme.body(color: AppTheme.text1),
            padding: EdgeInsets.zero,
            decoration: const BoxDecoration(),
            cursorColor: AppTheme.accent,
            cursorWidth: 1.5,
          ),
        ),
        if (trail != null) ...[const SizedBox(width: 8), trail],
      ]),
    );
  }

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
