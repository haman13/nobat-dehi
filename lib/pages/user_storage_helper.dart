// ignore_for_file: unused_field

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DummyUser {
  final String phoneNumber;
  final String password;
  final String fullName;

  DummyUser({
    required this.phoneNumber,
    required this.password,
    required this.fullName,
  });

  // تبدیل به Map برای ذخیره در حافظه
  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'password': password,
      'fullName': fullName,
    };
  }

  // ساخت از Map
  factory DummyUser.fromMap(Map<String, dynamic> map) {
    return DummyUser(
      phoneNumber: map['phoneNumber'],
      password: map['password'],
      fullName: map['fullName'],
    );
  }

  static Future<List<DummyUser>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList('users') ?? [];
    return usersJson
        .map((userJson) => DummyUser.fromMap(Map<String, dynamic>.from(
            Map<String, dynamic>.from(json.decode(userJson)))))
        .toList();
  }

  static Future<bool> isPhoneNumberTaken(String phoneNumber) async {
    final users = await getAllUsers();
    return users.any((user) => user.phoneNumber == phoneNumber);
  }

  static Future<DummyUser?> findUserByPhoneNumberAndPassword(String phoneNumber, String password) async {
    final users = await getAllUsers();
    try {
      return users.firstWhere(
        (user) => user.phoneNumber == phoneNumber && user.password == password,
      );
    } catch (e) {
      return null;
    }
  }
}

class UserStorageHelper {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'currentUser';

  // ذخیره‌ی کاربر جدید
  static Future<void> saveUser(DummyUser user) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> usersJson = prefs.getStringList(_usersKey) ?? [];

    // اضافه کردن کاربر جدید
    usersJson.add(jsonEncode(user.toMap()));
    await prefs.setStringList(_usersKey, usersJson);

    // ذخیره اطلاعات کاربر فعلی
    await prefs.setString('phone', user.phoneNumber);
    await prefs.setString('fullname', user.fullName);
    await prefs.setString('password', user.password);
  }

  // خواندن همه‌ی کاربران
  static Future<List<DummyUser>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> usersJson = prefs.getStringList(_usersKey) ?? [];

    return usersJson.map((userJson) {
      final Map<String, dynamic> userMap = jsonDecode(userJson);
      return DummyUser.fromMap(userMap);
    }).toList();
  }

  // چک کردن وجود شماره موبایل
  static Future<bool> isPhoneNumberTaken(String phoneNumber) async {
    final users = await getAllUsers();
    return users.any((user) => user.phoneNumber == phoneNumber);
  }

  // پیدا کردن کاربر بر اساس شماره موبایل و پسورد
  static Future<DummyUser?> findUserByPhoneNumberAndPassword(String phoneNumber, String password) async {
    final users = await getAllUsers();
    for (var user in users) {
      if (user.phoneNumber == phoneNumber && user.password == password) {
        // ذخیره اطلاعات کاربر فعلی
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('phone', user.phoneNumber);
        await prefs.setString('fullname', user.fullName);
        await prefs.setString('password', user.password);
        return user;
      }
    }
    return null;
  }

  // خروج کاربر
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('phone');
    await prefs.remove('fullname');
    await prefs.remove('password');
  }

  // به‌روزرسانی اطلاعات کاربر
  static Future<void> updateUser(String oldPhoneNumber, DummyUser updatedUser) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> usersJson = prefs.getStringList(_usersKey) ?? [];
    
    // حذف کاربر قدیمی
    usersJson.removeWhere((userJson) {
      final user = DummyUser.fromMap(jsonDecode(userJson));
      return user.phoneNumber == oldPhoneNumber;
    });
    
    // اضافه کردن کاربر جدید
    usersJson.add(jsonEncode(updatedUser.toMap()));
    await prefs.setStringList(_usersKey, usersJson);

    // به‌روزرسانی اطلاعات کاربر فعلی
    await prefs.setString('phone', updatedUser.phoneNumber);
    await prefs.setString('fullname', updatedUser.fullName);
    await prefs.setString('password', updatedUser.password);
  }
}
