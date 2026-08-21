import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'input_tagihan/input_step1_screen.dart';
import 'riwayat/riwayat_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    RiwayatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody: true supaya body "mengalir" di belakang navbar,
      // dan navbar sendiri jadi transparan di area luar bentuknya.
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    // Kunci perbaikan: Stack di sini TIDAK dibungkus ClipRRect.
    // Hanya panel navbar putih (di dalam Positioned) yang di-clip
    // dengan sudut membulat. Tombol "Input" ditaruh di luar area
    // yang di-clip itu, jadi dia bebas menonjol ke atas tanpa terpotong.
    return SizedBox(
      height: 64 + MediaQuery.of(context).padding.bottom + 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Panel navbar (yang di-clip rounded corner)
          Positioned(
            left: 0,
            right: 0,
            top: 24, // ruang kosong di atas, tempat tombol menonjol
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.98),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.divider.withValues(alpha: 0.3),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(0, Icons.grid_view_rounded, 'Dashboard'),
                        const SizedBox(width: 56),
                        _buildNavItem(1, Icons.history_rounded, 'Riwayat'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Tombol "Input" mengambang, DI LUAR ClipRRect -> tidak kepotong
          Positioned(
            top: 0,
            child: _buildCenterButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    final color = isActive ? AppTheme.primary : AppTheme.textSecondary;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            // Active-state dot indicator
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: isActive ? 1 : 0,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InputStep1Screen()),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Input',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}