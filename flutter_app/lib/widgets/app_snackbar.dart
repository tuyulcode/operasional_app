import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppSnackbarType { success, error, offline }

/// Snackbar custom bergaya card — pengganti SnackBar bawaan Flutter yang
/// polos (kotak abu-abu rata tanpa ikon). Floating, rounded, ada ikon +
/// judul + subtitle opsional, warna beda per jenis pesan.
///
/// Pemakaian:
///   AppSnackbar.success(context, title: 'Tagihan tersimpan', subtitle: 'Agustus 2026 · Meter 01');
///   AppSnackbar.error(context, title: 'Tagihan sudah ada', subtitle: 'Coba periode lain.');
///   AppSnackbar.offline(context); // pesan default untuk gagal koneksi
class AppSnackbar {
  AppSnackbar._();

  static void success(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    _show(
      context,
      type: AppSnackbarType.success,
      title: title,
      subtitle: subtitle,
      duration: const Duration(milliseconds: 2500),
    );
  }

  static void error(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    _show(
      context,
      type: AppSnackbarType.error,
      title: title,
      subtitle: subtitle,
      duration: const Duration(milliseconds: 3500),
    );
  }

  static void offline(
    BuildContext context, {
    String title = 'Tidak tersambung ke server',
    String? subtitle = 'Coba lagi dalam beberapa saat.',
  }) {
    _show(
      context,
      type: AppSnackbarType.offline,
      title: title,
      subtitle: subtitle,
      duration: const Duration(milliseconds: 3500),
    );
  }

  static void _show(
    BuildContext context, {
    required AppSnackbarType type,
    required String title,
    String? subtitle,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final config = _configFor(type);

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: config.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(config.icon, size: 20, color: config.iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: config.subtitleColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _SnackConfig _configFor(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return _SnackConfig(
          background: const Color(0xFF0F6E56),
          iconColor: const Color(0xFFE1F5EE),
          subtitleColor: const Color(0xFF9FE1CB),
          icon: Icons.check_circle_rounded,
        );
      case AppSnackbarType.error:
        return _SnackConfig(
          background: const Color(0xFF993C1D),
          iconColor: const Color(0xFFFAECE7),
          subtitleColor: const Color(0xFFF5C4B3),
          icon: Icons.warning_rounded,
        );
      case AppSnackbarType.offline:
        return _SnackConfig(
          background: const Color(0xFF2C2C2A),
          iconColor: const Color(0xFFD3D1C7),
          subtitleColor: const Color(0xFFB4B2A9),
          icon: Icons.wifi_off_rounded,
        );
    }
  }
}

class _SnackConfig {
  final Color background;
  final Color iconColor;
  final Color subtitleColor;
  final IconData icon;

  _SnackConfig({
    required this.background,
    required this.iconColor,
    required this.subtitleColor,
    required this.icon,
  });
}