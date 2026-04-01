import 'package:flutter/material.dart';

class AppTheme {
  // Stitch Design System Colors
  static const Color _surface = Color(0xFF0E0E0E);
  static const Color _surfaceContainer = Color(0xFF1A1A1A);
  static const Color _surfaceContainerLow = Color(0xFF131313);
  static const Color _surfaceContainerLowest = Color(0xFF000000);
  static const Color _surfaceContainerHigh = Color(0xFF20201F);
  static const Color _surfaceContainerHighest = Color(0xFF262626);
  static const Color _surfaceBright = Color(0xFF2C2C2C);
  static const Color _surfaceDim = Color(0xFF0E0E0E);
  
  static const Color _primary = Color(0xFF89ACFF);
  static const Color _primaryContainer = Color(0xFF739EFF);
  static const Color _primaryDim = Color(0xFF0F6DF3);
  static const Color _primaryFixed = Color(0xFF739EFF);
  static const Color _primaryFixedDim = Color(0xFF5A90FF);
  
  static const Color _secondary = Color(0xFFFEB300);
  static const Color _secondaryContainer = Color(0xFF7E5700);
  static const Color _secondaryDim = Color(0xFFEDA600);
  static const Color _secondaryFixed = Color(0xFFFFC96F);
  static const Color _secondaryFixedDim = Color(0xFFFFB623);
  
  static const Color _tertiary = Color(0xFFB5FFC2);
  static const Color _tertiaryContainer = Color(0xFF3FFF8B);
  static const Color _tertiaryDim = Color(0xFF24F07E);
  static const Color _tertiaryFixed = Color(0xFF3FFF8B);
  static const Color _tertiaryFixedDim = Color(0xFF24F07E);
  
  static const Color _onSurface = Color(0xFFFFFFFF);
  static const Color _onSurfaceVariant = Color(0xFFADAAAA);
  static const Color _onPrimary = Color(0xFF002B6A);
  static const Color _onPrimaryContainer = Color(0xFF002053);
  static const Color _onSecondary = Color(0xFF523700);
  static const Color _onSecondaryContainer = Color(0xFFFFF6EE);
  static const Color _onTertiary = Color(0xFF006731);
  static const Color _onTertiaryContainer = Color(0xFF005D2C);
  
  static const Color _outline = Color(0xFF767575);
  static const Color _outlineVariant = Color(0xFF484847);
  
  static const Color _error = Color(0xFFFF716C);
  static const Color _errorContainer = Color(0xFF9F0519);
  static const Color _errorDim = Color(0xFFD7383B);
  static const Color _onError = Color(0xFF490006);
  static const Color _onErrorContainer = Color(0xFFFFA8A3);

  static ThemeData darkTheme() {
    const colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: _primary,
      onPrimary: _onPrimary,
      primaryContainer: _primaryContainer,
      onPrimaryContainer: _onPrimaryContainer,
      primaryFixed: _primaryFixed,
      primaryFixedDim: _primaryFixedDim,
      onPrimaryFixed: Color(0xFF000000),
      onPrimaryFixedVariant: Color(0xFF002966),
      
      secondary: _secondary,
      onSecondary: _onSecondary,
      secondaryContainer: _secondaryContainer,
      onSecondaryContainer: _onSecondaryContainer,
      secondaryFixed: _secondaryFixed,
      secondaryFixedDim: _secondaryFixedDim,
      onSecondaryFixed: Color(0xFF483000),
      onSecondaryFixedVariant: Color(0xFF6C4A00),
      
      tertiary: _tertiary,
      onTertiary: _onTertiary,
      tertiaryContainer: _tertiaryContainer,
      onTertiaryContainer: _onTertiaryContainer,
      tertiaryFixed: _tertiaryFixed,
      tertiaryFixedDim: _tertiaryFixedDim,
      onTertiaryFixed: Color(0xFF004820),
      onTertiaryFixedVariant: Color(0xFF006832),
      
      error: _error,
      onError: _onError,
      errorContainer: _errorContainer,
      onErrorContainer: _onErrorContainer,
      
      surface: _surface,
      onSurface: _onSurface,
      surfaceContainerHighest: _surfaceContainerHighest,
      surfaceContainerHigh: _surfaceContainerHigh,
      surfaceContainer: _surfaceContainer,
      surfaceContainerLow: _surfaceContainerLow,
      surfaceContainerLowest: _surfaceContainerLowest,
      surfaceBright: _surfaceBright,
      surfaceDim: _surfaceDim,
      
      outline: _outline,
      outlineVariant: _outlineVariant,
      
      inverseSurface: Color(0xFFFCF9F8),
      onInverseSurface: Color(0xFF565555),
      inversePrimary: Color(0xFF0059CB),
      
      surfaceTint: _primary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _surface,
      fontFamily: 'Inter',
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );

    // Custom text theme following Stitch editorial hierarchy
    final textTheme = base.textTheme.copyWith(
      // Display styles for large numbers/balances
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02,
        height: 1.1,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w800,
        letterSpacing: -0.01,
        height: 1.15,
      ),
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.2,
      ),
      
      // Headlines for section titles
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        letterSpacing: -0.01,
        height: 1.2,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.25,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.3,
      ),
      
      // Titles for card headers and sub-sections
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.3,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      
      // Body text for descriptions and content
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.4,
      ),
      
      // Labels for technical data and micro-content
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontFamily: 'Public Sans',
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.3,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontFamily: 'Public Sans',
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.3,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontFamily: 'Public Sans',
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        height: 1.2,
      ),
    );

    return base.copyWith(
      textTheme: textTheme.apply(
        bodyColor: _onSurface,
        displayColor: _onSurface,
      ),
      cardTheme: CardThemeData(
        color: _surfaceContainer,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        KavachColors(
          success: _tertiary,
          textMuted: _onSurfaceVariant,
          primaryDim: _primaryDim,
          surfaceContainer: _surfaceContainer,
          surfaceContainerLow: _surfaceContainerLow,
          surfaceContainerLowest: _surfaceContainerLowest,
          surfaceContainerHigh: _surfaceContainerHigh,
          surfaceContainerHighest: _surfaceContainerHighest,
          secondaryDim: _secondaryDim,
          tertiaryDim: _tertiaryDim,
          errorDim: _errorDim,
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
    required this.surfaceContainer,
    required this.surfaceContainerLow,
    required this.surfaceContainerLowest,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.secondaryDim,
    required this.tertiaryDim,
    required this.errorDim,
  });

  final Color success;
  final Color textMuted;
  final Color primaryDim;
  final Color surfaceContainer;
  final Color surfaceContainerLow;
  final Color surfaceContainerLowest;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color secondaryDim;
  final Color tertiaryDim;
  final Color errorDim;

  @override
  KavachColors copyWith({
    Color? success,
    Color? textMuted,
    Color? primaryDim,
    Color? surfaceContainer,
    Color? surfaceContainerLow,
    Color? surfaceContainerLowest,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? secondaryDim,
    Color? tertiaryDim,
    Color? errorDim,
  }) {
    return KavachColors(
      success: success ?? this.success,
      textMuted: textMuted ?? this.textMuted,
      primaryDim: primaryDim ?? this.primaryDim,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainerLowest: surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest ?? this.surfaceContainerHighest,
      secondaryDim: secondaryDim ?? this.secondaryDim,
      tertiaryDim: tertiaryDim ?? this.tertiaryDim,
      errorDim: errorDim ?? this.errorDim,
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
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t) ?? surfaceContainer,
      surfaceContainerLow: Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t) ?? surfaceContainerLow,
      surfaceContainerLowest: Color.lerp(surfaceContainerLowest, other.surfaceContainerLowest, t) ?? surfaceContainerLowest,
      surfaceContainerHigh: Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t) ?? surfaceContainerHigh,
      surfaceContainerHighest: Color.lerp(surfaceContainerHighest, other.surfaceContainerHighest, t) ?? surfaceContainerHighest,
      secondaryDim: Color.lerp(secondaryDim, other.secondaryDim, t) ?? secondaryDim,
      tertiaryDim: Color.lerp(tertiaryDim, other.tertiaryDim, t) ?? tertiaryDim,
      errorDim: Color.lerp(errorDim, other.errorDim, t) ?? errorDim,
    );
  }
}
