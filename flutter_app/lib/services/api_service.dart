import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.defaultHeaders,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          StorageService.clearAll();
        }
        return handler.next(error);
      },
    ));
  }

  // ── Auth ──
  Future<Response> login(String username, String password) async {
    return _dio.post('/login.php', data: {
      'username': username,
      'password': password,
    });
  }

  Future<Response> logout() async {
    return _dio.post('/logout.php');
  }

  Future<Response> getUser() async {
    return _dio.get('/user.php');
  }

  // ── Dashboard ──
  Future<Response> getDashboard() async {
    return _dio.get('/dashboard.php');
  }

  // ── Master Data ──
  Future<Response> getAreas() async {
    return _dio.get('/areas.php');
  }

  Future<Response> getTitikMeter({int? areaId}) async {
    return _dio.get('/titik_meter.php', queryParameters: {
      if (areaId != null) 'area_id': areaId,
    });
  }

  // ── Tagihan Air ──
  Future<Response> getTagihanAir({int? areaId, String? bulan, String? search}) async {
    return _dio.get('/tagihan_air.php', queryParameters: {
      if (areaId != null) 'area_id': areaId,
      if (bulan != null) 'bulan': bulan,
      if (search != null && search.isNotEmpty) 'search': search,
    });
  }

  Future<Response> getTagihanAirDetail(int id) async {
    return _dio.get('/tagihan_air.php', queryParameters: {'id': id});
  }

  Future<Response> getMeterLalu(int titikMeterId, String periode) async {
    return _dio.get('/meter_lalu.php', queryParameters: {
      'titik_meter_id': titikMeterId,
      'periode': periode,
    });
  }

  Future<Response> storeTagihanAir({
    required int titikMeterId,
    required String periode,
    required double meterIni,
    required double meterFaktor,
    required double tarif,
    double? meterLalu,
    List<File>? fotos,
  }) async {
    final formData = FormData.fromMap({
      'titik_meter_id': titikMeterId,
      'periode': periode,
      'meter_ini': meterIni,
      'meter_faktor': meterFaktor,
      'tarif': tarif,
      if (meterLalu != null) 'meter_lalu': meterLalu,
    });

    if (fotos != null && fotos.isNotEmpty) {
      for (final file in fotos) {
        formData.files.add(MapEntry(
          'foto_meter[]',
          await MultipartFile.fromFile(file.path,
              filename: file.path.split(Platform.pathSeparator).last),
        ));
      }
    }

    return _dio.post('/tagihan_air.php', data: formData);
  }

  Future<Response> updateTagihanAir({
    required int id,
    required int titikMeterId,
    required String periode,
    required double meterIni,
    required double meterFaktor,
    required double tarif,
    double? meterLalu,
    List<File>? fotos,
  }) async {
    final formData = FormData.fromMap({
      'titik_meter_id': titikMeterId,
      'periode': periode,
      'meter_ini': meterIni,
      'meter_faktor': meterFaktor,
      'tarif': tarif,
      if (meterLalu != null) 'meter_lalu': meterLalu,
    });

    if (fotos != null && fotos.isNotEmpty) {
      for (final file in fotos) {
        formData.files.add(MapEntry(
          'foto_meter[]',
          await MultipartFile.fromFile(file.path,
              filename: file.path.split(Platform.pathSeparator).last),
        ));
      }
    }

    return _dio.post('/tagihan_air.php?id=$id', data: formData);
  }

  Future<Response> deleteTagihanAir(int id) async {
    return _dio.delete('/tagihan_air.php?id=$id');
  }
}
