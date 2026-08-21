import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  User? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;

  Future<void> checkAuth() async {
    final token = await StorageService.getToken();
    if (token == null) {
      _isLoggedIn = false;
      notifyListeners();
      return;
    }

    try {
      final res = await _api.getUser();
      _user = User.fromJson(res.data['user']);
      _isLoggedIn = true;
    } catch (_) {
      _isLoggedIn = false;
      await StorageService.clearAll();
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.login(username, password);
      final token = res.data['token'] as String;
      await StorageService.saveToken(token);
      await StorageService.saveUsername(username);

      _user = User.fromJson(res.data['user']);
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response?.statusCode == 401) {
        _error = 'Username atau password salah.';
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        _error = e.response?.data['message'];
      } else {
        _error = 'Gagal terhubung ke server.';
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await StorageService.clearAll();
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
