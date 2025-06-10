import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/services_list_page.dart';
import 'package:flutter_application_1/pages/reservations_page.dart';
import 'package:flutter_application_1/pages/user_profile_page.dart';
import 'package:flutter_application_1/pages/welcome_page.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/utils/custom_page_transition.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  final bool isLoggedIn;
  final int initialIndex;

  const MainScreen({Key? key, required this.isLoggedIn, this.initialIndex = 0})
      : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  String _phoneNumber = '';
  String reservationMobile = '';
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    _loadUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      // ابتدا از SharedPreferences تلاش کن
      final prefs = await SharedPreferences.getInstance();
      final phoneFromPrefs = prefs.getString('phone');

      if (phoneFromPrefs != null && phoneFromPrefs.isNotEmpty) {
        setState(() {
          _phoneNumber = phoneFromPrefs;
          reservationMobile = phoneFromPrefs;
        });
        print('📱 MainScreen شماره از SharedPreferences: $phoneFromPrefs');
        return;
      }

      // اگر در SharedPreferences نبود، از Supabase تلاش کن
      final user = SupabaseConfig.client.auth.currentUser;
      print('MainScreen currentUser: $user');
      if (user == null) {
        throw Exception('کاربر وارد نشده است');
      }

      final userData = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      print('MainScreen userData: $userData');
      setState(() {
        _phoneNumber = userData['phone'] ?? 'نامشخص';
        reservationMobile = userData['phone'] ?? 'نامشخص';
      });
      print('MainScreen _phoneNumber after setState: $_phoneNumber');
    } catch (e) {
      print('خطا در دریافت اطلاعات کاربر: $e');
    }
  }

  void _onPageChanged(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex != index) {
      _pageController.jumpToPage(index);
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      await SupabaseConfig.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        CustomPageTransition(
          page: const WelcomePage(),
          settings: const RouteSettings(name: '/login'),
        ),
      );
    } catch (e) {
      print('خطا در خروج از حساب کاربری: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          const ServicesListPage(isLoggedIn: true),
          const ReservationsPage(),
          UserProfilePage(
            phoneNumber: _phoneNumber,
            onLogout: _handleLogout,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryLightColor.withOpacity(1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavButton(
                  icon: Icons.spa,
                  label: 'خدمات',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onNavItemTapped(0),
                ),
                _buildNavButton(
                  icon: Icons.list_alt,
                  label: 'رزروهای من',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onNavItemTapped(1),
                ),
                _buildNavButton(
                  icon: Icons.person,
                  label: 'پروفایل',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onNavItemTapped(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
