import 'package:flutter/material.dart';
import 'package:frontend/features/home/presentation/home_dashboard_page.dart';
import 'package:frontend/features/auth/presentation/login_page.dart';
import 'package:frontend/features/auth/presentation/signup_page.dart';

class AppRouter {
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
  static const bool _enableDashboardDemo = true;

  static bool get canShowDashboard => _enableDashboardDemo;

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
      case homeRoute:
        return MaterialPageRoute<void>(
          builder: (_) =>
              canShowDashboard ? HomeDashboardPage.route() : const LoginPage(),
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
