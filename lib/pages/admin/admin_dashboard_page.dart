import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';
import 'admin_settings_page.dart';
import 'package:flutter_application_1/pages/admin/manage_reservations_page.dart';
import 'package:flutter_application_1/pages/admin/manage_services_page.dart';
import 'package:flutter_application_1/pages/admin/reports_page.dart';
import 'package:flutter_application_1/pages/admin/manage_users_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<dynamic> recentReservations = [];
  Map<String, dynamic> stats = {
    'totalReservations': 0,
    'todayReservations': 0,
    'weeklyReservations': 0,
    'monthlyReservations': 0,
    'todayIncome': 0,
    'weeklyIncome': 0,
    'monthlyIncome': 0,
    'todayUserCancelled': 0,
    'weeklyUserCancelled': 0,
    'monthlyUserCancelled': 0,
  };
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadNotifications();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // بارگذاری رزروها از دیتابیس
      final reservationsResponse =
          await SupabaseConfig.client.from('reservations').select('''
            *,
            models!inner(
              id,
              name,
              price,
              duration,
              description
            ),
            services!inner(
              id,
              label
            )
          ''').order('date', ascending: false);

      // محاسبه آمار
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = today.subtract(const Duration(days: 7));
      final monthAgo = DateTime(now.year, now.month - 1, now.day);

      int totalReservations = reservationsResponse.length;
      int todayReservations = 0;
      int weeklyReservations = 0;
      int monthlyReservations = 0;
      int todayIncome = 0;
      int weeklyIncome = 0;
      int monthlyIncome = 0;
      int todayUserCancelled = 0;
      int weeklyUserCancelled = 0;
      int monthlyUserCancelled = 0;

      for (var reservation in reservationsResponse) {
        final reservationDate = DateTime.parse(reservation['date']);
        final price = reservation['models']?['price'] ?? 0;
        final status = reservation['status'] ?? '';

        // فقط رزروهای تأیید شده را در درآمد حساب کن
        bool isConfirmed = status == 'confirmed' || status == 'تأیید شده';
        bool isUserCancelled = status == 'user_cancelled';

        if (reservationDate.isAfter(today.subtract(const Duration(days: 1))) &&
            reservationDate.isBefore(today.add(const Duration(days: 1)))) {
          todayReservations++;
          if (isConfirmed) todayIncome += price as int;
          if (isUserCancelled) todayUserCancelled++;
        }

        if (reservationDate.isAfter(weekAgo)) {
          weeklyReservations++;
          if (isConfirmed) weeklyIncome += price as int;
          if (isUserCancelled) weeklyUserCancelled++;
        }

        if (reservationDate.isAfter(monthAgo)) {
          monthlyReservations++;
          if (isConfirmed) monthlyIncome += price as int;
          if (isUserCancelled) monthlyUserCancelled++;
        }
      }

      setState(() {
        stats['totalReservations'] = totalReservations;
        stats['todayReservations'] = todayReservations;
        stats['weeklyReservations'] = weeklyReservations;
        stats['monthlyReservations'] = monthlyReservations;
        stats['todayIncome'] = todayIncome;
        stats['weeklyIncome'] = weeklyIncome;
        stats['monthlyIncome'] = monthlyIncome;
        stats['todayUserCancelled'] = todayUserCancelled;
        stats['weeklyUserCancelled'] = weeklyUserCancelled;
        stats['monthlyUserCancelled'] = monthlyUserCancelled;

        recentReservations = reservationsResponse.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'خطا در بارگذاری داده‌ها: $e';
        _isLoading = false;
      });
      print('خطا در بارگذاری داده‌های Dashboard: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          prefs.getStringList('admin_notifications') ?? [];

      List<Map<String, dynamic>> notifications = [];
      for (String notificationStr in notificationsJson) {
        try {
          final notificationData =
              jsonDecode(notificationStr) as Map<String, dynamic>;
          if (notificationData['is_read'] == false) {
            notifications.add(notificationData);
          }
        } catch (e) {
          print('خطا در parse کردن نوتیفیکیشن: $e');
        }
      }

      // مرتب‌سازی بر اساس created_at (جدیدترین اول)
      notifications.sort((a, b) {
        final aTime =
            DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final bTime =
            DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      print('⚠️ خطا در بارگذاری نوتیفیکیشن‌ها: $e');
      setState(() {
        _notifications = [];
      });
    }
  }

  List<Map<String, dynamic>> _notifications = [];

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'در انتظار';
      case 'confirmed':
        return 'تأیید شده';
      case 'cancelled':
        return 'لغو شده';
      case 'user_cancelled':
        return '🔔 لغو شده توسط کاربر';
      case 'admin_cancelled':
        return 'لغو شده از سمت ادمین';
      default:
        return status;
    }
  }

  String _convertToPersianDate(String? gregorianDate) {
    if (gregorianDate == null || gregorianDate.isEmpty) return 'نامشخص';

    try {
      final DateTime date = DateTime.parse(gregorianDate);
      final Jalali jalaliDate = Jalali.fromDateTime(date);

      return '${jalaliDate.year}/${jalaliDate.month.toString().padLeft(2, '0')}/${jalaliDate.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return gregorianDate; // در صورت خطا همان تاریخ اصلی را نمایش بده
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'user_cancelled':
        return Colors.deepOrange;
      case 'admin_cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('داشبورد ادمین'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryLightColor3,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadData();
              await _loadNotifications();
            },
            tooltip: 'بروزرسانی',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await _loadData();
                          await _loadNotifications();
                        },
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadData();
                    await _loadNotifications();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsGrid(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildNotificationsList(),
                        const SizedBox(height: 24),
                        _buildRecentReservations(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'رزرو امروز',
          '${stats['todayReservations']}',
          '${stats['todayIncome']}',
          Colors.blue,
        ),
        _buildStatCard(
          'رزرو هفته',
          '${stats['weeklyReservations']}',
          '${stats['weeklyIncome']}',
          Colors.green,
        ),
        _buildStatCard(
          'رزرو ماه',
          '${stats['monthlyReservations']}',
          '${stats['monthlyIncome']}',
          Colors.orange,
        ),
        _buildStatCard(
          'کل رزروها',
          '${stats['totalReservations']}',
          '',
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, String subtitle, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const Text(
                'تومان',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'دسترسی سریع',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'مدیریت رزروها',
                Icons.calendar_today,
                Colors.blue,
                _navigateToManageReservations,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'مدیریت خدمات',
                Icons.category,
                Colors.green,
                _navigateToManageServices,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'گزارش‌ها',
                Icons.bar_chart,
                Colors.orange,
                _navigateToReports,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'مدیریت کاربران',
                Icons.people,
                Colors.purple,
                _navigateToManageUsers,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReservations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'رزروهای اخیر',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (recentReservations.isEmpty)
          const Center(
            child: Text('هیچ رزروی یافت نشد'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentReservations.length,
            itemBuilder: (context, index) {
              final reservation = recentReservations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title:
                      Text(reservation['services']?['label'] ?? 'خدمت نامشخص'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('نام: ${reservation['customer_name'] ?? 'نامشخص'}'),
                      Text(
                          'تلفن: ${reservation['customer_phone'] ?? 'نامشخص'}'),
                      Text(
                          'تاریخ: ${_convertToPersianDate(reservation['date'])}'),
                      Text('ساعت: ${reservation['time'] ?? ''}'),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(reservation['status'] ?? 'pending'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(reservation['status'] ?? 'pending'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildNotificationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔔 نوتیفیکیشن‌ها',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_notifications.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text(
                  'همه نوتیفیکیشن‌ها خوانده شده است ✅',
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.deepOrange.withOpacity(0.3)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepOrange.withOpacity(0.1),
                        Colors.white,
                      ],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                  ),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.cancel,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notification['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${notification['customer_name']} - ${notification['service_name']}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: ElevatedButton.icon(
                      onPressed: () =>
                          _markNotificationAsRead(notification['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('متوجه شدم'),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                    'نام: ${notification['customer_name'] ?? 'نامشخص'}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                    'تلفن: ${notification['customer_phone'] ?? 'نامشخص'}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.category,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                    'خدمت: ${notification['service_name'] ?? 'نامشخص'}'),
                              ],
                            ),
                            if (notification['model_name'] != null &&
                                notification['model_name']
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.design_services,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('مدل: ${notification['model_name']}'),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.date_range,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                    'تاریخ: ${_convertToPersianDate(notification['date'])}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                    'ساعت: ${notification['time'] ?? 'نامشخص'}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.schedule,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                    'زمان لغو: ${_formatNotificationTime(notification['created_at'])}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // تابع فرمت کردن زمان نوتیفیکیشن
  String _formatNotificationTime(String? createdAt) {
    if (createdAt == null) return 'نامشخص';

    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} دقیقه پیش';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ساعت پیش';
      } else {
        return '${difference.inDays} روز پیش';
      }
    } catch (e) {
      return 'نامشخص';
    }
  }

  // تابع علامت‌گذاری نوتیفیکیشن به عنوان خوانده شده
  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          prefs.getStringList('admin_notifications') ?? [];

      List<String> updatedNotifications = [];
      for (String notificationStr in notificationsJson) {
        try {
          final notificationData =
              jsonDecode(notificationStr) as Map<String, dynamic>;
          if (notificationData['id'] == notificationId) {
            notificationData['is_read'] = true;
          }
          updatedNotifications.add(jsonEncode(notificationData));
        } catch (e) {
          print('خطا در پردازش نوتیفیکیشن: $e');
          updatedNotifications.add(notificationStr); // حفظ نوتیفیکیشن اصلی
        }
      }

      await prefs.setStringList('admin_notifications', updatedNotifications);

      // بروزرسانی لیست نوتیفیکیشن‌ها
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('نوتیفیکیشن به عنوان خوانده شده علامت‌گذاری شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('⚠️ خطا در علامت‌گذاری نوتیفیکیشن: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در علامت‌گذاری نوتیفیکیشن: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _navigateToManageReservations() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageReservationsPage()),
    );
  }

  void _navigateToManageServices() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageServicesPage()),
    );
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportsPage()),
    );
  }

  void _navigateToManageUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageUsersPage()),
    );
  }
}
