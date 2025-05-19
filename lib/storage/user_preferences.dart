import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const _keyName = 'name';
  static const _keyFamily = 'family';
  static const _keyPhone = 'phone';
  static const _keyPassword = 'password';
  static const _keyIsLoggedIn = 'is_logged_in';

  // ذخیره اطلاعات کاربر
  static Future<void> saveUser({
    required String name,
    required String family,
    required String phone,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyFamily, family);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyPassword, password);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  // گرفتن اطلاعات برای نمایش در پروفایل
  static Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyName),
      'family': prefs.getString(_keyFamily),
      'phone': prefs.getString(_keyPhone),
    };
  }

  // بررسی ورود کاربر
  static Future<bool> login({
    required String phone,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString(_keyPhone);
    final savedPassword = prefs.getString(_keyPassword);

    if (savedPhone == phone && savedPassword == password) {
      await prefs.setBool(_keyIsLoggedIn, true);
      return true;
    }
    return false;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
  }
}
