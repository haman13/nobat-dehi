import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/responsive_helper.dart';

class AppTheme {
  // رنگ‌های اصلی برنامه - ترکیب مدرن صورتی و بنفش
  static const Color primaryColor = Color(0xFFE91E63); // pink[600]
  static const Color primaryDarkColor = Color(0xFFAD1457); // pink[800]
  static const Color primaryLightColor = Color(0xFFF8BBD0); // pink[100]
  static const Color primaryLightColor2 = Color(0xFFFCE4EC); // pink[50]
  static const Color accentColor = Color(0xFF9C27B0); // purple[500]
  static const Color accentLightColor = Color(0xFFE1BEE7); // purple[100]

  // رنگ‌های گرادیان مدرن
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE91E63), // pink[600]
      Color(0xFFAD1457), // pink[800]
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9C27B0), // purple[500]
      Color(0xFFE91E63), // pink[600]
    ],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFCE4EC), // pink[50]
      Color(0xFFF3E5F5), // purple[50]
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      Color(0xFFFCE4EC), // pink[50]
    ],
  );

  // رنگ‌های وضعیت - بهبود یافته
  static const Color todayReservationColor = Color(0xFF2196F3); // blue[500]
  static const Color weekReservationColor = Color(0xFF4CAF50); // green[500]
  static const Color monthReservationColor = Color(0xFFFF9800); // orange[500]
  static const Color allReservationColor = Color(0xFF9C27B0); // purple[500]

  // رنگ‌های متن
  static const Color textPrimaryColor = Color(0xFF212121); // grey[900]
  static const Color textSecondaryColor = Color(0xFF757575); // grey[600]
  static const Color textOnPrimaryColor = Colors.white;
  static const Color textHintColor = Color(0xFF9E9E9E); // grey[500]

  // رنگ‌های پس‌زمینه
  static const Color backgroundColor = Color(0xFFFAFAFA); // grey[50]
  static const Color surfaceColor = Colors.white;
  static const Color cardBackgroundColor = Colors.white;

  // رنگ‌های وضعیت
  static const Color statusPendingColor = Color(0xFFFF9800); // orange[500]
  static const Color statusConfirmedColor = Color(0xFF4CAF50); // green[500]
  static const Color statusCancelledColor = Color(0xFFF44336); // red[500]
  static const Color statusDefaultColor = Color(0xFF9E9E9E); // grey[500]

  // ===== نسبت‌های ریسپانسیو =====

  // Navigation Bar - اندازه‌های مستقل برای تجربه بهتر
  static const double _navBarHeightRatio = 0.09; // 9% از base size موبایل
  static const double _navBarPaddingRatio = 0.04; // 4% از base size

  // حداقل و حداکثر اندازه‌های Navigation Bar
  static const double _minNavBarHeight =
      58.0; // کاهش 2 پیکسل برای حل مشکل overflow
  static const double _maxNavBarHeight = 88.0; // کاهش متناسب حداکثر
  static const double _minNavBarPadding = 16.0; // حداقل padding

  // Padding و Margin
  static const double _paddingSmallRatio = 0.015; // 1.5% از base size
  static const double _paddingMediumRatio = 0.03; // 3% از base size
  static const double _paddingLargeRatio = 0.045; // 4.5% از base size

  // Border Radius
  static const double _borderRadiusSmallRatio = 0.02; // 2% از base size
  static const double _borderRadiusMediumRatio = 0.03; // 3% از base size
  static const double _borderRadiusLargeRatio = 0.045; // 4.5% از base size

  // Font Sizes - برای Navigation Bar اندازه‌های مستقل
  static const double _fontSmallRatio = 0.025; // 2.5% از base size
  static const double _fontMediumRatio = 0.032; // 3.2% از base size
  static const double _fontLargeRatio = 0.04; // 4% از base size
  static const double _fontXLargeRatio = 0.05; // 5% از base size
  static const double _fontCardRatio = 0.038; // 3.8% از base size

  // فونت‌های Navigation Bar - حداقل اندازه‌ها
  static const double _minNavFontSize = 13.0; // حداقل اندازه فونت navigation
  static const double _maxNavFontSize = 16.0; // حداکثر اندازه فونت navigation

  // Icon Sizes - برای Navigation Bar اندازه‌های مستقل
  static const double _iconSmallRatio = 0.035; // 3.5% از base size
  static const double _iconMediumRatio = 0.045; // 4.5% از base size
  static const double _iconLargeRatio = 0.055; // 5.5% از base size

  // آیکون‌های Navigation Bar - حداقل اندازه‌ها
  static const double _minNavIconSize = 22.0; // حداقل اندازه آیکون navigation
  static const double _maxNavIconSize = 28.0; // حداکثر اندازه آیکون navigation

  // Card Dimensions
  static const double _cardPaddingRatio = 0.05; // 5% از base size
  static const double _cardElevationRatio = 0.01; // 1% از base size

  // ===== متدهای ریسپانسیو =====

  // Navigation Bar - با حداقل و حداکثر محدودیت
  static double navBarHeight(BuildContext context) {
    final calculatedSize =
        ResponsiveHelper.getRawSize(context, _navBarHeightRatio);
    return calculatedSize.clamp(_minNavBarHeight, _maxNavBarHeight);
  }

  static double navBarPadding(BuildContext context) {
    final calculatedSize =
        ResponsiveHelper.getRawSize(context, _navBarPaddingRatio);
    return calculatedSize.clamp(_minNavBarPadding, double.infinity);
  }

  // فونت Navigation Bar با محدودیت
  static double navBarFontSize(BuildContext context) {
    final calculatedSize =
        ResponsiveHelper.getRawFontSize(context, _fontMediumRatio);
    return calculatedSize.clamp(_minNavFontSize, _maxNavFontSize);
  }

  // آیکون Navigation Bar با محدودیت
  static double navBarIconSize(BuildContext context) {
    final calculatedSize =
        ResponsiveHelper.getRawSize(context, _iconMediumRatio);
    return calculatedSize.clamp(_minNavIconSize, _maxNavIconSize);
  }

  // Padding و Margin
  static double paddingSmall(BuildContext context) =>
      ResponsiveHelper.size(context, _paddingSmallRatio);
  static double paddingMedium(BuildContext context) =>
      ResponsiveHelper.size(context, _paddingMediumRatio);
  static double paddingLarge(BuildContext context) =>
      ResponsiveHelper.size(context, _paddingLargeRatio);

  // Border Radius
  static double borderRadiusSmall(BuildContext context) =>
      ResponsiveHelper.size(context, _borderRadiusSmallRatio);
  static double borderRadiusMedium(BuildContext context) =>
      ResponsiveHelper.size(context, _borderRadiusMediumRatio);
  static double borderRadiusLarge(BuildContext context) =>
      ResponsiveHelper.size(context, _borderRadiusLargeRatio);

  // Font Sizes
  static double fontSmall(BuildContext context) =>
      ResponsiveHelper.fontSize(context, _fontSmallRatio);
  static double fontMedium(BuildContext context) =>
      ResponsiveHelper.fontSize(context, _fontMediumRatio);
  static double fontLarge(BuildContext context) =>
      ResponsiveHelper.fontSize(context, _fontLargeRatio);
  static double fontXLarge(BuildContext context) =>
      ResponsiveHelper.fontSize(context, _fontXLargeRatio);
  static double fontCard(BuildContext context) =>
      ResponsiveHelper.fontSize(context, _fontCardRatio);

  // Icon Sizes
  static double iconSmall(BuildContext context) =>
      ResponsiveHelper.size(context, _iconSmallRatio);
  static double iconMedium(BuildContext context) =>
      ResponsiveHelper.size(context, _iconMediumRatio);
  static double iconLarge(BuildContext context) =>
      ResponsiveHelper.size(context, _iconLargeRatio);

  // Card Dimensions
  static double cardPadding(BuildContext context) =>
      ResponsiveHelper.size(context, _cardPaddingRatio);
  static double cardElevation(BuildContext context) =>
      ResponsiveHelper.size(context, _cardElevationRatio);

  // ===== استایل‌های متنی ریسپانسیو =====

  static TextStyle responsiveTitleStyle(BuildContext context) => TextStyle(
        fontSize: fontXLarge(context),
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        letterSpacing: -0.5,
      );

  static TextStyle responsiveSubtitleStyle(BuildContext context) => TextStyle(
        fontSize: fontLarge(context),
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        letterSpacing: -0.3,
      );

  static TextStyle responsiveBodyStyle(BuildContext context) => TextStyle(
        fontSize: fontMedium(context),
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
        height: 1.5,
      );

  static TextStyle responsiveCaptionStyle(BuildContext context) => TextStyle(
        fontSize: fontSmall(context),
        fontWeight: FontWeight.w400,
        color: textSecondaryColor,
        height: 1.4,
      );

  static TextStyle responsiveButtonTextStyle(BuildContext context) => TextStyle(
        fontSize: fontMedium(context),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle responsiveCardTitleStyle(BuildContext context) => TextStyle(
        fontSize: fontCard(context),
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        letterSpacing: -0.3,
      );

  // سایه‌ها و elevation مدرن
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x26E91E63),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> appBarShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  // استایل‌های متنی بهبود یافته
  static const TextStyle titleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    letterSpacing: -0.5,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
    letterSpacing: -0.3,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
    height: 1.5,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
    height: 1.4,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // ویجت لوگو بهبود یافته
  static Widget getLogo({double size = 50}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.asset(
          'assets/images/logo1.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // استایل دکمه‌های مدرن
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  ).copyWith(
    backgroundColor: MaterialStateProperty.resolveWith<Color>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.pressed)) {
          return primaryDarkColor;
        }
        if (states.contains(MaterialState.disabled)) {
          return textHintColor;
        }
        return primaryColor;
      },
    ),
  );

  static ButtonStyle gradientButtonStyle(LinearGradient gradient) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    );
  }

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor, width: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  // استایل کارت‌های مدرن (ثابت)
  static BoxDecoration modernCardDecoration = BoxDecoration(
    color: cardBackgroundColor,
    borderRadius: BorderRadius.circular(20),
    boxShadow: cardShadow,
    border: Border.all(
      color: primaryLightColor.withOpacity(0.3),
      width: 1,
    ),
  );

  // استایل کارت‌های مدرن (ریسپانسیو)
  static BoxDecoration responsiveModernCardDecoration(BuildContext context) =>
      BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadiusMedium(context)),
        boxShadow: cardShadow,
        border: Border.all(
          color: primaryLightColor.withOpacity(0.3),
          width: 1,
        ),
      );

  static BoxDecoration gradientCardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    gradient: cardGradient,
    boxShadow: cardShadow,
  );

  // استایل فیلدهای ورودی مدرن
  static InputDecoration modernTextFieldDecoration = InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: textHintColor.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: textHintColor.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: statusCancelledColor, width: 2),
    ),
    fillColor: surfaceColor,
    filled: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    hintStyle: const TextStyle(
      color: textHintColor,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    labelStyle: const TextStyle(
      color: textSecondaryColor,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
  );

  // ویجت دکمه گرادیان
  static Widget gradientButton({
    required VoidCallback onPressed,
    required Widget child,
    LinearGradient? gradient,
    List<BoxShadow>? boxShadow,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? primaryGradient,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: boxShadow ?? buttonShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }

  // تابع بهبود یافته برای نمایش دیالوگ ادمین
  static Widget buildModernDialog({
    required String title,
    required String content,
    List<Widget>? actions,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: modernCardDecoration,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: subtitleStyle),
            const SizedBox(height: 16),
            Text(content, style: bodyStyle, textAlign: TextAlign.center),
            if (actions != null) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }

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
      builder: (context) => buildModernDialog(
        title: 'ورود به پنل ادمین',
        content: 'در حال ورود به پنل ادمین...',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: textButtonStyle,
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
