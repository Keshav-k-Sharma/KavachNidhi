/// Backend base URL without trailing slash.
///
/// Override at build time:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com`
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://kavachnidhi.onrender.com',
  );
}
