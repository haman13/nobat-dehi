import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/main_screen.dart';
import 'pages/welcome_page.dart';
import 'pages/admin/admin_login_page.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_application_1/theme.dart';
import 'utils/supabase_config.dart';
import 'pages/reservation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fa_IR', null);
  await SupabaseConfig.initialize();
  runApp(const SalonApp());
}

class SalonApp extends StatelessWidget {
  const SalonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نوبت دهی سالن زیبایی',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const WelcomePage(),
        '/main': (context) => const MainScreen(isLoggedIn: true),
        '/admin/login': (context) => const AdminLoginPage(),
        '/admin/dashboard': (context) => const AdminDashboardPage(),
        '/reservation': (context) => const ReservationPage(),
      },
      theme: _buildAppTheme(),
      home: const WelcomePage(),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      useMaterial3: true,

      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primaryColor,
        brightness: Brightness.light,
        primary: AppTheme.primaryColor,
        secondary: AppTheme.accentColor,
        surface: AppTheme.surfaceColor,
        background: AppTheme.backgroundColor,
        error: AppTheme.statusCancelledColor,
      ),

      // Primary colors
      primaryColor: AppTheme.primaryColor,
      scaffoldBackgroundColor: AppTheme.backgroundColor,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTheme.titleStyle.copyWith(
          color: Colors.white,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: AppTheme.cardBackgroundColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppTheme.primaryButtonStyle,
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppTheme.secondaryButtonStyle,
      ),

      textButtonTheme: TextButtonThemeData(
        style: AppTheme.textButtonStyle,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: AppTheme.textHintColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: AppTheme.textHintColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppTheme.statusCancelledColor, width: 2),
        ),
        fillColor: AppTheme.surfaceColor,
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(
          color: AppTheme.textHintColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppTheme.textSecondaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: AppTheme.titleStyle,
        displayMedium: AppTheme.subtitleStyle,
        headlineLarge: AppTheme.titleStyle.copyWith(fontSize: 32),
        headlineMedium: AppTheme.titleStyle.copyWith(fontSize: 28),
        headlineSmall: AppTheme.subtitleStyle,
        titleLarge: AppTheme.subtitleStyle,
        titleMedium: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600),
        titleSmall: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w500),
        bodyLarge: AppTheme.bodyStyle,
        bodyMedium: AppTheme.bodyStyle.copyWith(fontSize: 14),
        bodySmall: AppTheme.captionStyle,
        labelLarge: AppTheme.buttonTextStyle,
        labelMedium:
            AppTheme.captionStyle.copyWith(fontWeight: FontWeight.w500),
        labelSmall: AppTheme.captionStyle.copyWith(fontSize: 12),
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTheme.subtitleStyle,
        contentTextStyle: AppTheme.bodyStyle,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTheme.textPrimaryColor,
        contentTextStyle: AppTheme.bodyStyle.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppTheme.primaryColor,
        linearTrackColor: AppTheme.primaryLightColor,
        circularTrackColor: AppTheme.primaryLightColor,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: AppTheme.textSecondaryColor,
        size: 24,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: AppTheme.textHintColor.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle:
            AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: AppTheme.captionStyle,
      ),

      // Navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Additional visual properties
      splashColor: AppTheme.primaryColor.withOpacity(0.1),
      highlightColor: AppTheme.primaryColor.withOpacity(0.05),
      hoverColor: AppTheme.primaryColor.withOpacity(0.03),
      focusColor: AppTheme.primaryColor.withOpacity(0.1),
    );
  }
}
