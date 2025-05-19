// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/main_screen.dart';
import 'package:flutter_application_1/pages/user_management.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/animated_button.dart';
import 'sign_up_page.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/utils/custom_page_route.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  int tapCount = 0;

  @override
  Widget build(BuildContext context) {
    Future<void> _login() async {
      if (_isLoading) return;

      setState(() {
        _isLoading = true;
      });

      try {
        final enteredPhone = _phoneController.text.trim();
        final enteredPassword = _passwordController.text;

        if (enteredPhone.isEmpty || enteredPassword.isEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('خطا'),
              content: const Text('لطفاً تمام فیلدها را پر کنید.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('باشه'),
                ),
              ],
            ),
          );
          return;
        }

        final user = await UserManagement.getUserByPhone(enteredPhone);

        // ورود سریع با کاربر هاردکد
        if (enteredPhone == HardcodedUser.phone && enteredPassword == HardcodedUser.password) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fullname', HardcodedUser.fullName);
          await prefs.setString('phone', HardcodedUser.phone);
          await prefs.setString('password', HardcodedUser.password);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            CustomPageRoute(
              page: const MainScreen(
                isLoggedIn: true,
                initialIndex: 0,
              ),
              settings: const RouteSettings(name: '/main'),
            ),
          );
          return;
        }

        if (user != null && user['password'] == enteredPassword) {
          // ذخیره اطلاعات کاربر فعلی
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fullname', user['fullName']);
          await prefs.setString('phone', user['phone']);
          await prefs.setString('password', user['password']);

          if (!mounted) return;
          
          Navigator.pushReplacement(
            context,
            CustomPageRoute(
              page: const MainScreen(
                isLoggedIn: true,
                initialIndex: 0,
              ),
              settings: const RouteSettings(name: '/main'),
            ),
          );
        } else {
          if (!mounted) return;
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('خطا'),
              content: const Text('شماره موبایل یا رمز عبور اشتباه است.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('باشه'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خطا'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('باشه'),
              ),
            ],
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    final width = MediaQuery.of(context).size.width;
    final boxWidth = width > 600 ? width * 0.4 : width * 0.85;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTapDown: (_) {
                  AppTheme.handleAdminTap(context);
                },
                child: AppTheme.getLogo(size: 100),
              ),
              const SizedBox(height: 24),
              const Text(
                'به سالن زیبایی خوش آمدید 💅🏻',
                style: AppTheme.titleStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: boxWidth,
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  maxLength: 11,
                  decoration: AppTheme.textFieldDecoration.copyWith(
                    labelText: 'شماره موبایل',
                    prefixIcon: const Icon(Icons.phone),
                    counterText: '',
                    hintText: '09xxxxxxxxx',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: boxWidth,
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: AppTheme.textFieldDecoration.copyWith(
                    labelText: 'رمز عبور',
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: boxWidth,
                child: AnimatedButton(
                  onPressed: _isLoading ? () {} : () => _login(),
                  style: AppTheme.primaryButtonStyle,
                  isLoading: _isLoading,
                  child: const Text('ورود'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    CustomPageRoute(
                      page: const SignUpPage(),
                      settings: const RouteSettings(name: '/signup'),
                      isSlide: false,
                    ),
                  );
                },
                style: AppTheme.secondaryButtonStyle,
                child: const Text('ثبت نام'),
              ),
              const SizedBox(height: 12),
              
              
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
