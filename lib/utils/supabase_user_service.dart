import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseUserService {
  static final supabase = Supabase.instance.client;

  static Future<void> signUp({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    try {
      // بررسی وجود کاربر با این شماره تماس
      final existingUser = await supabase
          .from('users')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('این شماره تماس قبلاً ثبت شده است');
      }

      // ایجاد کاربر جدید
      await supabase.from('users').insert({
        'full_name': fullName,
        'phone': phone,
        'password': password, // در حالت واقعی باید رمز عبور را هش کنیم
      });
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception(e.message);
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      final response = await supabase
          .from('users')
          .select(
              'full_name, phone, password, is_blocked, blocked_at, blocked_reason')
          .eq('phone', phone)
          .single();
      return response;
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        return null; // کاربر یافت نشد
      }
      rethrow;
    }
  }

  static Future<bool> isUserBlocked(String phone) async {
    try {
      final user = await getUserByPhone(phone);
      if (user == null) return false;

      return user['is_blocked'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> login(String phone, String password) async {
    try {
      final user = await getUserByPhone(phone);
      if (user == null) return false;

      return user['password'] == password;
    } catch (e) {
      return false;
    }
  }
}
