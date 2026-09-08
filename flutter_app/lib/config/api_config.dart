class ApiConfig {
  // Ganti ke domain hosting kamu
  static const String baseUrl = 'https://operasional.umumcsr.com/api';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static Map<String, String> get defaultHeaders => {
        'Accept': 'application/json',
      };
}