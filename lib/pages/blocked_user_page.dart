import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/pages/blocked_user_reservations_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/pages/welcome_page.dart';

class BlockedUserPage extends StatelessWidget {
  final String fullName;
  final String phone;
  final String? blockedReason;
  final String? blockedAt;

  const BlockedUserPage({
    super.key,
    required this.fullName,
    required this.phone,
    this.blockedReason,
    this.blockedAt,
  });

  String _formatBlockedDate() {
    if (blockedAt == null) return 'نامشخص';

    try {
      final date = DateTime.parse(blockedAt!);
      final jalaliDate = Jalali.fromDateTime(date);
      return '${jalaliDate.year}/${jalaliDate.month.toString().padLeft(2, '0')}/${jalaliDate.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'نامشخص';
    }
  }

  Future<void> _contactSupport() async {
    // شماره پشتیبانی (می‌توانید تغییر دهید)
    const supportPhone = '09123456789';

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: supportPhone,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      // خطا در باز کردن شماره
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: const Text('حساب مسدود شده'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // آیکون و پیام اصلی
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // آیکون مسدودیت
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.block,
                        size: 60,
                        color: Colors.red,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // پیام اصلی
                    const Text(
                      'حساب شما مسدود شده است',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'سلام $fullName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'متأسفانه حساب کاربری شما به دلیل نقض قوانین مسدود شده است.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // اطلاعات مسدودیت
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'جزئیات مسدودیت:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // تاریخ مسدودیت
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        const Text('تاریخ مسدودیت: ',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(_formatBlockedDate()),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // دلیل مسدودیت
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        const Text('دلیل: ',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        Expanded(
                          child: Text(
                            blockedReason?.isNotEmpty == true
                                ? blockedReason!
                                : 'دلیل مشخص نشده است',
                            style: TextStyle(
                              color: blockedReason?.isNotEmpty == true
                                  ? Colors.red[700]
                                  : Colors.grey,
                              fontWeight: blockedReason?.isNotEmpty == true
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // دکمه‌های عملیات
              Column(
                children: [
                  // دکمه تماس با پشتیبانی
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _contactSupport,
                      icon: const Icon(Icons.phone, color: Colors.white),
                      label: const Text(
                        'تماس با پشتیبانی',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // دکمه خروج از حساب
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const WelcomePage()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'خروج از حساب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // پیام راهنما
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 24),
                    SizedBox(height: 8),
                    Text(
                      'درخواست رفع مسدودیت',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'برای درخواست رفع مسدودیت، لطفاً با پشتیبانی تماس بگیرید و شرایط خود را توضیح دهید.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
