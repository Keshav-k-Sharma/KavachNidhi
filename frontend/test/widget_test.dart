import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/auth/auth_controller.dart';
import 'package:frontend/core/auth/auth_repository.dart';
import 'package:frontend/core/auth/token_storage.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  Future<AuthController> createBootstrappedAuth() async {
    final TokenStorage storage = TokenStorage();
    final ApiClient client = ApiClient();
    final AuthRepository repo = AuthRepository(client: client);
    final AuthController auth = AuthController(
      tokenStorage: storage,
      apiClient: client,
      authRepository: repo,
    );
    await auth.bootstrap();
    return auth;
  }

  Future<void> pumpAuthApp(WidgetTester tester, AuthController auth) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: auth,
        child: MaterialApp(
          theme: AppTheme.darkTheme(),
          initialRoute: AppRouter.loginRoute,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders login screen content', (WidgetTester tester) async {
    final AuthController auth = await createBootstrappedAuth();
    await pumpAuthApp(tester, auth);

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('REQUEST OTP'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
  });

  testWidgets('navigates from login to signup', (WidgetTester tester) async {
    final AuthController auth = await createBootstrappedAuth();
    await pumpAuthApp(tester, auth);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Join'), findsOneWidget);
    expect(find.textContaining('KavachNidhi'), findsWidgets);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
  });

  testWidgets('navigates from signup back to login', (
    WidgetTester tester,
  ) async {
    final AuthController auth = await createBootstrappedAuth();
    await pumpAuthApp(tester, auth);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    final Finder loginLink = find.text('Log in');
    await tester.ensureVisible(loginLink);
    await tester.pumpAndSettle();
    await tester.tap(loginLink);
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
