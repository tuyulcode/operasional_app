import 'dart:convert';
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

  // Cek status login cukup dari data user yang tersimpan lokal di HP.
  // Tidak ada token/verifikasi ke server sama sekali.
  Future<void> checkAuth() async {
    final userJson = await StorageService.getUserJson();

    if (userJson == null) {
      _isLoggedIn = false;
      notifyListeners();
      return;
    }

    try {
      _user = User.fromJson(jsonDecode(userJson));
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

      await StorageService.saveUsername(username);
      await StorageService.saveUserJson(jsonEncode(res.data['user']));

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