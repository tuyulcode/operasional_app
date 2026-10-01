import 'dart:io';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: ApiConfig.defaultHeaders,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await StorageService.clearAll();
          }

          return handler.next(error);
        },
      ),
    );
  }

  // ============================================================
  // AUTH
  // ============================================================

  Future<Response> login(
    String username,
    String password,
  ) async {
    return _dio.post(
      '/login',
      data: {
        'username': username,
        'password': password,
      },
    );
  }

  Future<Response> logout() async {
    return _dio.post('/logout');
  }

  Future<Response> getUser() async {
    return _dio.get('/user');
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Future<Response> getDashboard() async {
    return _dio.get('/dashboard');
  }

  // ============================================================
  // MASTER DATA
  // ============================================================

  Future<Response> getAreas() async {
    return _dio.get('/areas');
  }

  Future<Response> getTitikMeter({
    int? areaId,
  }) async {
    return _dio.get(
      '/titik-meter',
      queryParameters: {
        if (areaId != null) 'area_id': areaId,
      },
    );
  }

  /// Mengambil PPN yang sedang aktif.
  ///
  /// Perhitungan final tetap dilakukan oleh backend Laravel.
  Future<Response> getPpnAktif() async {
    return _dio.get('/ppn');
  }

  // ============================================================
  // TAGIHAN AIR
  // ============================================================

  /// Mengambil daftar tagihan air.
  ///
  /// Filter:
  /// - areaId
  /// - bulan
  /// - search
  Future<Response> getTagihanAir({
    int? areaId,
    String? bulan,
    String? search,
  }) async {
    return _dio.get(
      '/tagihan-air',
      queryParameters: {
        if (areaId != null) 'area_id': areaId,
        if (bulan != null && bulan.isNotEmpty) 'bulan': bulan,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
  }

  /// Mengambil detail satu tagihan.
  ///
  /// Endpoint detail tidak dibuat terpisah di Laravel.
  /// Karena /tagihan-air sudah mendukung filter,
  /// kita ambil seluruh data kemudian cari ID yang diminta
  /// di sisi Flutter.
  Future<Response> getTagihanAirDetail(int id) async {
    final response = await _dio.get('/tagihan-air');

    final responseData = response.data;

    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];

      if (data is List) {
        final found = data.where((item) {
          if (item is! Map) {
            return false;
          }

          return item['id'].toString() == id.toString();
        }).toList();

        return Response(
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
          headers: response.headers,
          data: {
            'data': found.isNotEmpty ? found.first : null,
          },
        );
      }
    }

    return response;
  }

  // ============================================================
  // METER LALU
  // ============================================================

  Future<Response> getMeterLalu(
    int titikMeterId,
    String periode,
  ) async {
    return _dio.get(
      '/tagihan-air/meter-lalu',
      queryParameters: {
        'titik_meter_id': titikMeterId,
        'periode': periode,
      },
    );
  }

  // ============================================================
  // TAMBAH TAGIHAN AIR
  // ============================================================

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

      if (meterLalu != null)
        'meter_lalu': meterLalu,
    });

    // Upload foto meter.
    if (fotos != null && fotos.isNotEmpty) {
      for (final file in fotos) {
        formData.files.add(
          MapEntry(
            'foto_meter[]',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path
                  .split(Platform.pathSeparator)
                  .last,
            ),
          ),
        );
      }
    }

    return _dio.post(
      '/tagihan-air',
      data: formData,
    );
  }

  // ============================================================
  // UPDATE TAGIHAN AIR
  // ============================================================

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

      if (meterLalu != null)
        'meter_lalu': meterLalu,
    });

    // Upload foto tambahan.
    if (fotos != null && fotos.isNotEmpty) {
      for (final file in fotos) {
        formData.files.add(
          MapEntry(
            'foto_meter[]',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path
                  .split(Platform.pathSeparator)
                  .last,
            ),
          ),
        );
      }
    }

    return _dio.post(
      '/tagihan-air?id=$id',
      data: formData,
    );
  }

  // ============================================================
  // DELETE TAGIHAN AIR
  // ============================================================

  Future<Response> deleteTagihanAir(
    int id,
  ) async {
    return _dio.delete(
      '/tagihan-air?id=$id',
    );
  }
}