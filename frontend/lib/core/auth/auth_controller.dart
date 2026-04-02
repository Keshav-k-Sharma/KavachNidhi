import 'package:flutter/widgets.dart';

import 'package:frontend/core/auth/auth_repository.dart';
import 'package:frontend/core/auth/token_storage.dart';
import 'package:frontend/core/navigation/app_navigator.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/router/app_router.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required TokenStorage tokenStorage,
    required ApiClient apiClient,
    required AuthRepository authRepository,
  })  : _tokenStorage = tokenStorage,
        _apiClient = apiClient,
        _authRepository = authRepository {
    _apiClient.tokenGetter = () => accessToken;
    _apiClient.onUnauthorized = _onUnauthorized;
  }

  final TokenStorage _tokenStorage;
  final ApiClient _apiClient;
  final AuthRepository _authRepository;

  bool ready = false;
  String? accessToken;
  String? userId;

  ApiClient get apiClient => _apiClient;

  bool get isAuthenticated =>
      accessToken != null && accessToken!.isNotEmpty;

  Future<void> bootstrap() async {
    try {
      final List<String?> results = await Future.wait<String?>(<Future<String?>>[
        _tokenStorage.readAccessToken(),
        _tokenStorage.readUserId(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () => <String?>[null, null],
      );
      accessToken = results[0];
      userId = results[1];
    } catch (_) {
      accessToken = null;
      userId = null;
    }
    ready = true;
    notifyListeners();
  }

  Future<void> requestOtp(String phoneDigits) =>
      _authRepository.sendOtp(phoneDigits);

  Future<void> signInWithOtp({
    required String phoneDigits,
    required String otp,
  }) async {
    final ({String accessToken, String userId}) result =
        await _authRepository.verifyOtp(phone: phoneDigits, otp: otp);
    await _tokenStorage.saveSession(
      accessToken: result.accessToken,
      userId: result.userId,
    );
    accessToken = result.accessToken;
    userId = result.userId;
    notifyListeners();
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    accessToken = null;
    userId = null;
    notifyListeners();
  }

  void _onUnauthorized() {
    // Clear session without awaiting to avoid re-entrancy issues.
    _tokenStorage.clear().then((_) {
      accessToken = null;
      userId = null;
      notifyListeners();
      appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRouter.loginRoute,
        (Route<dynamic> route) => false,
      );
    });
  }
}
