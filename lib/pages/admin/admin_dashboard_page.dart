import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'admin_settings_page.dart';
import 'package:flutter_application_1/pages/admin/manage_reservations_page.dart';
import 'package:flutter_application_1/pages/admin/manage_services_page.dart';
import 'package:flutter_application_1/pages/admin/reports_page.dart';
import 'package:flutter_application_1/pages/admin/manage_users_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  List<Reservation> recentReservations = [];
  Map<String, dynamic> stats = {
    'totalReservations': 0,
    'todayReservations': 0,
    'weeklyReservations': 0,
    'monthlyReservations': 0,
    'todayIncome': 0,
    'weeklyIncome': 0,
    'monthlyIncome': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadNotifications();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final reservationsJson = prefs.getStringList('reservations') ?? [];
    final allReservations = reservationsJson
        .map((json) => Reservation.fromJson(jsonDecode(json)))
        .toList();

    // محاسبه آمار
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    setState(() {
      stats['totalReservations'] = allReservations.length;
      stats['todayReservations'] = allReservations
          .where((r) => r.date.isAfter(today))
          .length;
      stats['weeklyReservations'] = allReservations
          .where((r) => r.date.isAfter(weekAgo))
          .length;
      stats['monthlyReservations'] = allReservations
          .where((r) => r.date.isAfter(monthAgo))
          .length;

      stats['todayIncome'] = allReservations
          .where((r) => r.date.isAfter(today) && r.status == 'تأیید شده')
          .fold(0, (sum, r) => sum + r.price);
      stats['weeklyIncome'] = allReservations
          .where((r) => r.date.isAfter(weekAgo) && r.status == 'تأیید شده')
          .fold(0, (sum, r) => sum + r.price);
      stats['monthlyIncome'] = allReservations
          .where((r) => r.date.isAfter(monthAgo) && r.status == 'تأیید شده')
          .fold(0, (sum, r) => sum + r.price);

      recentReservations = allReservations
        ..sort((a, b) => b.date.compareTo(a.date));
      if (recentReservations.length > 5) {
        recentReservations = recentReservations.sublist(0, 5);
      }
    });
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList('admin_notifications') ?? [];
    final notifications = notificationsJson
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
    
    setState(() {
      _notifications = notifications;
    });
  }

  List<Map<String, dynamic>> _notifications = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('داشبورد ادمین'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryLightColor3,
        actions: [
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
      body: RefreshIndicator(
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
              _buildRecentReservations(),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'نوتیفیکیشن‌ها',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildNotificationsList(),
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
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'رزرو امروز',
          '${stats['todayReservations']}',
          '${stats['todayIncome']} ',
          
          Colors.blue,
        ),
        _buildStatCard(
          'رزرو هفته',
          '${stats['weeklyReservations']}',
          '${stats['weeklyIncome']} ',
          Colors.green,
        ),
        _buildStatCard(
          'رزرو ماه',
          '${stats['monthlyReservations']}',
          '${stats['monthlyIncome']} ',
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
            ],
            if(subtitle.isNotEmpty) ...[
              const Text('تومان',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),]
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
                  title: Text(reservation.service),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('نام: ${reservation.fullName}'),
                      Text('تلفن: ${reservation.phoneNumber}'),
                      Text('تاریخ: ${reservation.date.toString().split(' ')[0]}'),
                      Text('ساعت: ${reservation.time}'),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(reservation.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reservation.status,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'در انتظار':
        return Colors.orange;
      case 'تأیید شده':
        return Colors.green;
      case 'لغو شده':
        return Colors.red;
      default:
        return Colors.grey;
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

  Widget _buildNotificationsList() {
    if (_notifications.isEmpty) {
      return const Center(
        child: Text('هیچ نوتیفیکیشنی وجود ندارد'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        final date = DateTime.parse(notification['timestamp']);
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.notifications, color: Colors.red),
            title: Text(
              notification['type'] == 'cancellation'
                  ? 'لغو رزرو'
                  : 'نوتیفیکیشن جدید',
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('خدمت: ${notification['service']}'),
                Text('تاریخ: ${notification['date'].split('T')[0]}'),
                Text('ساعت: ${notification['time']}'),
                Text('کاربر: ${notification['user_name']}'),
                Text('شماره تماس: ${notification['user_phone']}'),
                Text(
                  'زمان: ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final notifications = prefs.getStringList('admin_notifications') ?? [];
                notifications.removeAt(index);
                await prefs.setStringList('admin_notifications', notifications);
                _loadNotifications();
              },
            ),
          ),
        );
      },
    );
  }
} 