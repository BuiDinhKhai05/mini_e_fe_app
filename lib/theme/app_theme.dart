import 'package:flutter/material.dart';

/// File quản lý format giao diện chung cho toàn app.
/// Các màn hình nên dùng màu, text style, radius, shadow từ file này
/// để giao diện đồng bộ và dễ chỉnh sửa sau này.

class AppColors {
  AppColors._();

  // Màu chính của app
  static const Color primaryPink = Color(0xFFFF5C8A);
  static const Color darkPink = Color(0xFFE84D7A);
  static const Color lightPink = Color(0xFFFFEEF4);
  static const Color softPink = Color(0xFFFFF8FA);

  // Background
  static const Color background = Color(0xFFFFF8FA);
  static const Color cardBackground = Colors.white;

  // Text
  static const Color textDark = Color(0xFF2D2D2D);
  static const Color textGrey = Color(0xFF777777);
  static const Color textLight = Color(0xFF999999);

  // Border
  static const Color borderPink = Color(0xFFFFD6E2);
  static const Color borderGrey = Color(0xFFEAEAEA);

  // Status
  static const Color success = Color(0xFF2EAD4A);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
}

class AppRadius {
  AppRadius._();

  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 22;
  static const double circle = 999;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
  );

  static const TextStyle bodyGrey = TextStyle(
    fontSize: 14,
    color: AppColors.textGrey,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle price = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryPink,
  );
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];
}

class AppDecorations {
  AppDecorations._();

  static BoxDecoration card = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(AppRadius.large),
    boxShadow: AppShadows.cardShadow,
  );

  static BoxDecoration pinkCard = BoxDecoration(
    color: AppColors.softPink,
    borderRadius: BorderRadius.circular(AppRadius.large),
    border: Border.all(color: AppColors.borderPink),
  );

  static BoxDecoration input = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppRadius.medium),
    border: Border.all(color: AppColors.borderGrey),
  );

  static BoxDecoration pinkBadge = BoxDecoration(
    color: AppColors.lightPink,
    borderRadius: BorderRadius.circular(AppRadius.circle),
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primaryPink,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryPink,
      primary: AppColors.primaryPink,
      secondary: AppColors.darkPink,
      background: AppColors.background,
      error: AppColors.error,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.titleMedium,
      iconTheme: IconThemeData(
        color: AppColors.textDark,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryPink,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        textStyle: AppTextStyles.button,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(
          color: AppColors.primaryPink,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1.4,
        ),
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryPink,
      unselectedItemColor: AppColors.textLight,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryPink,
      foregroundColor: Colors.white,
    ),
  );
}