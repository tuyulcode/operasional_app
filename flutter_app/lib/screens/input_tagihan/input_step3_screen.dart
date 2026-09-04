import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/area.dart';
import '../../models/titik_meter.dart';
import '../../providers/tagihan_provider.dart';
import '../main_shell.dart';
import '../../screens/profile/profile_screen.dart';
import '../../widgets/tappable.dart';

class InputStep3Screen extends StatefulWidget {
  final Area area;
  final TitikMeter titikMeter;
  final String periode;
  final double meterLalu;
  final double meterIni;
  final double meterFaktor;
  final double tarif;
  final double pemakaian;
  final double ppnPersentase;
  final double ppnNominal;
  final double estimasi;
  final List<File> fotos;
  final bool meterLaluManual;

  const InputStep3Screen({
    super.key,
    required this.area,
    required this.titikMeter,
    required this.periode,
    required this.meterLalu,
    required this.meterIni,
    required this.meterFaktor,
    required this.tarif,
    required this.pemakaian,
    this.ppnPersentase = 0,
    this.ppnNominal = 0,
    required this.estimasi,
    required this.fotos,
    required this.meterLaluManual,
  });

  @override
  State<InputStep3Screen> createState() => _InputStep3ScreenState();
}

class _InputStep3ScreenState extends State<InputStep3Screen> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Warna aksen untuk highlight total estimasi (teal/cyan)
  static const Color _accentTeal = Color(0xFF2DD9C4);

  void _submit() async {
    final prov = context.read<TagihanProvider>();
    final success = await prov.storeTagihan(
      titikMeterId: widget.titikMeter.id,
      periode: widget.periode,
      meterIni: widget.meterIni,
      meterFaktor: widget.meterFaktor,
      tarif: widget.tarif,
      meterLalu: widget.meterLaluManual ? widget.meterLalu : null,
      fotos: widget.fotos.isNotEmpty ? widget.fotos : null,
    );

    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.error ?? 'Gagal menyimpan'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Berhasil!',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tagihan air berhasil disimpan.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainShell()),
                      (route) => false,
                    );
                  },
                  child: Text('Kembali ke Dashboard',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TagihanProvider>();

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

                  // Ringkasan Tagihan (dark navy card, gabungan data + estimasi)
                  _buildRingkasanCard(),
                  const SizedBox(height: 20),

                  // Foto
                  if (widget.fotos.isNotEmpty) ...[
                    _buildPhotoCard(),
                    const SizedBox(height: 24),
                  ],

                  // Konfirmasi & Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: prov.isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: prov.isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'KONFIRMASI & SIMPAN',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.save_rounded,
                                    size: 18, color: Colors.white),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Kembali untuk Edit
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            AppTheme.pemakaianCardBg.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Text('Kembali untuk Edit',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              )),
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

  // ── Header (sama seperti step1 & step2) ──
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
                borderRadius: BorderRadius.circular(10),
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
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStepper(2),
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
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Container(
                height: 2,
                color: isDone
                    ? AppTheme.primary
                    : AppTheme.divider.withValues(alpha: 0.7),
              ),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.apartment_rounded,
                size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.area.nama} - ${widget.titikMeter.nama}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Meter ID: ${widget.titikMeter.id}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card Ringkasan Tagihan (dark navy, gabungan data meter + total estimasi) ──
  Widget _buildRingkasanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              size: 100,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_rounded,
                      size: 16, color: AppTheme.heroCardLabel),
                  const SizedBox(width: 6),
                  Text(
                    'Ringkasan Tagihan',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ringkasanRow('Meter Bulan Lalu',
                  '${widget.meterLalu.toStringAsFixed(2)} m\u00b3'),
              const SizedBox(height: 8),
              _ringkasanRow('Meter Bulan Ini',
                  '${widget.meterIni.toStringAsFixed(2)} m\u00b3'),
              const SizedBox(height: 8),
              _ringkasanRow('Pemakaian Terkoreksi',
                  '${widget.pemakaian.toStringAsFixed(2)} m\u00b3'),
              const SizedBox(height: 8),
              _ringkasanRow(
                  'Tarif / m\u00b3', _currencyFormat.format(widget.tarif)),
              const SizedBox(height: 8),
              _ringkasanRow('Jumlah Sebelum PPN',
                  _currencyFormat.format(widget.estimasi - widget.ppnNominal)),
              const SizedBox(height: 8),
              _ringkasanRow(
                'PPN (${widget.ppnPersentase.toStringAsFixed(widget.ppnPersentase % 1 == 0 ? 0 : 2)}%)',
                _currencyFormat.format(widget.ppnNominal),
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Jumlah',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.heroCardLabel,
                    ),
                  ),
                  Text(
                    _currencyFormat.format(widget.estimasi),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _accentTeal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ringkasanRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.heroCardLabel,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ── Card Bukti Foto Meteran (light bg + badge Terlampir) ──
  Widget _buildPhotoCard() {
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
              Icon(Icons.photo_camera_back_rounded,
                  size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text(
                'Bukti Foto Meteran',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 140,
                  child: PageView.builder(
                    itemCount: widget.fotos.length,
                    itemBuilder: (_, i) => Image.file(
                      widget.fotos[i],
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 13, color: AppTheme.success),
                        const SizedBox(width: 4),
                        Text(
                          'Terlampir',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.fotos.length > 1)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.fotos.length} foto',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}