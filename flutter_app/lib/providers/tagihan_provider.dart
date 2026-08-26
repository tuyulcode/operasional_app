import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/tagihan_air.dart';
import '../services/api_service.dart';

class TagihanProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<TagihanAir> _tagihans = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  String? _successMessage;

  List<TagihanAir> get tagihans => _tagihans;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _error = null;
    _successMessage = null;
  }

  Future<void> loadTagihan({int? areaId, String? bulan, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getTagihanAir(
        areaId: areaId,
        bulan: bulan,
        search: search,
      );
      _tagihans = (res.data['data'] as List)
          .map((t) => TagihanAir.fromJson(t))
          .toList();
    } catch (e) {
      _error = 'Gagal memuat data tagihan.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<double?> getMeterLalu(int titikMeterId, String periode) async {
    try {
      final res = await _api.getMeterLalu(titikMeterId, periode);
      if (res.data['auto_filled'] == true) {
        return (res.data['meter_lalu'] as num).toDouble();
      }
    } catch (_) {}
    return null;
  }

  Future<bool> storeTagihan({
    required int titikMeterId,
    required String periode,
    required double meterIni,
    required double meterFaktor,
    required double tarif,
    double? meterLalu,
    List<File>? fotos,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _api.storeTagihanAir(
        titikMeterId: titikMeterId,
        periode: periode,
        meterIni: meterIni,
        meterFaktor: meterFaktor,
        tarif: tarif,
        meterLalu: meterLalu,
        fotos: fotos,
      );
      _successMessage = 'Tagihan air berhasil ditambahkan.';
      _isSubmitting = false;
      notifyListeners();
      // Refresh the shared list so screens kept alive elsewhere (e.g.
      // Riwayat behind an IndexedStack) see the new record immediately,
      // without needing a manual pull-to-refresh.
      unawaited(loadTagihan());
      return true;
    } on DioException catch (e) {
      _isSubmitting = false;
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          _error = firstError is List ? firstError.first : firstError.toString();
        } else {
          _error = data['message'] ?? 'Gagal menyimpan tagihan.';
        }
      } else {
        _error = 'Gagal terhubung ke server.';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTagihan(int id) async {
    try {
      await _api.deleteTagihanAir(id);
      _tagihans.removeWhere((t) => t.id == id);
      _successMessage = 'Tagihan air berhasil dihapus.';
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Gagal menghapus tagihan.';
      notifyListeners();
      return false;
    }
  }
}