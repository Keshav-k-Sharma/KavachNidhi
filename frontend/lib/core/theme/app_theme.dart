import 'package:flutter/material.dart';

class AppTheme {
  static const Color _background = Color(0xFF0E0E0E);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _surfaceAlt = Color(0xFF262626);
  static const Color _primary = Color(0xFF89ACFF);
  static const Color _primaryDim = Color(0xFF0F6DF3);
  static const Color _secondary = Color(0xFFFEB300);
  static const Color _success = Color(0xFFB5FFC2);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFFADAAAA);

  static ThemeData darkTheme() {
    const colorScheme = ColorScheme.dark(
      primary: _primary,
      secondary: _secondary,
      surface: _surface,
      onPrimary: Color(0xFF002053),
      onSecondary: Color(0xFF523700),
      onSurface: _textPrimary,
      onSurfaceVariant: _textMuted,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _background,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.25),
        ),
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: _textPrimary,
        displayColor: _textPrimary,
      ),
      cardTheme: CardThemeData(
        color: _surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        KavachColors(
          success: _success,
          textMuted: _textMuted,
          primaryDim: _primaryDim,
        ),
      ],
    );
  }
}

@immutable
class KavachColors extends ThemeExtension<KavachColors> {
  const KavachColors({
    required this.success,
    required this.textMuted,
    required this.primaryDim,
  });

  final Color success;
  final Color textMuted;
  final Color primaryDim;

  @override
  KavachColors copyWith({Color? success, Color? textMuted, Color? primaryDim}) {
    return KavachColors(
      success: success ?? this.success,
      textMuted: textMuted ?? this.textMuted,
      primaryDim: primaryDim ?? this.primaryDim,
    );
  }

  @override
  KavachColors lerp(ThemeExtension<KavachColors>? other, double t) {
    if (other is! KavachColors) {
      return this;
    }

    return KavachColors(
      success: Color.lerp(success, other.success, t) ?? success,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      primaryDim: Color.lerp(primaryDim, other.primaryDim, t) ?? primaryDim,
    );
  }
}
