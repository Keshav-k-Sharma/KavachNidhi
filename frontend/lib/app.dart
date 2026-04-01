import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/auth/auth_controller.dart';
import 'package:frontend/core/auth/auth_repository.dart';
import 'package:frontend/core/auth/token_storage.dart';
import 'package:frontend/core/navigation/app_navigator.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/presentation/splash_page.dart';

class KavachNidhiApp extends StatefulWidget {
  const KavachNidhiApp({super.key});

  @override
  State<KavachNidhiApp> createState() => _KavachNidhiAppState();
}

class _KavachNidhiAppState extends State<KavachNidhiApp> {
  AuthController? _auth;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final TokenStorage storage = TokenStorage();
    final ApiClient client = ApiClient();
    final AuthRepository repo = AuthRepository(client: client);
    final AuthController controller = AuthController(
      tokenStorage: storage,
      apiClient: client,
      authRepository: repo,
    );
    await controller.bootstrap();
    if (!mounted) {
      return;
    }
    setState(() => _auth = controller);
  }

  @override
  Widget build(BuildContext context) {
    if (_auth == null) {
      return MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'KavachNidhi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme(),
        home: const SplashPage(),
      );
    }

    return ChangeNotifierProvider<AuthController>.value(
      value: _auth!,
      child: Consumer<AuthController>(
        builder: (BuildContext context, AuthController auth, _) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            title: 'KavachNidhi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme(),
            initialRoute: auth.isAuthenticated
                ? AppRouter.homeRoute
                : AppRouter.loginRoute,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
