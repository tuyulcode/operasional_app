import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/area.dart';
import '../../models/titik_meter.dart';
import '../../providers/master_data_provider.dart';
import '../../screens/profile/profile_screen.dart';
import '../../widgets/tappable.dart';
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
      prov.loadPpnAktif();
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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Card: Lokasi Meter ──
                  _buildSectionCard(
                    icon: Icons.location_on_rounded,
                    title: 'Lokasi Meter',
                    children: [
                      _buildLabel('Pilih Area'),
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
                      const SizedBox(height: 16),
                      _buildLabel('Pilih Titik Meter'),
                      const SizedBox(height: 8),
                      _buildDropdown<TitikMeter>(
                        hint: _selectedArea == null
                            ? 'Pilih area terlebih dahulu'
                            : 'Pilih Titik Metering',
                        value: _selectedTitikMeter,
                        items: filteredTitikMeter,
                        itemLabel: (tm) => tm.nama,
                        onChanged: _selectedArea == null
                            ? null
                            : (tm) => setState(() => _selectedTitikMeter = tm),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Card: Periode Tagihan ──
                  _buildSectionCard(
                    icon: Icons.calendar_today_rounded,
                    title: 'Periode Tagihan',
                    children: [
                      _buildLabel('Pilih Periode'),
                      const SizedBox(height: 8),
                      _buildPeriodePicker(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Lanjut button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _canNext ? _next : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canNext
                            ? AppTheme.primary
                            : AppTheme.textMuted.withValues(alpha: 0.4),
                        disabledBackgroundColor:
                            AppTheme.textMuted.withValues(alpha: 0.4),
                        foregroundColor: Colors.white,
                        elevation: 0,
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
                          const SizedBox(width: 8),
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

  // ── Header: putih bersih, tombol back + ikon petir + judul, avatar kanan, stepper putus-putus ──
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Tappable(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      size: 18, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
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
                'INPUT TAGIHAN',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              // Menu profil — tap untuk membuka ProfileScreen
              Tappable(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
                circular: true,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
          // Connector: garis putus-putus
          final stepIdx = i ~/ 2;
          final isDone = stepIdx < currentStep;
          return Expanded(
            child: _DashedLine(
              color: isDone
                  ? AppTheme.primary
                  : AppTheme.divider.withValues(alpha: 0.6),
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final isActive = stepIdx == currentStep;
        final isCompleted = stepIdx < currentStep;
        return Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isActive || isCompleted
                    ? AppTheme.secondary
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive || isCompleted
                      ? AppTheme.secondary
                      : AppTheme.divider,
                  width: 1.4,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${stepIdx + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : AppTheme.textMuted,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              steps[stepIdx],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive || isCompleted
                    ? AppTheme.textPrimary
                    : AppTheme.textMuted,
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Card pembungkus tiap section (Lokasi Meter / Periode Tagihan) ──
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pemakaianCardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
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

    return Tappable(
      onTap: () async {
        DateTime initialDate;
        if (_selectedPeriode != null) {
          final parts = _selectedPeriode!.split('-');
          initialDate = DateTime(int.parse(parts[0]), int.parse(parts[1]));
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
        if (picked != null && mounted) {
          setState(() {
            _selectedPeriode =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
          });
        }
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                displayText.isEmpty ? 'Pilih Bulan & Tahun' : displayText,
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

// ── Garis putus-putus untuk connector stepper ──
class _DashedLine extends StatelessWidget {
  final Color color;
  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 4.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Padding(
          padding: const EdgeInsets.only(bottom: 22), // sejajar tengah lingkaran
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: 1.4,
                child: DecoratedBox(decoration: BoxDecoration(color: color)),
              );
            }),
          ),
        );
      },
    );
  }
}