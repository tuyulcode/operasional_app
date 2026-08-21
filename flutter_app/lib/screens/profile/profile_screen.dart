import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Column(
        children: [
          // Header with profile
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 16, 20, 32),
            child: Column(
              children: [
                // Top row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'PROFILE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 24),
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: user?.photoUrl != null
                      ? ClipOval(
                          child: Image.network(user!.photoUrl!,
                              fit: BoxFit.cover),
                        )
                      : const Icon(Icons.person_rounded,
                          size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.username ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    user?.role == 'admin' ? 'Administrator' : 'Petugas',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Info section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        _infoRow(Icons.person_outline, 'Username',
                            user?.username ?? '-'),
                        const Divider(height: 20),
                        _infoRow(Icons.shield_outlined, 'Role',
                            user?.role ?? '-'),
                        const Divider(height: 20),
                        _infoRow(Icons.apartment_rounded, 'Organisasi',
                            'PLN Nusantara Power'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menu items
                  _menuItem(Icons.info_outline, 'Tentang Aplikasi', () {
                    _showAbout(context);
                  }),
                  const SizedBox(height: 8),
                  _menuItem(Icons.help_outline, 'Bantuan', () {}),

                  const Spacer(),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmLogout(context),
                      icon: const Icon(Icons.logout_rounded,
                          size: 20, color: Colors.white),
                      label: Text(
                        'Keluar Aplikasi',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '© 2024 PLN Nusantara Power\nv1.0.0',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text('Keluar?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Apakah Anda yakin ingin keluar dari aplikasi?',
            style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal',
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('Keluar',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text('Tagihan Air Mobile',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Aplikasi mobile untuk pencatatan dan monitoring tagihan air PLN Nusantara Power.\n\nVersi 1.0.0',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup',
                style: GoogleFonts.inter(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}
