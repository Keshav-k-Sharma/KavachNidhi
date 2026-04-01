import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/auth/auth_controller.dart';
import 'package:frontend/features/auth/presentation/login_page.dart';
import 'package:frontend/features/auth/presentation/otp_verification_page.dart';
import 'package:frontend/features/auth/presentation/signup_page.dart';
import 'package:frontend/features/home/presentation/main_shell_page.dart';

class AppRouter {
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
  static const String otpRoute = '/otp';

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
      case otpRoute:
        final Object? args = settings.arguments;
        final String digits = args is String ? args : '';
        return MaterialPageRoute<void>(
          builder: (_) => OtpVerificationPage(phoneDigits: digits),
          settings: settings,
        );
      case homeRoute:
        return MaterialPageRoute<void>(
          builder: (BuildContext context) => Consumer<AuthController>(
            builder: (BuildContext context, AuthController auth, _) {
              if (!auth.isAuthenticated) {
                return const LoginPage();
              }
              return MainShellPage.route();
            },
          ),
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
