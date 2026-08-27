import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/tagihan_air.dart';
import '../../providers/master_data_provider.dart';
import '../../providers/tagihan_provider.dart';
import '../../screens/profile/profile_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  int? _selectedAreaId;
  String? _selectedBulan;
  String? _selectedTahun;
  String? _selectedTitikMeter;

  bool _showAll = false;

  final List<String> _months = const [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

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
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ============================================================
  // DATA
  // ============================================================

  void _loadData() {
    context.read<TagihanProvider>().loadTagihan(
      areaId: _selectedAreaId,
      search: _searchController.text,
    );
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      context.read<TagihanProvider>().loadTagihan(
        areaId: _selectedAreaId,
        search: value,
      );
    });
  }

  void _onSearch(String value) {
    _searchDebounce?.cancel();
    context.read<TagihanProvider>().loadTagihan(
      areaId: _selectedAreaId,
      search: value,
    );
  }

  bool get _hasActiveFilter =>
      _selectedAreaId != null ||
      _selectedBulan != null ||
      _selectedTahun != null ||
      _selectedTitikMeter != null;

  void _resetAllFilters() {
    setState(() {
      _selectedAreaId = null;
      _selectedBulan = null;
      _selectedTahun = null;
      _selectedTitikMeter = null;
    });
    _loadData();
  }

  List<TagihanAir> _getFilteredTagihans(List<TagihanAir> tagihans) {
    var result = List<TagihanAir>.from(tagihans);

    // Filter bulan (matched client-side against the period label, e.g.
    // "Agustus 2026" — the backend only accepts a combined "YYYY-MM"
    // value, which this screen doesn't have since Bulan and Tahun are
    // picked independently).
    if (_selectedBulan != null) {
      result = result.where((t) {
        return t.periodeLabel.contains(_selectedBulan!);
      }).toList();
    }

    // Filter tahun
    if (_selectedTahun != null) {
      result = result.where((t) {
        return t.periodeLabel.contains(_selectedTahun!);
      }).toList();
    }

    // Filter titik meter
    if (_selectedTitikMeter != null) {
      result = result.where((t) {
        return t.titikMeterNama == _selectedTitikMeter;
      }).toList();
    }

    return result;
  }

  List<String> _getTitikMeters(List<TagihanAir> tagihans) {
    final result = tagihans
        .map((e) => e.titikMeterNama)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    result.sort();

    return result;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final tagProv = context.watch<TagihanProvider>();

    final allTagihans = tagProv.tagihans;

    final filteredTagihans = _getFilteredTagihans(allTagihans);

    final totalTagihan = filteredTagihans.fold<double>(
      0.0,
      (sum, t) => sum + t.jumlah,
    );

    final totalPemakaian = filteredTagihans.fold<double>(
      0.0,
      (sum, t) => sum + t.pemakaian,
    );

    final visibleCount = _showAll
        ? filteredTagihans.length
        : filteredTagihans.length > 5
        ? 5
        : filteredTagihans.length;

    final visibleTagihans = filteredTagihans.take(visibleCount).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _buildFilterRow(allTagihans),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () async {
                  _loadData();
                },
                child: tagProv.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : filteredTagihans.isEmpty
                    ? _buildEmpty()
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        children: [
                          _buildSummary(totalTagihan, totalPemakaian),

                          const SizedBox(height: 22),

                          _buildSectionTitle(),

                          const SizedBox(height: 10),

                          ...visibleTagihans.map((t) => _buildTagihanCard(t)),

                          if (filteredTagihans.length > 5) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                _showAll
                                    ? 'Menampilkan semua ${filteredTagihans.length} data'
                                    : 'Menampilkan 5 dari ${filteredTagihans.length} data',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildLoadMoreButton(),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBg,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                'Riwayat Tagihan',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17233D),
                  letterSpacing: -0.2,
                ),
              ),

              const Spacer(),

              // Menu profil — tap untuk membuka ProfileScreen
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Search
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F0FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD0D9E8)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearch,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Cari Riwayat...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF566276),
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF8A93A3),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                          setState(() {});
                        },
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER ROW
  // ============================================================

  Widget _buildFilterRow(List<TagihanAir> tagihans) {
    final titikMeters = _getTitikMeters(tagihans);

    return SizedBox(
      height: 32,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            // ConstrainedBox memaksa lebar minimum row = lebar layar,
            // sehingga saat chip muat, Row akan center di tengah;
            // saat kepanjangan, tetap bisa discroll normal.
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDropdownFilter(
                    label: _getSelectedPeriodeLabel(),
                    selected: _selectedBulan != null || _selectedTahun != null,
                    onTap: _showPeriodePicker,
                  ),

                  const SizedBox(width: 8),

                  _buildDropdownFilter(
                    label: _getSelectedAreaName(),
                    selected: _selectedAreaId != null,
                    onTap: _showAreaFilter,
                  ),

                  const SizedBox(width: 8),

                  _buildDropdownFilter(
                    label: _selectedTitikMeter ?? 'Titik Meter',
                    selected: _selectedTitikMeter != null,
                    onTap: () => _showTitikMeterFilter(titikMeters),
                  ),

                  if (_hasActiveFilter) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _resetAllFilters,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.close_rounded,
                              size: 13,
                              color: AppTheme.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Reset',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF14213D) : const Color(0xFFE9F1FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF14213D) : const Color(0xFFC8D3E5),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF24324A),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: selected ? Colors.white : const Color(0xFF33415C),
            ),
          ],
        ),
      ),
    );
  }

  String _getSelectedAreaName() {
    if (_selectedAreaId == null) {
      return 'Area';
    }

    final master = context.read<MasterDataProvider>();

    for (final area in master.areas) {
      if (area.id == _selectedAreaId) {
        return area.nama;
      }
    }

    return 'Area';
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(double totalTagihan, double totalPemakaian) {
    final currentYear = DateTime.now().year;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'TOTAL PEMAKAIAN',
            value: '${totalPemakaian.toStringAsFixed(0)} m³',
            subtitle: 'Tahun $currentYear',
            dark: true,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildSummaryCard(
            title: 'TOTAL TAGIHAN',
            value: _formatCompactCurrency(totalTagihan),
            subtitle: 'Tahun $currentYear',
            dark: false,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required bool dark,
  }) {
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(13, 11, 10, 9),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1D2B49) : const Color(0xFFDCEAFF),
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
              color: dark
                  ? Colors.white.withValues(alpha: 0.55)
                  : const Color(0xFF65738A),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : const Color(0xFF17233D),
            ),
          ),

          const Spacer(),

          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: dark
                  ? Colors.white.withValues(alpha: 0.45)
                  : const Color(0xFF65738A),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompactCurrency(double value) {
    if (value >= 1000000000) {
      return 'Rp${(value / 1000000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000000) {
      return 'Rp${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return 'Rp${(value / 1000).toStringAsFixed(0)}K';
    }

    return _currencyFormat.format(value);
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Text(
          'Riwayat Tagihan',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildTagihanCard(TagihanAir t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFD1D7E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent kiri
            Container(
              width: 3,
              decoration: const BoxDecoration(
                color: Color(0xFF009B8D),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 11, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader(t),

                    const SizedBox(height: 11),

                    _buildMeterInfo(t),

                    const SizedBox(height: 9),

                    _buildTotalTagihan(t),

                    const SizedBox(height: 9),

                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE5E7EB),
                    ),

                    const SizedBox(height: 8),

                    _buildCardFooter(t),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(TagihanAir t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.periodeLabel,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF18243A),
          ),
        ),

        const SizedBox(height: 2),

        Text(
          t.areaNama,
          style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF647084)),
        ),
      ],
    );
  }

  Widget _buildMeterInfo(TagihanAir t) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoColumn(
            label: 'Titik Meter',
            value: t.titikMeterNama,
          ),
        ),

        Expanded(
          child: _buildInfoColumn(
            label: 'Pemakaian',
            value: '${t.pemakaian.toStringAsFixed(0)} m³',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF8A93A3)),
        ),

        const SizedBox(height: 2),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B2940),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalTagihan(TagihanAir t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Tagihan',
          style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF8A93A3)),
        ),

        const SizedBox(height: 2),

        Text(
          _currencyFormat.format(t.jumlah),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF17233D),
          ),
        ),
      ],
    );
  }

  Widget _buildCardFooter(TagihanAir t) {
    return Row(
      children: [
        const Icon(Icons.photo_outlined, size: 13, color: Color(0xFF7A8494)),

        const SizedBox(width: 4),

        Text(
          t.fotos.isEmpty ? 'Tidak ada foto' : '${t.fotos.length} foto',
          style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF657080)),
        ),

        const Spacer(),

        GestureDetector(
          onTap: () => _showDetail(t),
          child: Row(
            children: [
              Text(
                'Lihat Detail',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF008F81),
                ),
              ),

              const SizedBox(width: 3),

              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: Color(0xFF008F81),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOAD MORE
  // ============================================================

  Widget _buildLoadMoreButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAll = !_showAll;
        });
      },
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFE5EEFC),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFC9D7EC)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _showAll ? 'Tampilkan Lebih Sedikit' : 'Muat Lebih Banyak',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF24334D),
                ),
              ),

              const SizedBox(width: 6),

              Icon(
                _showAll
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.refresh_rounded,
                size: 15,
                color: const Color(0xFF24334D),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTER
  // ============================================================

  String _getSelectedPeriodeLabel() {
    if (_selectedBulan != null && _selectedTahun != null) {
      return '$_selectedBulan $_selectedTahun';
    }

    return _selectedBulan ?? _selectedTahun ?? 'Periode';
  }

  Future<void> _showPeriodePicker() async {
    DateTime initialDate;

    final bulanIndex = _selectedBulan == null
        ? -1
        : _months.indexOf(_selectedBulan!);

    if (bulanIndex >= 0 && _selectedTahun != null) {
      initialDate = DateTime(int.parse(_selectedTahun!), bulanIndex + 1);
    } else {
      initialDate = DateTime.now();
    }

    final picked = await showMonthPicker(
      context: context,
      initialDate: initialDate,
      monthPickerDialogSettings: MonthPickerDialogSettings(
        dialogSettings: const PickerDialogSettings(
          locale: Locale('id'),
          dismissible: true,
          dialogRoundedCornersRadius: 18,
        ),
        headerSettings: const PickerHeaderSettings(
          headerBackgroundColor: AppTheme.primary,
        ),
        dateButtonsSettings: const PickerDateButtonsSettings(
          selectedMonthBackgroundColor: AppTheme.primary,
          selectedMonthTextColor: Colors.white,
        ),
      ),
    );

    if (!mounted || picked == null) return;

    setState(() {
      _selectedBulan = _months[picked.month - 1];
      _selectedTahun = picked.year.toString();
    });
  }

  void _showTitikMeterFilter(List<String> titikMeters) {
    _showSelectionSheet(
      title: 'Pilih Titik Meter',
      items: titikMeters,
      selected: _selectedTitikMeter,
      onSelected: (value) {
        setState(() {
          _selectedTitikMeter = value;
        });
      },
    );
  }

  void _showAreaFilter() {
    final master = context.read<MasterDataProvider>();

    final items = master.areas.map((a) => a.nama).toList();

    _showSelectionSheet(
      title: 'Pilih Area',
      items: items,
      selected: _getSelectedAreaName() == 'Area'
          ? null
          : _getSelectedAreaName(),
      onSelected: (value) {
        if (value == null) {
          setState(() {
            _selectedAreaId = null;
          });
          _loadData();
          return;
        }

        for (final area in master.areas) {
          if (area.nama == value) {
            setState(() {
              _selectedAreaId = area.id;
            });

            _loadData();
            break;
          }
        }
      },
    );
  }

  // ------------------------------------------------------------
  // FIXED: sheet sekarang menggunakan isScrollControlled + tinggi
  // dibatasi (ConstrainedBox) + daftar item dibungkus SingleChild-
  // ScrollView agar tidak overflow saat item banyak (mis. 12 bulan).
  // ------------------------------------------------------------
  void _showSelectionSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.75;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5D9E0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17233D),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selected != null)
                            _buildSelectionItem(
                              label: 'Semua',
                              selected: false,
                              onTap: () {
                                Navigator.pop(ctx);
                                onSelected(null);
                              },
                            ),

                          ...items.map(
                            (item) => _buildSelectionItem(
                              label: item,
                              selected: selected == item,
                              onTap: () {
                                Navigator.pop(ctx);
                                onSelected(item);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionItem({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE3F6F3) : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? const Color(0xFF008F81)
                      : const Color(0xFF27344A),
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 17,
                color: Color(0xFF008F81),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL
  // ============================================================

  // FIXED: sama seperti filter sheet, dibungkus isScrollControlled +
  // ConstrainedBox + SingleChildScrollView supaya tidak overflow
  // kalau daftar detail cukup panjang (mis. layar HP pendek / font besar).
  void _showDetail(TagihanAir t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.85;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5D9E0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    t.periodeLabel,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF17233D),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    t.areaNama,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF7C8696),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Titik Meter', t.titikMeterNama),

                          _buildDetailRow(
                            'Lokasi Flow Meter',
                            t.lokasiFlowMeter ?? '-',
                          ),

                          _buildDetailRow(
                            'Meter Sebelumnya',
                            t.meterLalu.toStringAsFixed(0),
                          ),

                          _buildDetailRow(
                            'Meter Saat Ini',
                            t.meterIni.toStringAsFixed(0),
                          ),

                          _buildDetailRow(
                            'Faktor Meter',
                            t.meterFaktor.toStringAsFixed(2),
                          ),

                          _buildDetailRow(
                            'Pemakaian',
                            '${t.pemakaian.toStringAsFixed(0)} m³',
                          ),

                          _buildDetailRow(
                            'Tarif',
                            _currencyFormat.format(t.tarif),
                          ),

                          _buildDetailRow(
                            'Total Tagihan',
                            _currencyFormat.format(t.jumlah),
                          ),

                          const SizedBox(height: 4),

                          _buildDokumentasiSection(t),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // FOTO / DOKUMENTASI
  // ============================================================

  Widget _buildDokumentasiSection(TagihanAir t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(
            'Dokumentasi',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF7C8696),
            ),
          ),
        ),

        if (t.fotos.isEmpty)
          Text(
            'Tidak ada foto',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C2940),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(t.fotos.length, (index) {
              final foto = t.fotos[index];
              return GestureDetector(
                onTap: () => _openFotoViewer(t.fotos, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFFF0F2F5),
                    child: Image.network(
                      foto.url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          size: 22,
                          color: Color(0xFF9AA4B2),
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }

  void _openFotoViewer(List<TagihanAirFoto> fotos, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) {
        final pageController = PageController(initialPage: initialIndex);
        int currentIndex = initialIndex;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Stack(
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: fotos.length,
                  onPageChanged: (i) {
                    setDialogState(() {
                      currentIndex = i;
                    });
                  },
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: Image.network(
                          fotos[index].url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: Colors.white54,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

                Positioned(
                  top: MediaQuery.of(ctx).padding.top + 8,
                  right: 12,
                  child: IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),

                if (fotos.length > 1)
                  Positioned(
                    bottom: MediaQuery.of(ctx).padding.bottom + 18,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentIndex + 1} / ${fotos.length}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF7C8696),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C2940),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _hasActiveFilter
                        ? Icons.filter_alt_off_rounded
                        : Icons.receipt_long_rounded,
                    size: 30,
                    color: AppTheme.primary.withValues(alpha: 0.6),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  _hasActiveFilter
                      ? 'Tidak ada hasil untuk filter ini'
                      : 'Belum ada riwayat tagihan',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _hasActiveFilter
                      ? 'Coba ubah atau reset filter yang aktif.'
                      : 'Data tagihan akan muncul di sini.',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),

                if (_hasActiveFilter) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _resetAllFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Reset Filter',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
