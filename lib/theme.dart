import 'package:flutter/material.dart';


class AppTheme {
  // رنگ‌های اصلی برنامه
  static const Color primaryColor = Colors.pinkAccent;
  static const Color primaryDarkColor = Color(0xFFE91E63); // pink[800]
  static const Color primaryLightColor = Color(0xFFFCE4EC); // pink[50]
  static const Color primaryLightColor2 = Color(0xFFF8BBD0); // pink[100]
  static const Color primaryLightColor3 = Color.fromARGB(255, 165, 213, 241); // pink[100]
  
  // رنگ‌های متن
  static const Color textPrimaryColor = Color(0xFFE91E63); // pink[800]
  static const Color textOnPrimaryColor = Colors.white;
  
  // رنگ‌های پس‌زمینه
  static const Color backgroundColor = Color(0xFFFCE4EC); // pink[50]
  static const Color surfaceColor = Colors.white;
  
  // رنگ‌های وضعیت
  static const Color statusPendingColor = Colors.orange;
  static const Color statusConfirmedColor = Colors.green;
  static const Color statusCancelledColor = Colors.red;
  static const Color statusDefaultColor = Colors.grey;

  // استایل‌های متنی
  static const TextStyle titleStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textPrimaryColor,
  );

  // ویجت لوگو
  static Widget getLogo({double size = 50}) {
    return SizedBox(
      width: size,
      height: size,
      // 
      child: Center(
        //
        child: Image.asset(
          'assets/images/logo1.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // استایل دکمه‌ها
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  static ButtonStyle secondaryButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
  );

  // استایل کارت‌ها
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: primaryColor, width: 1.5),
  );

  // استایل فیلدهای ورودی
  static InputDecoration textFieldDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    fillColor: surfaceColor,
    filled: true,
  );

  // متدهای مربوط به ورود ادمین
  static int _adminTapCount = 0;
  static const int _requiredTaps = 2;
  static const Duration _resetDuration = Duration(seconds: 3);

  static void handleAdminTap(BuildContext context) {
    _adminTapCount++;
    
    if (_adminTapCount >= _requiredTaps) {
      _adminTapCount = 0;
      _showAdminLoginDialog(context);
    } else {
      Future.delayed(_resetDuration, () {
        _adminTapCount = 0;
      });
    }
  }

  static void _showAdminLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ورود به پنل ادمین'),
        content: const Text('در حال ورود به پنل ادمین...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (context.mounted) {
        Navigator.pop(context); // بستن دیالوگ
        Navigator.pushNamed(context, '/admin/login');
      }
    });
  }
}
// تغییر نام کاربری و رمز عبور ادمین
class AdminCredentials {
  // مقادیر ثابت برای نام کاربری و رمز عبور ادمین
  static const String defaultUsername = 'a';
  static const String defaultPassword = 'a';

  static Future<String> get username async {
    return defaultUsername;
  }

  static Future<String> get password async {
    return defaultPassword;
  }
}

// کاربر هاردکد برای ورود سریع
class HardcodedUser {
  static const String phone = '09123456789';
  static const String password = '123456';
  static const String fullName = 'کاربر ادمین';
  
} 