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
    accessToken = await _tokenStorage.readAccessToken();
    userId = await _tokenStorage.readUserId();
    ready = true;
    notifyListeners();
  }

  Future<void> requestOtp(String phoneE164) =>
      _authRepository.sendOtp(phoneE164);

  Future<void> signInWithOtp({
    required String phoneE164,
    required String otp,
  }) async {
    final ({String accessToken, String userId}) result =
        await _authRepository.verifyOtp(phone: phoneE164, otp: otp);
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
