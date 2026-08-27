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
import '../../screens/profile/profile_screen.dart';
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
        } else {
          // Belum ada data periode sebelumnya (input pertama kali)
          // → biarkan kosong, user isi manual
          _meterLaluController.text = '';
          _meterLaluAutoFilled = false;
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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info lokasi terpilih
                  _buildLocationInfo(),
                  const SizedBox(height: 20),

                  // Pencatatan Meter
                  _buildSectionTitle(
                      Icons.speed_rounded, 'Pencatatan Meter'),
                  const SizedBox(height: 12),
                  _buildMeterCard(),
                  const SizedBox(height: 20),

                  // Ringkasan Tagihan
                  _buildEstimateCard(),
                  const SizedBox(height: 20),

                  // Bukti Foto
                  _buildSectionTitle(
                      Icons.camera_alt_rounded, 'Bukti Foto Meteran'),
                  const SizedBox(height: 12),
                  _buildPhotoSection(),
                  const SizedBox(height: 24),

                  // Simpan & Lanjutkan
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
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_rounded,
                              size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Simpan & Lanjutkan',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 15,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Batal
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
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

  // ── Header (sama seperti step1 & step3) ──
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
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppTheme.textPrimary, size: 18),
                ),
              ),
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
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
          final isDone = stepIdx < currentStep;
          return Expanded(
            child: isDone
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Container(height: 2, color: AppTheme.primary),
                  )
                : Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: _DashedLine(
                        color: AppTheme.divider.withValues(alpha: 0.7)),
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
                color: isCompleted
                    ? AppTheme.primary
                    : (isActive ? AppTheme.secondary : Colors.white),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? AppTheme.primary
                      : (isActive ? AppTheme.secondary : AppTheme.divider),
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
                          color: isActive ? Colors.white : AppTheme.textMuted,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              steps[stepIdx],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight:
                    isActive || isCompleted ? FontWeight.w700 : FontWeight.w400,
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

  // ── Card Lokasi Terpilih ──
  Widget _buildLocationInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.pemakaianCardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                'LOKASI TERPILIH',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.edit_rounded,
                    size: 16, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.area.nama} - ${widget.titikMeter.nama}',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 5),
              Text(
                'Meter ID: ${widget.titikMeter.id}',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 5),
              Text(
                'Periode: ${widget.periode}',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13, color: AppTheme.primary),
        ),
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
    );
  }

  // ── Card putih berisi semua field pencatatan meter ──
  Widget _buildMeterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meter Bulan Lalu
          // → Jika ada riwayat periode sebelumnya: auto-fill & terkunci (readonly)
          // → Jika belum ada riwayat (input pertama kali): bisa diisi manual
          Row(
            children: [
              _buildFieldLabel('Meter Bulan Lalu (m\u00b3)'),
              if (!_isLoadingMeterLalu && !_meterLaluAutoFilled)
                Text(' *',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.error)),
            ],
          ),
          const SizedBox(height: 6),
          if (_isLoadingMeterLalu)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FB),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const SizedBox(
                height: 20,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primary),
                  ),
                ),
              ),
            )
          else if (_meterLaluAutoFilled)
            // Sudah ada riwayat periode sebelumnya → readonly & terkunci
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FB),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _meterLaluController.text,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.lock_outline_rounded,
                      size: 16, color: AppTheme.textMuted),
                ],
              ),
            )
          else
            // Belum ada riwayat (input pertama kali) → bisa diisi manual
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _meterLaluController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle:
                            GoogleFonts.inter(color: AppTheme.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Icon(Icons.edit_note_rounded,
                      size: 20, color: AppTheme.textMuted),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _isLoadingMeterLalu
                      ? 'Memeriksa data periode sebelumnya\u2026'
                      : (_meterLaluAutoFilled
                          ? 'Otomatis dari periode sebelumnya \u00b7 terkunci'
                          : 'Belum ada data periode sebelumnya, silakan isi manual'),
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Meter Bulan Ini (required)
          Row(
            children: [
              _buildFieldLabel('Meter Bulan Ini (m\u00b3)'),
              Text(' *',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.error)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _meterIniController,
                    autofocus: false,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: GoogleFonts.inter(color: AppTheme.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Icon(Icons.edit_note_rounded,
                    size: 20, color: AppTheme.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Meter Faktor & Tarif
          Row(
            children: [
              Expanded(
                child: _buildMiniField(
                  label: 'Meter Faktor',
                  controller: _meterFaktorController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniField(
                  label: 'Tarif (Rp/m\u00b3)',
                  controller: _tarifController,
                  prefix: 'Rp ',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pemakaian Terkoreksi (highlight)
          _buildFieldLabel('Pemakaian Terkoreksi (m\u00b3)'),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              _pemakaian.toStringAsFixed(2),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildMiniField({
    required String label,
    required TextEditingController controller,
    String? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5FB),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              prefixText: prefix,
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  // ── Card Estimasi Tagihan (dark navy) ──
  Widget _buildEstimateCard() {
    final tarif = double.tryParse(_tarifController.text) ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppTheme.heroCardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -10,
            child: Icon(
              Icons.receipt_long_rounded,
              size: 90,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ESTIMASI TAGIHAN',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppTheme.heroCardLabel,
                    ),
                  ),
                  Icon(Icons.receipt_long_rounded,
                      size: 18, color: AppTheme.heroCardLabel),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tarif: ${_currencyFormat.format(tarif)} / m\u00b3',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.heroCardLabel,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _currencyFormat.format(_estimasi),
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bukti Foto Meteran (single dashed box + thumbnail strip) ──
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
              child: _photoOptionBox(
                icon: Icons.camera_alt_rounded,
                label: 'Ambil Foto',
                onTap: _fotos.length >= 10 ? null : _pickPhoto,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _photoOptionBox(
                icon: Icons.upload_file_rounded,
                label: 'Pilih File',
                onTap: _fotos.length >= 10 ? null : _pickFromGallery,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Format JPG, PNG (Max 5MB) \u00b7 ${_fotos.length}/10 foto',
          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _photoOptionBox({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorderBox(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Kotak dengan border putus-putus untuk area upload foto ──
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: AppTheme.divider,
        radius: AppTheme.radiusMd,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.7, 0.7, size.width - 1.4, size.height - 1.4),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      const dashWidth = 5.0;
      const dashSpace = 4.0;
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}

// ── Garis putus-putus untuk connector stepper (sama seperti step1) ──
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
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1.4,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}