import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/area.dart';
import '../../models/titik_meter.dart';
import '../../providers/master_data_provider.dart';
import 'input_step2_screen.dart';

class InputStep1Screen extends StatefulWidget {
  const InputStep1Screen({super.key});

  @override
  State<InputStep1Screen> createState() => _InputStep1ScreenState();
}

class _InputStep1ScreenState extends State<InputStep1Screen> {
  Area? _selectedArea;
  TitikMeter? _selectedTitikMeter;
  String? _selectedPeriode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<MasterDataProvider>();
      prov.loadAreas();
      prov.loadTitikMeter();
    });
    // Default: current month
    final now = DateTime.now();
    _selectedPeriode =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  bool get _canNext =>
      _selectedArea != null &&
      _selectedTitikMeter != null &&
      _selectedPeriode != null;

  void _next() {
    if (!_canNext) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InputStep2Screen(
          area: _selectedArea!,
          titikMeter: _selectedTitikMeter!,
          periode: _selectedPeriode!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final master = context.watch<MasterDataProvider>();

    final filteredTitikMeter = _selectedArea != null
        ? master.titikMeters
            .where((tm) => tm.areaId == _selectedArea!.id)
            .toList()
        : <TitikMeter>[];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lokasi Meter info card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      border:
                          Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lokasi Meter',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pilih Area
                  _buildLabel('Pilih Area Operasional'),
                  const SizedBox(height: 8),
                  _buildDropdown<Area>(
                    hint: 'Pilih Area Operasional',
                    value: _selectedArea,
                    items: master.areas,
                    itemLabel: (a) => a.nama,
                    onChanged: (a) {
                      setState(() {
                        _selectedArea = a;
                        _selectedTitikMeter = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Pilih Titik Meter
                  _buildLabel('Pilih Titik Meter'),
                  const SizedBox(height: 8),
                  _buildDropdown<TitikMeter>(
                    hint: _selectedArea == null
                        ? 'Pilih area terlebih dahulu'
                        : 'Pilih Titik Meteran',
                    value: _selectedTitikMeter,
                    items: filteredTitikMeter,
                    itemLabel: (tm) => tm.nama,
                    onChanged: _selectedArea == null
                        ? null
                        : (tm) => setState(() => _selectedTitikMeter = tm),
                  ),
                  const SizedBox(height: 20),

                  // Periode Tagihan
                  _buildLabel('Periode Tagihan'),
                  const SizedBox(height: 8),
                  _buildPeriodePicker(),
                  const SizedBox(height: 8),
                  _buildLabel('Pilih Bulan & Tahun', isSmall: true),
                  const SizedBox(height: 24),

                  // Lanjut button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _canNext ? _next : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canNext
                            ? AppTheme.primary
                            : AppTheme.primary.withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lanjut Pengisian Data',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
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
              const SizedBox(width: 12),
              Text(
                'TAGIHAN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '+ Input Meter',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stepper
          _buildStepper(0),
        ],
      ),
    );
  }

  Widget _buildStepper(int currentStep) {
    final steps = ['Lokasi', 'Data', 'Review'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIdx = i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: stepIdx < currentStep
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final isActive = stepIdx == currentStep;
        final isCompleted = stepIdx < currentStep;
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isActive || isCompleted
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: AppTheme.primary)
                    : Text(
                        '${stepIdx + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppTheme.primary
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIdx],
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive || isCompleted
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildLabel(String text, {bool isSmall = false}) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: isSmall ? 12 : 13,
        fontWeight: isSmall ? FontWeight.w400 : FontWeight.w600,
        color: isSmall ? AppTheme.textMuted : AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.inter(
                fontSize: 14, color: AppTheme.textMuted),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textMuted),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabel(item),
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppTheme.textPrimary),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPeriodePicker() {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    String displayText = '';
    if (_selectedPeriode != null) {
      final parts = _selectedPeriode!.split('-');
      final year = parts[0];
      final monthIdx = int.parse(parts[1]) - 1;
      displayText = '${months[monthIdx]} $year';
    }

    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: AppTheme.primary),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _selectedPeriode =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 18, color: AppTheme.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                displayText.isEmpty ? 'Pilih Periode' : displayText,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: displayText.isEmpty
                      ? AppTheme.textMuted
                      : AppTheme.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
