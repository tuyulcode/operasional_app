import 'package:flutter/material.dart';
import '../models/dashboard_stats.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  DashboardStats? _stats;
  bool _isLoading = false;
  String? _error;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.getDashboard();
      _stats = DashboardStats.fromJson(res.data);
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _error = 'Gagal memuat dashboard.';
    }
    notifyListeners();
  }
}
