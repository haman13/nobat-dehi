import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme.dart';

class ResponsiveHelper {
  /// حداکثر base size مجاز (35% از اندازه استاندارد موبایل)
  static const double _maxBaseSize = 375 * 1.35; // تقریباً 506px

  /// دریافت کوچک‌ترین اندازه از طول و عرض صفحه با محدودیت
  static double getBaseSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final minSize = math.min(size.width, size.height);

    // محدود کردن base size به حداکثر مقدار مجاز
    return math.min(minSize, _maxBaseSize);
  }

  /// دریافت ضریب نسبت بر اساس نوع دستگاه
  static double _getDeviceRatio(BuildContext context) {
    if (isDesktop(context)) return 0.7; // 30% کمتر برای دسکتاپ
    if (isTablet(context)) return 0.85; // 15% کمتر برای تبلت
    return 1.0; // موبایل عادی
  }

  /// محاسبه اندازه بر اساس نسبت از base size با ضریب دستگاه
  static double size(BuildContext context, double ratio) {
    final baseSize = getBaseSize(context);
    final deviceRatio = _getDeviceRatio(context);
    return baseSize * ratio * deviceRatio;
  }

  /// محاسبه اندازه فونت بر اساس نسبت از base size با ضریب دستگاه
  static double fontSize(BuildContext context, double ratio) {
    final baseSize = getBaseSize(context);
    final deviceRatio = _getDeviceRatio(context);
    return baseSize * ratio * deviceRatio;
  }

  /// محاسبه اندازه خام بدون ضریب دستگاه (برای عناصری که نباید کوچیک شوند)
  static double getRawSize(BuildContext context, double ratio) {
    final baseSize = getBaseSize(context);
    return baseSize * ratio;
  }

  /// محاسبه اندازه فونت خام بدون ضریب دستگاه
  static double getRawFontSize(BuildContext context, double ratio) {
    final baseSize = getBaseSize(context);
    return baseSize * ratio;
  }

  /// دریافت عرض صفحه
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// دریافت ارتفاع صفحه
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// بررسی اینکه آیا صفحه در حالت موبایل است
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < 600;
  }

  /// بررسی اینکه آیا صفحه در حالت تبلت است
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= 600 && width < 1024;
  }

  /// بررسی اینکه آیا صفحه در حالت دسکتاپ است
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= 1024;
  }

  /// دریافت اطلاعات کامل برای دیباگ
  static Map<String, dynamic> getDebugInfo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rawMinSize = math.min(size.width, size.height);
    final finalBaseSize = getBaseSize(context);
    final deviceRatio = _getDeviceRatio(context);

    return {
      'screenSize': '${size.width.toInt()}x${size.height.toInt()}',
      'rawMinSize': rawMinSize.toInt(),
      'finalBaseSize': finalBaseSize.toInt(),
      'deviceType': isDesktop(context)
          ? 'Desktop'
          : isTablet(context)
              ? 'Tablet'
              : 'Mobile',
      'deviceRatio': deviceRatio,
      'maxAllowed': _maxBaseSize.toInt(),
      'isLimited': rawMinSize > _maxBaseSize,
    };
  }

  /// محدود کردن عرض محتوا در دسکتاپ (70% عرض صفحه)
  static Widget wrapWithDesktopConstraint(
    BuildContext context,
    Widget child, {
    Color? backgroundColor, // رنگ حاشیه قابل تنظیم
  }) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    if (!isDesktop) {
      return child;
    }

    final maxWidth = MediaQuery.of(context).size.width * 0.7;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor ??
          AppTheme
              .primaryLightColor2, // از رنگ پاس شده یا پیش‌فرض استفاده می‌کنه
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: child,
        ),
      ),
    );
  }
}
