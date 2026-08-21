class ApiConfig {
// Ganti baseUrl sesuai perangkat yang digunakan:
  // 1. Android Emulator:
  // static const String baseUrl = 'http://10.0.2.2/operasional_app/api';
  
  // 2. HP Fisik Android (Gunakan IP Wi-Fi laptop):
  // static const String baseUrl = 'http://10.7.197.29/operasional_app/api';

  // 3. Browser / Windows Desktop:
  static const String baseUrl = 'http://localhost/operasional_app/api';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static Map<String, String> get defaultHeaders => {
        'Accept': 'application/json',
      };
}
