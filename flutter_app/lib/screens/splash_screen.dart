import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// Palette used only on this splash screen.
class _SplashPalette {
  static const navyDark = Color(0xFF071426);
}

/// Single-slide splash screen: brand + tagline over a looping muted
/// background video. While the video plays, it also validates any saved
/// login session, then routes to MainShell (already logged in) or
/// LoginScreen — whichever check finishes last, after a 5s minimum.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final VideoPlayerController _videoController;
  bool _videoReady = false;
  bool _minDurationElapsed = false;
  bool _authChecked = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 5), () {
      _minDurationElapsed = true;
      _tryNavigate();
    });

    // Validate any saved token so an already-logged-in user lands on
    // MainShell directly, instead of being forced to log in every time.
    context.read<AuthProvider>().checkAuth().then((_) {
      _authChecked = true;
      _tryNavigate();
    });

    _videoController = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..setLooping(true)
      ..setVolume(0) // splash video biasanya nggak perlu suara
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoReady = true);
        _videoController.play();
      }).catchError((_) {
        // Kalau video gagal load, _videoReady tetap false — background
        // jatuh ke warna polos navyDark (lihat build()).
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _tryNavigate() {
    if (_navigated || !_minDurationElapsed || !_authChecked) return;
    _navigated = true;
    if (!mounted) return;

    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const MainShell() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SplashPalette.navyDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video background — satu-satunya sumber background sekarang.
          // Selama belum ready (atau gagal load), yang keliatan cuma
          // backgroundColor navyDark dari Scaffold di atas.
          if (_videoReady)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
          // Dark overlay so the text stays legible over the video.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _SplashPalette.navyDark.withValues(alpha: 0.55),
                  _SplashPalette.navyDark.withValues(alpha: 0.35),
                  _SplashPalette.navyDark.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Align(
                alignment: const Alignment(0, -0.62),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
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
                    const SizedBox(height: 20),
                    Text(
                      'E-OPERASIONAL',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unit Pembangkit Paiton',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        letterSpacing: 1,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 46),
                    Text(
                      'Pantau. Catat. Optimalkan.',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kelola seluruh kegiatan operasional pembangkit\n'
                      'dari satu aplikasi.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}