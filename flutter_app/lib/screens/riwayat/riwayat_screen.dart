import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/tagihan_air.dart';
import '../../providers/master_data_provider.dart';
import '../../providers/tagihan_provider.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _searchController = TextEditingController();
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  int? _selectedAreaId;
  String? _selectedBulan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasterDataProvider>().loadAreas();
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    context.read<TagihanProvider>().loadTagihan(
          areaId: _selectedAreaId,
          bulan: _selectedBulan,
          search: _searchController.text,
        );
  }

  void _showFilterSheet() {
    final master = context.read<MasterDataProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Filter',
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Text('Area',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip(
                      'Semua',
                      _selectedAreaId == null,
                      () => setSheetState(
                          () => _selectedAreaId = null),
                    ),
                    ...master.areas.map((a) => _filterChip(
                          a.nama,
                          _selectedAreaId == a.id,
                          () => setSheetState(
                              () => _selectedAreaId = a.id),
                        )),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _loadData();
                    },
                    child: Text('Terapkan Filter',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary
              : AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagProv = context.watch<TagihanProvider>();

    // Summary
    final totalTagihan = tagProv.tagihans.fold<double>(
        0.0, (sum, t) => sum + t.jumlah);
    final totalPemakaian = tagProv.tagihans.fold<double>(
        0.0, (sum, t) => sum + t.pemakaian);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async => _loadData(),
              child: tagProv.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary))
                  : tagProv.tagihans.isEmpty
                      ? _buildEmpty()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            // Summary cards
                            _buildSummary(totalTagihan, totalPemakaian,
                                tagProv.tagihans.length),
                            const SizedBox(height: 16),

                            // List
                            Text(
                              'Riwayat Tagihan',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...tagProv.tagihans
                                .map((t) => _buildTagihanCard(t)),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'NUSANTARA POWER',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showFilterSheet,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari Riwayat...',
                hintStyle: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.6), size: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (_) => _loadData(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(double total, double pemakaian, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Tagihan',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 4),
                Text(_currencyFormat.format(total),
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pemakaian',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 4),
                Text('${pemakaian.toStringAsFixed(0)} m³',
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text('$count transaksi',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagihanCard(TagihanAir t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.water_drop_rounded,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.titikMeterNama,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    Text(t.areaNama,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_currencyFormat.format(t.jumlah),
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary)),
                  Text(t.periodeLabel,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              _metaChip('Meter ${t.meterIni.toStringAsFixed(0)}'),
              const SizedBox(width: 6),
              _metaChip('${t.pemakaian.toStringAsFixed(0)} m³'),
              const Spacer(),
              if (t.fotos.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.photo_rounded,
                        size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 3),
                    Text('${t.fotos.length} foto',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary)),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded,
              size: 60, color: AppTheme.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text('Belum ada riwayat tagihan',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
