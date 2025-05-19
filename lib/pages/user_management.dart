import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class User {
  final String fullName;
  final String phone;
  final String password;

  User({
    required this.fullName,
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'password': password,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      password: json['password'] as String,
    );
  }
}

class UserManagement {
  static Future<void> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // دریافت لیست فعلی کاربران
      List<String> usersJson = [];
      try {
        usersJson = prefs.getStringList('users') ?? [];
      } catch (e) {
        // اگر لیست وجود نداشت، یک لیست خالی ایجاد می‌کنیم
        usersJson = [];
      }
      
      // بررسی تکراری نبودن شماره تماس
      for (var json in usersJson) {
        try {
          final existingUser = User.fromJson(jsonDecode(json));
          if (existingUser.phone == user.phone) {
            throw Exception('این شماره تماس قبلاً ثبت شده است');
          }
        } catch (e) {
          // اگر در خواندن یک کاربر خطا رخ داد، آن را نادیده می‌گیریم
          continue;
        }
      }
      
      // تبدیل کاربر جدید به JSON
      final userJson = jsonEncode(user.toJson());
      
      // اضافه کردن به لیست
      usersJson.add(userJson);
      
      // ذخیره لیست جدید
      final success = await prefs.setStringList('users', usersJson);
      
      if (!success) {
        throw Exception('خطا در ذخیره اطلاعات در حافظه');
      }
    } catch (e) {
      throw Exception('خطا در ذخیره اطلاعات کاربر: ${e.toString()}');
    }
  }

  static Future<List<User>> getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('users') ?? [];
      
      return usersJson.map((json) {
        try {
          return User.fromJson(jsonDecode(json));
        } catch (e) {
          // اگر در خواندن یک کاربر خطا رخ داد، آن را نادیده می‌گیریم
          return null;
        }
      }).whereType<User>().toList();
    } catch (e) {
      throw Exception('خطا در دریافت لیست کاربران: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList('users') ?? [];
    
    for (final userJson in usersJson) {
      final user = jsonDecode(userJson) as Map<String, dynamic>;
      if (user['phone'] == phone) {
        return user;
      }
    }
    
    return null;
  }

  static Future<void> updateUser(String oldPhone, String newPhone, String fullName, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList('users') ?? [];
    
    for (int i = 0; i < usersJson.length; i++) {
      final user = jsonDecode(usersJson[i]) as Map<String, dynamic>;
      if (user['phone'] == oldPhone) {
        user['phone'] = newPhone;
        user['fullName'] = fullName;
        user['password'] = password;
        usersJson[i] = jsonEncode(user);
        break;
      }
    }
    
    await prefs.setStringList('users', usersJson);
  }

  static Future<void> createUser(String fullName, String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList('users') ?? [];
    
    final user = {
      'fullName': fullName,
      'phone': phone,
      'password': password,
    };
    
    usersJson.add(jsonEncode(user));
    await prefs.setStringList('users', usersJson);
  }

  static Future<bool> login(String phone, String password) async {
    final user = await getUserByPhone(phone);
    if (user == null) return false;
    
    return user['password'] == password;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('phone');
    await prefs.remove('fullname');
  }
} 