// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/main_screen.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/animated_button.dart';
import 'sign_up_page.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/utils/custom_page_route.dart';
import 'package:flutter_application_1/utils/supabase_user_service.dart';
import 'package:flutter_application_1/pages/blocked_user_page.dart';
import 'package:flutter_application_1/utils/responsive_helper.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final enteredPhone = _phoneController.text.trim();
      final enteredPassword = _passwordController.text;

      if (enteredPhone.isEmpty || enteredPassword.isEmpty) {
        _showErrorDialog('لطفاً تمام فیلدها را پر کنید.');
        return;
      }

      // ورود کاربران از دیتابیس Supabase
      final user = await SupabaseUserService.getUserByPhone(enteredPhone);
      if (user != null && user['password'] == enteredPassword) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fullname', user['full_name']);
        await prefs.setString('phone', user['phone']);
        await prefs.setString('password', user['password']);

        if (!mounted) return;

        // بررسی مسدود بودن کاربر
        if (user['is_blocked'] == true) {
          // هدایت به صفحه کاربران مسدود
          Navigator.pushReplacement(
            context,
            CustomPageRoute(
              page: BlockedUserPage(
                fullName: user['full_name'],
                phone: user['phone'],
                blockedReason: user['blocked_reason'],
                blockedAt: user['blocked_at'],
              ),
              settings: const RouteSettings(name: '/blocked'),
            ),
          );
        } else {
          // ورود عادی به صفحه اصلی
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
        }
      } else {
        if (!mounted) return;
        _showErrorDialog('شماره موبایل یا رمز عبور اشتباه است.');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AppTheme.buildModernDialog(
        title: 'خطا',
        content: message,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: AppTheme.textButtonStyle,
            child: const Text('باشه'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return ResponsiveHelper.wrapWithDesktopConstraint(
      context,
      Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AnimatedBuilder(
                  animation:
                      Listenable.merge([_fadeAnimation, _slideAnimation]),
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildContent(isTablet),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isTablet) {
    final maxWidth = isTablet ? 500.0 : double.infinity;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHeader(),
          const SizedBox(height: 48),
          _buildLoginCard(),
          const SizedBox(height: 24),
          _buildSignUpSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) {
            AppTheme.handleAdminTap(context);
          },
          child: Hero(
            tag: 'app_logo',
            child: AppTheme.getLogo(size: 120),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'به سالن زیبایی',
          style: AppTheme.titleStyle.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'خوش آمدید 💅🏻',
          style: AppTheme.titleStyle.copyWith(
            fontSize: 28,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'برای ادامه وارد حساب کاربری خود شوید',
          style: AppTheme.captionStyle.copyWith(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      decoration: AppTheme.modernCardDecoration,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPhoneField(),
          const SizedBox(height: 20),
          _buildPasswordField(),
          const SizedBox(height: 32),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'شماره موبایل',
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          maxLength: 11,
          decoration: AppTheme.modernTextFieldDecoration.copyWith(
            hintText: '09xxxxxxxxx',
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLightColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.phone,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'رمز عبور',
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          onSubmitted: (_) => _login(),
          decoration: AppTheme.modernTextFieldDecoration.copyWith(
            hintText: 'رمز عبور خود را وارد کنید',
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLightColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lock,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.textSecondaryColor,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return AnimatedButton(
      onPressed: _login,
      isLoading: _isLoading,
      useGradient: true,
      gradient: AppTheme.primaryGradient,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.login, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'ورود',
            style: AppTheme.buttonTextStyle.copyWith(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryLightColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Text(
            'حساب کاربری ندارید؟',
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedButton(
            onPressed: () {
              Navigator.push(
                context,
                CustomPageRoute(
                  page: const SignUpPage(),
                  settings: const RouteSettings(name: '/signup'),
                ),
              );
            },
            style: AppTheme.secondaryButtonStyle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add),
                const SizedBox(width: 8),
                Text(
                  'ایجاد حساب کاربری',
                  style: AppTheme.buttonTextStyle.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
