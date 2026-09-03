import 'package:flutter/material.dart';
import '../models/area.dart';
import '../models/titik_meter.dart';
import '../services/api_service.dart';

class MasterDataProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Area> _areas = [];
  List<TitikMeter> _titikMeters = [];
  bool _isLoading = false;
  double _ppnPersentaseAktif = 0;

  List<Area> get areas => _areas;
  List<TitikMeter> get titikMeters => _titikMeters;
  bool get isLoading => _isLoading;

  /// Persentase PPN yang sedang aktif — hanya untuk preview/estimasi di
  /// layar input. Nilai final & otoritatif tetap dihitung backend saat
  /// data disimpan, jadi tidak masalah kalau nilai ini sempat stale.
  double get ppnPersentaseAktif => _ppnPersentaseAktif;

  Future<void> loadAreas() async {
    try {
      final res = await _api.getAreas();
      _areas = (res.data['data'] as List)
          .map((a) => Area.fromJson(a))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadPpnAktif() async {
    try {
      final res = await _api.getPpnAktif();
      _ppnPersentaseAktif =
          (res.data['data']['persentase'] as num?)?.toDouble() ?? 0;
      notifyListeners();
    } catch (_) {
      // Diamkan — layar input tetap bisa jalan tanpa preview PPN kalau
      // endpoint ini gagal; backend tetap menghitung yang sebenarnya.
    }
  }

  Future<void> loadTitikMeter({int? areaId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.getTitikMeter(areaId: areaId);
      _titikMeters = (res.data['data'] as List)
          .map((t) => TitikMeter.fromJson(t))
          .toList();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  List<TitikMeter> titikMeterByArea(int areaId) {
    return _titikMeters.where((tm) => tm.areaId == areaId).toList();
  }
}