import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/main_screen.dart';
import 'pages/welcome_page.dart';
import 'pages/admin/admin_login_page.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_application_1/theme.dart';

void main()async {
   WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fa', null); 
  runApp(const SalonApp());
}

class SalonApp extends StatelessWidget {
  const SalonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نوبت دهی',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const WelcomePage(),
        '/main': (context) => const MainScreen(isLoggedIn: true),
        '/admin/login': (context) => const AdminLoginPage(),
        '/admin/dashboard': (context) => const AdminDashboardPage(),
      },
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.primaryColor,
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppTheme.primaryButtonStyle,
        ),
        textTheme: const TextTheme(
          titleLarge: AppTheme.titleStyle,
          titleMedium: AppTheme.subtitleStyle,
          bodyLarge: AppTheme.bodyStyle,
        ),
      ),
      home: const WelcomePage(),
    );
  }
}
