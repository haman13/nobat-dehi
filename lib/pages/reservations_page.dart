import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({Key? key}) : super(key: key);

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  String _phoneNumber = '';
  bool _isLoading = true;
  List<dynamic> todayReservations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // ابتدا از SharedPreferences تلاش کن
      final prefs = await SharedPreferences.getInstance();
      final phoneFromPrefs = prefs.getString('phone');

      if (phoneFromPrefs != null && phoneFromPrefs.isNotEmpty) {
        setState(() {
          _phoneNumber = phoneFromPrefs;
        });
        print('📱 شماره از SharedPreferences: $phoneFromPrefs');
        await _fetchTodayReservations();
        return;
      }

      // اگر در SharedPreferences نبود، از Supabase بگیر
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        final userData = await SupabaseConfig.client
            .from('users')
            .select()
            .eq('id', user.id)
            .single();

        setState(() {
          _phoneNumber = userData['phone'] ?? 'نامشخص';
        });
        print('📱 شماره از Supabase: ${userData['phone']}');
        await _fetchTodayReservations();
      } else {
        setState(() {
          _phoneNumber = 'کاربر لاگین نشده';
          _isLoading = false;
        });
        print('📱 کاربر لاگین نشده');
      }
    } catch (e) {
      setState(() {
        _phoneNumber = 'خطا در دریافت شماره';
        _isLoading = false;
      });
      print('📱 خطا در دریافت شماره: $e');
    }
  }

  Future<void> _fetchTodayReservations() async {
    try {
      // دریافت شماره تلفن کاربر برای فیلتر کردن رزروها
      String userPhone = _phoneNumber;
      if (userPhone == 'در حال بارگذاری...' ||
          userPhone == 'کاربر لاگین نشده' ||
          userPhone == 'خطا در دریافت شماره') {
        // تلاش برای دریافت مجدد شماره از SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        userPhone = prefs.getString('phone') ?? '';
      }

      if (userPhone.isEmpty) {
        setState(() {
          _error = 'شماره تلفن کاربر مشخص نیست';
          _isLoading = false;
        });
        return;
      }

      final data = await SupabaseConfig.client
          .from('reservations')
          .select('*, model:models(*)')
          .eq('customer_phone', userPhone)
          .order('date', ascending: false)
          .order('time', ascending: true);

      setState(() {
        todayReservations = data;
        _isLoading = false;
      });
      print('📋 کل رزروها برای شماره $userPhone: ${data.length} رزرو');
    } catch (e) {
      setState(() {
        _error = 'خطا در دریافت رزروها: ${e.toString()}';
        _isLoading = false;
      });
      print('📋 خطا در دریافت رزروها: $e');
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
      case 'تایید شده':
        return Colors.green;
      case 'cancelled':
      case 'لغو شده':
        return Colors.red;
      case 'pending':
      case 'در انتظار':
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'confirmed':
        return 'تایید شده';
      case 'cancelled':
        return 'لغو شده';
      case 'pending':
        return 'در انتظار';
      default:
        return status ?? 'نامشخص';
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

  @override
  Widget build(BuildContext context) {
    print('🔴 ReservationsPage _phoneNumber: [$_phoneNumber]');
    return Scaffold(
      appBar: AppBar(
        title: const Text('رزروهای من'),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('شماره موبایل', _phoneNumber),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Center(
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                    )
                  else if (todayReservations.isEmpty)
                    const Center(
                      child: Text(
                        'هیچ رزروی ثبت نشده است',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: todayReservations.length,
                      itemBuilder: (context, index) {
                        final reservation = todayReservations[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Stack(
                            children: [
                              ListTile(
                                title: Text(reservation['service'] ?? ''),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'مدل: ${reservation['model']?['name'] ?? ''}'),
                                    Text(
                                        'تاریخ: ${_convertToPersianDate(reservation['date'])}'),
                                    Text('ساعت: ${reservation['time'] ?? ''}'),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        _getStatusColor(reservation['status']),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(reservation['status']),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
