import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import 'main_shell.dart';
import 'profile/profile_screen.dart';

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
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _cardFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        child: Stack(
          children: [
            // ── Decorative blurred blobs ──
            Positioned(
              top: -70,
              right: -60,
              child: _blob(220, Colors.white.withValues(alpha: 0.10)),
            ),
            Positioned(
              top: 90,
              left: -90,
              child: _blob(180, Colors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              bottom: -110,
              right: -70,
              child: _blob(260, AppTheme.primaryLight.withValues(alpha: 0.14)),
            ),

            SafeArea(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).unfocus(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 24),

                            // ── Brand ──
                            FadeTransition(
                              opacity: _logoFade,
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: _LogoBadge(),
                              ),
                            ),
                            const SizedBox(height: 18),
                            FadeTransition(
                              opacity: _logoFade,
                              child: Column(
                                children: [
                                  Text(
                                    'E-OPERASIONAL',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2.4,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Unit Pembangkit Paiton',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Card Login ──
                            FadeTransition(
                              opacity: _cardFade,
                              child: SlideTransition(
                                position: _cardSlide,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                      24, 28, 24, 24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.radiusXl),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.secondary
                                            .withValues(alpha: 0.18),
                                        blurRadius: 30,
                                        offset: const Offset(0, 14),
                                      ),
                                    ],
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Selamat Datang',
                                          style: GoogleFonts.inter(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Masuk untuk melanjutkan pekerjaan Anda',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppTheme.textMuted,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 26),

                                        // Username
                                        _FieldLabel('Username'),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _usernameController,
                                          textInputAction: TextInputAction.next,
                                          style: GoogleFonts.inter(fontSize: 14.5),
                                          decoration: InputDecoration(
                                            hintText: 'Masukkan username',
                                            prefixIcon: const Icon(
                                              Icons.person_outline_rounded,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) {
                                              return 'Username wajib diisi';
                                            }
                                            return null;
                                          },
                                          onFieldSubmitted: (_) =>
                                              FocusScope.of(context)
                                                  .requestFocus(_passwordFocus),
                                        ),
                                        const SizedBox(height: 16),

                                        // Password
                                        _FieldLabel('Password'),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _passwordController,
                                          focusNode: _passwordFocus,
                                          obscureText: _obscurePassword,
                                          style: GoogleFonts.inter(fontSize: 14.5),
                                          textInputAction: TextInputAction.done,
                                          decoration: InputDecoration(
                                            hintText: 'Masukkan password',
                                            prefixIcon: const Icon(
                                              Icons.lock_outline_rounded,
                                              color: AppTheme.textMuted,
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: AppTheme.textMuted,
                                              ),
                                              onPressed: () => setState(() =>
                                                  _obscurePassword =
                                                      !_obscurePassword),
                                            ),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) {
                                              return 'Password wajib diisi';
                                            }
                                            return null;
                                          },
                                          onFieldSubmitted: (_) => _login(),
                                        ),
                                        const SizedBox(height: 10),

                                        // Remember me + forgot password
                                        Row(
                                          children: [
                                            SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                activeColor: AppTheme.primary,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                onChanged: (v) => setState(
                                                    () => _rememberMe = v ?? true),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => setState(
                                                  () => _rememberMe = !_rememberMe),
                                              child: Text(
                                                'Ingat saya',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: _goToForgotPasswordHelp,
                                              child: Text(
                                                'Lupa password?',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12.5,
                                                  color: AppTheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),

                                        // Error
                                        Consumer<AuthProvider>(
                                          builder: (_, auth, __) {
                                            return AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              child: auth.error == null
                                                  ? const SizedBox.shrink()
                                                  : Container(
                                                      key: ValueKey(auth.error),
                                                      width: double.infinity,
                                                      padding:
                                                          const EdgeInsets.all(12),
                                                      margin: const EdgeInsets
                                                          .only(bottom: 16),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.error
                                                            .withValues(
                                                                alpha: 0.09),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                AppTheme.radiusSm),
                                                        border: Border.all(
                                                          color: AppTheme.error
                                                              .withValues(
                                                                  alpha: 0.25),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .error_outline_rounded,
                                                              color:
                                                                  AppTheme.error,
                                                              size: 18),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              auth.error!,
                                                              style: GoogleFonts
                                                                  .inter(
                                                                fontSize: 13,
                                                                color: AppTheme
                                                                    .error,
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
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppTheme.radiusMd),
                                                  gradient: busy
                                                      ? null
                                                      : AppTheme.primaryGradient,
                                                  color: busy
                                                      ? AppTheme.textMuted
                                                          .withValues(alpha: 0.4)
                                                      : null,
                                                  boxShadow: busy
                                                      ? null
                                                      : [
                                                          BoxShadow(
                                                            color: AppTheme
                                                                .primary
                                                                .withValues(
                                                                    alpha: 0.35),
                                                            blurRadius: 16,
                                                            offset:
                                                                const Offset(0, 8),
                                                          ),
                                                        ],
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppTheme.radiusMd),
                                                    onTap: busy ? null : _login,
                                                    child: Center(
                                                      child: busy
                                                          ? const SizedBox(
                                                              width: 22,
                                                              height: 22,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                color:
                                                                    Colors.white,
                                                                strokeWidth: 2.5,
                                                              ),
                                                            )
                                                          : Row(
                                                              mainAxisSize:
                                                                  MainAxisSize.min,
                                                              children: [
                                                                Text(
                                                                  'Masuk',
                                                                  style: GoogleFonts
                                                                      .inter(
                                                                    fontSize: 16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    width: 8),
                                                                const Icon(
                                                                  Icons
                                                                      .arrow_forward_rounded,
                                                                  color:
                                                                      Colors.white,
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
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            FadeTransition(
                              opacity: _cardFade,
                              child: Text(
                                '© ${DateTime.now().year} PLN Nusantara Power - Unit Pembangkit Paiton.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
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
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }
}