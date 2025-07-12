import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/services_list_page.dart';
import 'package:flutter_application_1/pages/reservations_page.dart';
import 'package:flutter_application_1/pages/user_profile_page.dart';
import 'package:flutter_application_1/pages/welcome_page.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/utils/custom_page_transition.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';
import 'package:flutter_application_1/utils/responsive_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  final bool isLoggedIn;
  final int initialIndex;

  const MainScreen({Key? key, required this.isLoggedIn, this.initialIndex = 0})
      : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late int _selectedIndex;
  String _phoneNumber = '';
  String reservationMobile = '';
  late PageController _pageController;
  late AnimationController _navAnimationController;
  late List<AnimationController> _iconControllers;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    _setupAnimations();
    _loadUserData();
  }

  void _setupAnimations() {
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _iconControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );

    // انیمیشن آیتم انتخاب شده
    if (_selectedIndex < _iconControllers.length) {
      _iconControllers[_selectedIndex].forward();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navAnimationController.dispose();
    for (var controller in _iconControllers) {
      controller.dispose();
    }
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
      if (mounted) {
        setState(() {
          _phoneNumber = userData['phone'] ?? 'نامشخص';
          reservationMobile = userData['phone'] ?? 'نامشخص';
        });
      }
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
      _updateIconAnimations(index);
    }
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex != index && mounted) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _selectedIndex = index;
      });
      _updateIconAnimations(index);
    }
  }

  void _updateIconAnimations(int selectedIndex) {
    for (int i = 0; i < _iconControllers.length; i++) {
      if (i == selectedIndex) {
        _iconControllers[i].forward();
      } else {
        _iconControllers[i].reverse();
      }
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
    return ResponsiveHelper.wrapWithDesktopConstraint(
      context,
      Scaffold(
        backgroundColor: AppTheme.backgroundColor,
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
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(0, -AppTheme.paddingSmall(context) * 0.25),
            blurRadius: AppTheme.paddingLarge(context),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: AppTheme.navBarHeight(context),
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.navBarPadding(context),
            vertical: AppTheme.paddingSmall(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.spa_outlined,
                activeIcon: Icons.spa,
                label: 'خدمات',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.list_alt_outlined,
                activeIcon: Icons.list_alt,
                label: 'رزروها',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'پروفایل',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavItemTapped(index),
        child: AnimatedBuilder(
          animation: _iconControllers[index],
          builder: (context, child) {
            final animationValue = _iconControllers[index].value;

            return Container(
              height: AppTheme.navBarHeight(context) * 0.75,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppTheme.borderRadiusMedium(context)),
                gradient: isSelected ? AppTheme.primaryGradient : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          offset:
                              Offset(0, AppTheme.paddingSmall(context) * 0.5),
                          blurRadius: AppTheme.paddingMedium(context),
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusMedium(context)),
                  onTap: () => _onNavItemTapped(index),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingMedium(context)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSelected ? activeIcon : icon,
                            key: ValueKey(isSelected),
                            color: isSelected
                                ? Colors.white
                                : AppTheme.statusDefaultColor,
                            size: AppTheme.navBarIconSize(context),
                          ),
                        ),
                        SizedBox(width: AppTheme.paddingSmall(context)),
                        AnimatedOpacity(
                          opacity: isSelected ? animationValue : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: AppTheme.navBarFontSize(context),
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.statusDefaultColor,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
