import 'package:flutter/material.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/core/theme/app_theme.dart';

class KavachNidhiApp extends StatelessWidget {
  const KavachNidhiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KavachNidhi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      initialRoute: AppRouter.loginRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
