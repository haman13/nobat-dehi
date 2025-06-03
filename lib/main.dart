import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/main_screen.dart';
import 'pages/welcome_page.dart';
import 'pages/admin/admin_login_page.dart';
import 'pages/admin/admin_dashboard_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_application_1/theme.dart';
import 'utils/supabase_config.dart';
import 'pages/services_page.dart';
import 'pages/reservation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fa', null);
  await SupabaseConfig.initialize();
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
        '/reservation': (context) => const ReservationPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/services') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ServicesPage(selectedDate: args['date']),
          );
        }
        return null;
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
