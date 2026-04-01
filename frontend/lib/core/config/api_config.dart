/// Backend base URL without trailing slash.
///
/// Override at build time:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com`
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
}
