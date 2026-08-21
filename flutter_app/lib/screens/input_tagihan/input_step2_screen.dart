import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/area.dart';
import '../../models/titik_meter.dart';
import '../../providers/tagihan_provider.dart';
import 'input_step3_screen.dart';

class InputStep2Screen extends StatefulWidget {
  final Area area;
  final TitikMeter titikMeter;
  final String periode;

  const InputStep2Screen({
    super.key,
    required this.area,
    required this.titikMeter,
    required this.periode,
  });

  @override
  State<InputStep2Screen> createState() => _InputStep2ScreenState();
}

class _InputStep2ScreenState extends State<InputStep2Screen> {
  final _meterLaluController = TextEditingController();
  final _meterIniController = TextEditingController();
  final _meterFaktorController = TextEditingController();
  final _tarifController = TextEditingController();

  bool _meterLaluAutoFilled = false;
  bool _isLoadingMeterLalu = true;
  List<File> _fotos = [];

  final _picker = ImagePicker();
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _meterFaktorController.text = widget.titikMeter.meterFaktor.toString();
    _tarifController.text = widget.titikMeter.tarifHarga.toStringAsFixed(0);
    _fetchMeterLalu();
  }

  @override
  void dispose() {
    _meterLaluController.dispose();
    _meterIniController.dispose();
    _meterFaktorController.dispose();
    _tarifController.dispose();
    super.dispose();
  }

  Future<void> _fetchMeterLalu() async {
    final prov = context.read<TagihanProvider>();
    final val = await prov.getMeterLalu(widget.titikMeter.id, widget.periode);
    if (mounted) {
      setState(() {
        _isLoadingMeterLalu = false;
        if (val != null) {
          _meterLaluController.text = val.toStringAsFixed(2);
          _meterLaluAutoFilled = true;
        }
      });
    }
  }

  double get _pemakaian {
    final ini = double.tryParse(_meterIniController.text) ?? 0;
    final lalu = double.tryParse(_meterLaluController.text) ?? 0;
    final faktor = double.tryParse(_meterFaktorController.text) ?? 1;
    return (ini - lalu) * faktor;
  }

  double get _estimasi {
    final tarif = double.tryParse(_tarifController.text) ?? 0;
    return _pemakaian * tarif;
  }

  bool get _canNext {
    return _meterIniController.text.isNotEmpty &&
        (_meterLaluAutoFilled || _meterLaluController.text.isNotEmpty) &&
        _meterFaktorController.text.isNotEmpty &&
        _tarifController.text.isNotEmpty;
  }

  Future<void> _pickPhoto() async {
    if (_fotos.length >= 10) return;
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _fotos.add(File(picked.path)));
    }
  }

  Future<void> _pickFromGallery() async {
    if (_fotos.length >= 10) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _fotos.add(File(picked.path)));
    }
  }

  void _next() {
    if (!_canNext) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InputStep3Screen(
          area: widget.area,
          titikMeter: widget.titikMeter,
          periode: widget.periode,
          meterLalu: double.tryParse(_meterLaluController.text) ?? 0,
          meterIni: double.tryParse(_meterIniController.text) ?? 0,
          meterFaktor: double.tryParse(_meterFaktorController.text) ?? 1,
          tarif: double.tryParse(_tarifController.text) ?? 0,
          pemakaian: _pemakaian,
          estimasi: _estimasi,
          fotos: _fotos,
          meterLaluManual: !_meterLaluAutoFilled,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  _buildLocationInfo(),
                  const SizedBox(height: 20),

                  // Pencatatan Meter
                  _buildSectionTitle('Pencatatan Meter'),
                  const SizedBox(height: 12),

                  _buildInputRow(
                    'Meter Bulan Lalu (m³)',
                    _meterLaluController,
                    readOnly: _meterLaluAutoFilled,
                    isLoading: _isLoadingMeterLalu,
                    hint: _meterLaluAutoFilled
                        ? 'Auto dari periode sebelumnya'
                        : 'Masukkan manual (data awal)',
                  ),
                  const SizedBox(height: 14),

                  _buildInputRow(
                    'Meter Bulan Ini (m³)',
                    _meterIniController,
                    hint: 'Masukkan angka meter',
                    autofocus: true,
                  ),
                  const SizedBox(height: 14),

                  _buildInputRow(
                    'Total Pemakaian (m³)',
                    null,
                    displayValue: _pemakaian.toStringAsFixed(2),
                    readOnly: true,
                  ),
                  const SizedBox(height: 14),

                  _buildInputRow(
                    'Meter Faktor',
                    _meterFaktorController,
                    hint: '1',
                  ),
                  const SizedBox(height: 14),

                  _buildInputRow(
                    'Tarif (Rp/m³)',
                    _tarifController,
                    hint: 'Tarif per m3',
                    prefix: 'Rp ',
                  ),
                  const SizedBox(height: 20),

                  // Ringkasan Tagihan
                  _buildSectionTitle('Ringkasan Tagihan'),
                  const SizedBox(height: 12),
                  _buildEstimateCard(),
                  const SizedBox(height: 20),

                  // Bukti Foto
                  _buildSectionTitle('Bukti Foto Meteran'),
                  const SizedBox(height: 12),
                  _buildPhotoSection(),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text('Kembali',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _canNext ? _next : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: _canNext
                                ? AppTheme.primary
                                : AppTheme.primary.withValues(alpha: 0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Lanjut Review',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  )),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
            ],
          ),
          const SizedBox(height: 16),
          _buildStepper(1),
        ],
      ),
    );
  }

  Widget _buildStepper(int currentStep) {
    final steps = ['Lokasi', 'Data', 'Review'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
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
                    ? const Icon(Icons.check,
                        size: 16, color: AppTheme.primary)
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

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _infoRow(Icons.location_on_rounded, 'Area', widget.area.nama),
          const Divider(height: 16),
          _infoRow(Icons.speed_rounded, 'Titik Meter', widget.titikMeter.nama),
          const Divider(height: 16),
          _infoRow(Icons.calendar_today_rounded, 'Periode', widget.periode),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppTheme.textSecondary)),
        Expanded(
          child: Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildInputRow(
    String label,
    TextEditingController? controller, {
    String? hint,
    String? prefix,
    String? displayValue,
    bool readOnly = false,
    bool autofocus = false,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          if (isLoading)
            const SizedBox(
              height: 24,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primary),
                ),
              ),
            )
          else if (displayValue != null)
            Text(
              displayValue,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            )
          else
            TextField(
              controller: controller,
              readOnly: readOnly,
              autofocus: autofocus,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                prefixText: prefix,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
        ],
      ),
    );
  }

  Widget _buildEstimateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Meter Bulan Ini',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8))),
              Text(
                  '${double.tryParse(_meterIniController.text)?.toStringAsFixed(2) ?? "0.00"} m³',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Meter Bulan Lalu',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8))),
              Text(
                  '${double.tryParse(_meterLaluController.text)?.toStringAsFixed(2) ?? "0.00"} m³',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pemakaian',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8))),
              Text('${_pemakaian.toStringAsFixed(2)} m³',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
          const Divider(color: Colors.white30, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Estimasi',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Text(_currencyFormat.format(_estimasi),
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      children: [
        if (_fotos.isNotEmpty)
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _fotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: Image.file(_fotos[i],
                        width: 90, height: 90, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _fotos.removeAt(i)),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_fotos.isNotEmpty) const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _photoButton(
                Icons.camera_alt_rounded,
                'Ambil Foto',
                _pickPhoto,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _photoButton(
                Icons.photo_library_rounded,
                'Galeri',
                _pickFromGallery,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${_fotos.length}/10 foto (opsional)',
          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _photoButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: _fotos.length >= 10 ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppTheme.textMuted),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
