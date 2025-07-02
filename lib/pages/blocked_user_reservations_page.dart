import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';
import 'package:flutter_application_1/pages/blocked_user_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class BlockedUserReservationsPage extends StatefulWidget {
  const BlockedUserReservationsPage({super.key});

  @override
  State<BlockedUserReservationsPage> createState() =>
      _BlockedUserReservationsPageState();
}

class _BlockedUserReservationsPageState
    extends State<BlockedUserReservationsPage> {
  String _phoneNumber = '';
  String _fullName = '';
  List<dynamic> reservations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('phone') ?? '';
      final fullName = prefs.getString('fullname') ?? '';

      setState(() {
        _phoneNumber = phone;
        _fullName = fullName;
      });

      if (phone.isNotEmpty) {
        await _loadReservations();
      } else {
        setState(() {
          _error = 'اطلاعات کاربر یافت نشد';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطا در بارگذاری اطلاعات کاربر: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReservations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await SupabaseConfig.client
          .from('reservations')
          .select('''
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
          ''')
          .eq('customer_phone', _phoneNumber)
          .order('date', ascending: false)
          .order('time', ascending: true);

      setState(() {
        reservations = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'خطا در بارگذاری رزروها: $e';
        _isLoading = false;
      });
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'confirmed':
        return 'تأیید شده';
      case 'cancelled':
        return 'لغو شده';
      case 'admin_cancelled':
        return 'لغو شده توسط ادمین';
      case 'pending':
        return 'در انتظار';
      default:
        return status ?? 'نامشخص';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
      case 'admin_cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _convertToPersianDate(String? gregorianDate) {
    if (gregorianDate == null || gregorianDate.isEmpty) return 'نامشخص';

    try {
      final DateTime date = DateTime.parse(gregorianDate);
      final Jalali jalaliDate = Jalali.fromDateTime(date);
      return '${jalaliDate.year}/${jalaliDate.month.toString().padLeft(2, '0')}/${jalaliDate.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return gregorianDate;
    }
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return formatter.format(amount);
  }

  Future<void> _goBackToBlockedPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullName = prefs.getString('fullname') ?? '';
      final phone = prefs.getString('phone') ?? '';

      // دریافت اطلاعات مسدودیت از دیتابیس
      final userData = await SupabaseConfig.client
          .from('users')
          .select('blocked_reason, blocked_at')
          .eq('phone', phone)
          .single();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BlockedUserPage(
            fullName: fullName,
            phone: phone,
            blockedReason: userData['blocked_reason'],
            blockedAt: userData['blocked_at'],
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: const Text('رزروهای شما'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToBlockedPage,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: Column(
        children: [
          // هشدار مسدودیت
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red[600],
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حساب شما مسدود است',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'امکان ثبت رزرو جدید وجود ندارد',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // محتوای اصلی
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.red))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadReservations,
                              child: const Text('تلاش مجدد'),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        color: Colors.white,
                        child: reservations.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'هیچ رزروی ثبت نشده است',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadReservations,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: reservations.length,
                                  itemBuilder: (context, index) {
                                    final reservation = reservations[index];
                                    final model = reservation['models'];
                                    final service = reservation['services'];
                                    final status = reservation['status'];

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: _getStatusColor(status)
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // ردیف اول: خدمت و وضعیت
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    service?['label'] ??
                                                        'خدمت نامشخص',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _getStatusColor(status),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    _getStatusText(status),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 12),

                                            // نام مدل
                                            Text(
                                              model?['name'] ?? 'مدل نامشخص',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.blue,
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            // اطلاعات تاریخ و زمان
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _convertToPersianDate(
                                                      reservation['date']),
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                                const SizedBox(width: 16),
                                                const Icon(Icons.access_time,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 6),
                                                Text(
                                                  reservation['time'] ??
                                                      'نامشخص',
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 8),

                                            // قیمت و مدت زمان
                                            Row(
                                              children: [
                                                const Icon(Icons.attach_money,
                                                    size: 16,
                                                    color: Colors.green),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${_formatCurrency(model?['price'] ?? 0)} تومان',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                const Icon(Icons.timer,
                                                    size: 16,
                                                    color: Colors.blue),
                                                const SizedBox(width: 6),
                                                Text(
                                                  model?['duration'] ??
                                                      'نامشخص',
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                              ],
                                            ),

                                            // توضیحات (در صورت وجود)
                                            if (model?['description'] != null &&
                                                model['description']
                                                    .toString()
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  model['description'],
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
