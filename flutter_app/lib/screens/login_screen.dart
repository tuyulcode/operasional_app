import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../widgets/tappable.dart';
import 'main_shell.dart';
import 'profile/profile_screen.dart';

/// Colors used only by this redesigned login screen (kept local so we don't
/// depend on / clash with fields that may not exist in AppTheme).
class _LoginPalette {
  static const navyDark = Color(0xFF0B1B33);
  static const navyMid = Color(0xFF13284A);
  static const border = Color(0xFFE3E7EE);
  static const hint = Color(0xFF9AA4B2);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = true;

  late final AnimationController _animController;
  late final Animation<double> _headerFade;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _cardFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animController.forward();
    _restoreSavedUsername();
  }

  Future<void> _restoreSavedUsername() async {
    final saved = await StorageService.getUsername();
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => _usernameController.text = saved);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(username, password);

    if (!_rememberMe) {
      await StorageService.removeUsername();
    }

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  void _goToForgotPasswordHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(openHelp: true),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Selamat datang kembali!',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _LoginPalette.navyDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Masuk untuk melanjutkan pekerjaan Anda '
            'di Unit Pembangkit Paiton.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),

          // Jarak sebelum field pertama dilebarin — dulu 16, sekarang 26,
          // biar ada nafas antara subtitle dan form-nya (kayak referensi).
          const SizedBox(height: 26),

          // Username
          _OutlinedField(
            controller: _usernameController,
            hint: 'Email atau Username',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Username wajib diisi';
              }
              return null;
            },
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_passwordFocus),
          ),
          // Jarak antar field dilebarin dikit — dulu 10, sekarang 14.
          const SizedBox(height: 14),

          // Password
          _OutlinedField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _LoginPalette.hint,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Password wajib diisi';
              }
              return null;
            },
            onFieldSubmitted: (_) => _login(),
          ),

          // Jarak sebelum baris "Ingat saya" dilebarin — dulu 10, sekarang
          // 18, biar nggak keliatan nempel ke field password.
          const SizedBox(height: 18),

          // Remember me + forgot password
          Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: Checkbox(
                  value: _rememberMe,
                  activeColor: _LoginPalette.navyDark,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (v) => setState(() => _rememberMe = v ?? true),
                ),
              ),
              const SizedBox(width: 8),
              Tappable(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  child: Text(
                    'Ingat saya',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Tappable(
                onTap: _goToForgotPasswordHelp,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  child: Text(
                    'Lupa password?',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: _LoginPalette.navyDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Jarak sebelum tombol/error dilebarin paling banyak — dulu 12,
          // sekarang 24 — biar tombol "Masuk" nggak keliatan mepet ke
          // baris "Ingat saya", sesuai proporsi di referensi.
          const SizedBox(height: 24),

          // Error
          Consumer<AuthProvider>(
            builder: (_, auth, __) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: auth.error == null
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey(auth.error),
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.09),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppTheme.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                auth.error!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              );
            },
          ),

          // Login button
          Consumer<AuthProvider>(
            builder: (_, auth, __) {
              final busy = auth.isLoading;
              return SizedBox(
                height: 52,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    color: busy
                        ? _LoginPalette.navyDark.withValues(alpha: 0.5)
                        : _LoginPalette.navyDark,
                    boxShadow: busy
                        ? null
                        : [
                            BoxShadow(
                              color: _LoginPalette.navyDark
                                  .withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      onTap: busy ? null : _login,
                      child: Center(
                        child: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Masuk',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Jarak ke copyright dilebarin — dulu 14, sekarang 20.
          const SizedBox(height: 20),

          Center(
            child: Text(
              '© E-OPERASIONAL ${DateTime.now().year}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Small logo + app name, pinned to the top-left corner of the screen.
  Widget _buildTopLeftBrand() {
    return FadeTransition(
      opacity: _headerFade,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'E-OPERASIONAL',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: _LoginPalette.navyDark,
                ),
              ),
              Text(
                'UNIT PEMBANGKIT PAITON',
                style: GoogleFonts.inter(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _LoginPalette.navyDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen background image.
          Image.asset(
            'assets/images/back2.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: _LoginPalette.navyDark),
          ),
          // Light wash over the lower part of the image so the form
          // stays readable, matching the reference design.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.38, 0.55, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.75),
                  Colors.white.withValues(alpha: 0.96),
                ],
              ),
            ),
          ),

          // Small logo, pinned top-left.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: _buildTopLeftBrand(),
              ),
            ),
          ),

          // Main form, vertically centered on the screen.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              18,
                              constraints.maxHeight * 0.46,
                              18,
                              24,
                            ),
                            child: FadeTransition(
                              opacity: _cardFade,
                              child: SlideTransition(
                                position: _cardSlide,
                                child: _buildForm(),
                              ),
                            ),
                          ),
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
  }
}

/// Text field styled with a thin outline + leading icon, matching the
/// reference design (icon + hint text inline, no separate label above).
class _OutlinedField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _OutlinedField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.suffixIcon,
    this.obscureText = false,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.inter(fontSize: 14.5, color: _LoginPalette.navyDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: _LoginPalette.hint),
        prefixIcon: Icon(icon, color: _LoginPalette.hint, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: _LoginPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: _LoginPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: _LoginPalette.navyDark, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
      ),
    );
  }
}