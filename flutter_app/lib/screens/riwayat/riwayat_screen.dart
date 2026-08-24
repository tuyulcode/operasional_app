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
    super.dispose();
  }

  // ============================================================
  // DATA
  // ============================================================

  void _loadData() {
    context.read<TagihanProvider>().loadTagihan(
          areaId: _selectedAreaId,
          bulan: _selectedBulan,
          search: _searchController.text,
        );

    setState(() {
      _showAll = false;
    });
  }

  void _onSearch(String value) {
    context.read<TagihanProvider>().loadTagihan(
          areaId: _selectedAreaId,
          bulan: _selectedBulan,
          search: value,
        );

    setState(() {
      _showAll = false;
    });
  }

  List<TagihanAir> _getFilteredTagihans(
    List<TagihanAir> tagihans,
  ) {
    var result = List<TagihanAir>.from(tagihans);

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

  List<String> _getYears(List<TagihanAir> tagihans) {
    final years = <String>{};

    for (final t in tagihans) {
      final match = RegExp(
        r'\b(20\d{2})\b',
      ).firstMatch(t.periodeLabel);

      if (match != null) {
        years.add(match.group(1)!);
      }
    }

    final result = years.toList()
      ..sort(
        (a, b) => b.compareTo(a),
      );

    if (result.isEmpty) {
      result.add(DateTime.now().year.toString());
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

    final filteredTagihans = _getFilteredTagihans(
      allTagihans,
    );

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

    final visibleTagihans = filteredTagihans
        .take(visibleCount)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),

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
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              14,
                              16,
                              28,
                            ),
                            children: [
                              _buildFilterRow(allTagihans),

                              const SizedBox(height: 16),

                              _buildSummary(
                                totalTagihan,
                                totalPemakaian,
                              ),

                              const SizedBox(height: 22),

                              _buildSectionTitle(),

                              const SizedBox(height: 10),

                              ...visibleTagihans.map(
                                (t) => _buildTagihanCard(t),
                              ),

                              if (filteredTagihans.length > 5) ...[
                                const SizedBox(height: 2),
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
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.08),
          ),
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
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),

              const SizedBox(width: 8),

              Text(
                'NUSANTARA POWER',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF17233D),
                  letterSpacing: -0.2,
                ),
              ),

              const Spacer(),

              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF13213D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 19,
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
              border: Border.all(
                color: const Color(0xFFD0D9E8),
              ),
            ),
            child: TextField(
              controller: _searchController,
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
                suffixIcon: GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    width: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF62D6C7)
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: Color(0xFF009B8D),
                    ),
                  ),
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

  Widget _buildFilterRow(
    List<TagihanAir> tagihans,
  ) {
    final years = _getYears(tagihans);
    final titikMeters = _getTitikMeters(tagihans);

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildDropdownFilter(
            label: _selectedBulan ?? 'Bulan',
            selected: _selectedBulan != null,
            onTap: _showMonthFilter,
          ),

          const SizedBox(width: 8),

          _buildDropdownFilter(
            label: _selectedTahun ?? 'Tahun',
            selected: _selectedTahun != null,
            onTap: () => _showYearFilter(years),
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
            onTap: () => _showTitikMeterFilter(
              titikMeters,
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF14213D)
              : const Color(0xFFE9F1FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF14213D)
                : const Color(0xFFC8D3E5),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : const Color(0xFF24324A),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: selected
                  ? Colors.white
                  : const Color(0xFF33415C),
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

    final master =
        context.read<MasterDataProvider>();

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

  Widget _buildSummary(
    double totalTagihan,
    double totalPemakaian,
  ) {
    final currentYear = DateTime.now().year;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'TOTAL PEMAKAIAN',
            value:
                '${totalPemakaian.toStringAsFixed(0)} m³',
            subtitle: 'Tahun $currentYear',
            dark: true,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildSummaryCard(
            title: 'TOTAL TAGIHAN',
            value: _formatCompactCurrency(
              totalTagihan,
            ),
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
      padding: const EdgeInsets.fromLTRB(
        13,
        11,
        10,
        9,
      ),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF1D2B49)
            : const Color(0xFFDCEAFF),
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
              color: dark
                  ? Colors.white.withValues(
                      alpha: 0.55,
                    )
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
              color: dark
                  ? Colors.white
                  : const Color(0xFF17233D),
            ),
          ),

          const Spacer(),

          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: dark
                  ? Colors.white.withValues(
                      alpha: 0.45,
                    )
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
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFFD1D7E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
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
                padding:
                    const EdgeInsets.fromLTRB(
                  10,
                  9,
                  11,
                  9,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
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
          style: GoogleFonts.inter(
            fontSize: 9,
            color: const Color(0xFF647084),
          ),
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
            value:
                '${t.pemakaian.toStringAsFixed(0)} m³',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8,
            color: const Color(0xFF8A93A3),
          ),
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Total Tagihan',
          style: GoogleFonts.inter(
            fontSize: 8,
            color: const Color(0xFF8A93A3),
          ),
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
        const Icon(
          Icons.photo_outlined,
          size: 13,
          color: Color(0xFF7A8494),
        ),

        const SizedBox(width: 4),

        Text(
          t.fotos.isEmpty
              ? 'Tidak ada foto'
              : '${t.fotos.length} foto',
          style: GoogleFonts.inter(
            fontSize: 8,
            color: const Color(0xFF657080),
          ),
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
          border: Border.all(
            color: const Color(0xFFC9D7EC),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _showAll
                    ? 'Tampilkan Lebih Sedikit'
                    : 'Muat Lebih Banyak',
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

  void _showMonthFilter() {
    _showSelectionSheet(
      title: 'Pilih Bulan',
      items: _months,
      selected: _selectedBulan,
      onSelected: (value) {
        setState(() {
          _selectedBulan = value;
        });

        _loadData();
      },
    );
  }

  void _showYearFilter(
    List<String> years,
  ) {
    _showSelectionSheet(
      title: 'Pilih Tahun',
      items: years,
      selected: _selectedTahun,
      onSelected: (value) {
        setState(() {
          _selectedTahun = value;
        });
      },
    );
  }

  void _showTitikMeterFilter(
    List<String> titikMeters,
  ) {
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
    final master =
        context.read<MasterDataProvider>();

    final items = master.areas
        .map((a) => a.nama)
        .toList();

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

  void _showSelectionSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5D9E0),
                      borderRadius:
                          BorderRadius.circular(4),
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
                    selected:
                        selected == item,
                    onTap: () {
                      Navigator.pop(ctx);
                      onSelected(item);
                    },
                  ),
                ),

                const SizedBox(height: 8),
              ],
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
        margin:
            const EdgeInsets.only(bottom: 6),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE3F6F3)
              : const Color(0xFFF7F8FA),
          borderRadius:
              BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
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
  // FILTER BUTTON
  // ============================================================

  void _showFilterSheet() {
    final master =
        context.read<MasterDataProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding:
                  EdgeInsets.fromLTRB(
                18,
                12,
                18,
                MediaQuery.of(ctx)
                        .viewInsets
                        .bottom +
                    20,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFD5D9E0,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(4),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Filter Riwayat',
                    style:
                        GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          const Color(
                        0xFF17233D,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Bulan',
                    style:
                        GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          const Color(
                        0xFF657080,
                      ),
                    ),
                  ),

                  const SizedBox(height: 7),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildSheetChip(
                        'Semua',
                        _selectedBulan ==
                            null,
                        () {
                          setSheetState(
                            () {
                              _selectedBulan =
                                  null;
                            },
                          );
                        },
                      ),
                      ..._months.map(
                        (month) =>
                            _buildSheetChip(
                          month,
                          _selectedBulan ==
                              month,
                          () {
                            setSheetState(
                              () {
                                _selectedBulan =
                                    month;
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Area',
                    style:
                        GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          const Color(
                        0xFF657080,
                      ),
                    ),
                  ),

                  const SizedBox(height: 7),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildSheetChip(
                        'Semua',
                        _selectedAreaId ==
                            null,
                        () {
                          setSheetState(
                            () {
                              _selectedAreaId =
                                  null;
                            },
                          );
                        },
                      ),
                      ...master.areas.map(
                        (area) =>
                            _buildSheetChip(
                          area.nama,
                          _selectedAreaId ==
                              area.id,
                          () {
                            setSheetState(
                              () {
                                _selectedAreaId =
                                    area.id;
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width:
                        double.infinity,
                    height: 44,
                    child:
                        ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          ctx,
                        );
                        _loadData();
                      },
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            AppTheme
                                .primary,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            8,
                          ),
                        ),
                      ),
                      child: Text(
                        'Terapkan Filter',
                        style:
                            GoogleFonts
                                .inter(
                          fontSize: 11,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetChip(
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary
              : const Color(0xFFF1F4F8),
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight:
                FontWeight.w500,
            color: selected
                ? Colors.white
                : const Color(
                    0xFF3D495C,
                  ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL
  // ============================================================

  void _showDetail(TagihanAir t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              22,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration:
                        BoxDecoration(
                      color: const Color(
                        0xFFD5D9E0,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(4),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  t.periodeLabel,
                  style:
                      GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        const Color(
                      0xFF17233D,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  t.areaNama,
                  style:
                      GoogleFonts.inter(
                    fontSize: 10,
                    color:
                        const Color(
                      0xFF7C8696,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                _buildDetailRow(
                  'Titik Meter',
                  t.titikMeterNama,
                ),

                _buildDetailRow(
                  'Lokasi Flow Meter',
                  t.lokasiFlowMeter ??
                      '-',
                ),

                _buildDetailRow(
                  'Meter Sebelumnya',
                  t.meterLalu
                      .toStringAsFixed(0),
                ),

                _buildDetailRow(
                  'Meter Saat Ini',
                  t.meterIni
                      .toStringAsFixed(0),
                ),

                _buildDetailRow(
                  'Faktor Meter',
                  t.meterFaktor
                      .toStringAsFixed(2),
                ),

                _buildDetailRow(
                  'Pemakaian',
                  '${t.pemakaian.toStringAsFixed(0)} m³',
                ),

                _buildDetailRow(
                  'Tarif',
                  _currencyFormat.format(
                    t.tarif,
                  ),
                ),

                _buildDetailRow(
                  'Total Tagihan',
                  _currencyFormat.format(
                    t.jumlah,
                  ),
                ),

                _buildDetailRow(
                  'Dokumentasi',
                  t.fotos.isEmpty
                      ? 'Tidak ada foto'
                      : '${t.fotos.length} foto',
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  GoogleFonts.inter(
                fontSize: 10,
                color:
                    const Color(
                  0xFF7C8696,
                ),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style:
                  GoogleFonts.inter(
                fontSize: 10,
                fontWeight:
                    FontWeight.w600,
                color:
                    const Color(
                  0xFF1C2940,
                ),
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
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height:
              MediaQuery.of(context)
                      .size
                      .height *
                  0.55,
          child: Center(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration:
                      BoxDecoration(
                    color: AppTheme
                        .primary
                        .withValues(
                      alpha: 0.08,
                    ),
                    shape: BoxShape
                        .circle,
                  ),
                  child: Icon(
                    Icons
                        .receipt_long_rounded,
                    size: 30,
                    color: AppTheme
                        .primary
                        .withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Belum ada riwayat tagihan',
                  style:
                      GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                    color: AppTheme
                        .textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Data tagihan akan muncul di sini.',
                  style:
                      GoogleFonts.inter(
                    fontSize: 10,
                    color:
                        AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}