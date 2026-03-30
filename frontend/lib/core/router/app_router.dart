import 'package:flutter/material.dart';
import 'package:frontend/features/auth/presentation/login_page.dart';
import 'package:frontend/features/auth/presentation/signup_page.dart';

class AppRouter {
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      case signupRoute:
        return MaterialPageRoute<void>(
          builder: (_) => const SignupPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginPage(),
          settings: const RouteSettings(name: loginRoute),
        );
    }
  }
}
