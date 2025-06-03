// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/animated_button.dart';
import 'package:flutter_application_1/utils/supabase_user_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final name = nameController.text.trim();
      final phone = phoneController.text.trim();
      final password = passwordController.text;
      final confirmPassword = confirmPasswordController.text;

      if (name.isEmpty ||
          phone.isEmpty ||
          password.isEmpty ||
          confirmPassword.isEmpty) {
        _showErrorDialog('لطفاً تمام فیلدها را پر کنید.');
        return;
      }

      if (phone.length != 11 ||
          !phone.startsWith('09') ||
          !RegExp(r'^\d{11}$').hasMatch(phone)) {
        _showErrorDialog('شماره موبایل باید فقط شامل عدد باشد، با 09 شروع شود و 11 رقم باشد.');
        return;
      }

      if (password != confirmPassword) {
        _showErrorDialog('رمز عبور و تکرار آن یکسان نیستند.');
        return;
      }

      // ثبت نام در Supabase
      await SupabaseUserService.signUp(
        fullName: name,
        phone: phone,
        password: password,
      );

      // ذخیره اطلاعات کاربر فعلی
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fullname', name);
      await prefs.setString('phone', phone);
      await prefs.setString('password', password);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خطا'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('موفقیت'),
        content: const Text('ثبت‌نام با موفقیت انجام شد!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // بستن دیالوگ
              Navigator.pop(context); // برگشت به صفحه قبلی فقط در صورت موفقیت
            },
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final boxWidth = width > 600 ? width * 0.4 : width * 0.85;

    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: Colors.pink[300],
        title: const Text('ثبت‌نام'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(
                width: boxWidth,
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'نام و نام خانوادگی',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: boxWidth,
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  maxLength: 11,
                  decoration: InputDecoration(
                    labelText: 'شماره موبایل',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.phone),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                    hintText: '09xxxxxxxxx',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: boxWidth,
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'رمز عبور',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: boxWidth,
                child: TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'تکرار رمز عبور',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: boxWidth,
                child: AnimatedButton(
                  onPressed: _isLoading ? () {} : () => _signUp(),
                  style: AppTheme.primaryButtonStyle,
                  isLoading: _isLoading,
                  child: const Text('ثبت نام'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: AppTheme.secondaryButtonStyle,
                child: const Text('بازگشت به صفحه ورود'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
