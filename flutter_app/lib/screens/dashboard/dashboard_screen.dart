import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/dashboard_stats.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashProv = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => dashProv.loadDashboard(),
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(child: _buildHeader(auth)),

            // ── Content ──
            if (dashProv.isLoading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary)),
              )
            else if (dashProv.stats != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    _buildSummaryCards(dashProv.stats!),
                    const SizedBox(height: 20),
                    _buildProgressCard(dashProv.stats!),
                    const SizedBox(height: 20),
                    _buildQuickStats(dashProv.stats!),
                    const SizedBox(height: 20),
                    _buildActivitySection(dashProv.stats!),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 24),
      child: Row(
        children: [
          // Logo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.water_drop_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NUSANTARA POWER',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Profile button
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: auth.user?.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(auth.user!.photoUrl!,
                          fit: BoxFit.cover),
                    )
                  : const Icon(Icons.person_rounded,
                      color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.receipt_long_rounded,
            iconColor: AppTheme.primary,
            label: 'TOTAL TAGIHAN (EST)',
            value: _currencyFormat.format(stats.totalTagihan),
            subtitle: stats.periodeLabel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.water_drop_rounded,
            iconColor: AppTheme.accent,
            label: 'TOTAL PEMAKAIAN',
            value: '${NumberFormat('#,##0', 'id_ID').format(stats.totalPemakaian)} m³',
            subtitle: stats.periodeLabel,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(DashboardStats stats) {
    final progress = stats.progress;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up_rounded,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Status Input Bulan Berjalan',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '${progress.persen}%',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.persen / 100,
              minHeight: 8,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.sudahInput} Titik Terisi',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                '${progress.totalTarget - progress.sudahInput} Titik Tersisa',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: _QuickStat(
            icon: Icons.location_on_rounded,
            value: '${stats.totalArea}',
            label: 'AREA AKTIF',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStat(
            icon: Icons.speed_rounded,
            value: '${stats.totalTitikMeter}',
            label: 'TITIK METER',
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection(DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'AKTIVITAS TERAKHIR',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              'Lihat Semua',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (stats.aktivitasTerakhir.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Center(
              child: Text(
                'Belum ada aktivitas.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppTheme.textMuted),
              ),
            ),
          )
        else
          ...stats.aktivitasTerakhir.map((a) => _ActivityTile(
                titikMeter: a.titikMeter,
                area: a.area,
                jumlah: _currencyFormat.format(a.jumlah),
                status: a.status,
                updatedAt: a.updatedAt,
              )),
      ],
    );
  }
}

// ── Reusable sub-widgets ──

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _QuickStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String titikMeter;
  final String area;
  final String jumlah;
  final String status;
  final String updatedAt;

  const _ActivityTile({
    required this.titikMeter,
    required this.area,
    required this.jumlah,
    required this.status,
    required this.updatedAt,
  });

  String _formatDate() {
    try {
      final dt = DateTime.parse(updatedAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
      if (diff.inHours < 24) return '${diff.inHours}j lalu';
      return DateFormat('dd MMM, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return updatedAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_outline,
                color: AppTheme.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titikMeter,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Diinput oleh Budi · $area',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
