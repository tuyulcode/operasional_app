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

class InputStep3Screen extends StatefulWidget {
  final Area area;
  final TitikMeter titikMeter;
  final String periode;
  final double meterLalu;
  final double meterIni;
  final double meterFaktor;
  final double tarif;
  final double pemakaian;
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lokasi
                  _buildSection('Lokasi Meter', [
                    _reviewRow('Area', widget.area.nama),
                    _reviewRow('Titik Meter', widget.titikMeter.nama),
                    _reviewRow('Periode', widget.periode),
                  ]),
                  const SizedBox(height: 16),

                  // Data Meter
                  _buildSection('Data Pencatatan', [
                    _reviewRow('Meter Lalu', '${widget.meterLalu.toStringAsFixed(2)} m³'),
                    _reviewRow('Meter Ini', '${widget.meterIni.toStringAsFixed(2)} m³'),
                    _reviewRow('Meter Faktor', widget.meterFaktor.toString()),
                    _reviewRow('Tarif/m³', _currencyFormat.format(widget.tarif)),
                    _reviewRow('Pemakaian', '${widget.pemakaian.toStringAsFixed(2)} m³'),
                  ]),
                  const SizedBox(height: 16),

                  // Estimasi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ESTIMASI TAGIHAN',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: Colors.white.withValues(alpha: 0.8))),
                            const SizedBox(height: 4),
                            Text(
                              _currencyFormat.format(widget.estimasi),
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long_rounded,
                              color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Foto
                  if (widget.fotos.isNotEmpty) ...[
                    _buildSectionTitle('Bukti Foto Meteran'),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.fotos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          child: Image.file(widget.fotos[i],
                              width: 90, height: 90, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: prov.isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
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
                                const Icon(Icons.check_circle_rounded,
                                    size: 20, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'KONFIRMASI & SIMPAN',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text('Kembali untuk Edit',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                    ),
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
          return Expanded(
            child: Container(height: 2, color: Colors.white),
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
              decoration: const BoxDecoration(
                color: Colors.white,
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
                              : AppTheme.textMuted,
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
                color: Colors.white,
              ),
            ),
          ],
        );
      }),
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

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
