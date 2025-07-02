import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'dart:convert';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({Key? key}) : super(key: key);

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  String _phoneNumber = '';
  bool _isLoading = true;
  List<dynamic> todayReservations = [];
  List<dynamic> filteredReservations = [];
  String? _error;

  // متغیرهای فیلتر
  List<Map<String, dynamic>> services = [];
  String selectedService = 'همه خدمات';
  String selectedStatus = 'همه';
  String selectedDateRange = 'همه';
  String? selectedMonth; // فرمت: "1403/08"
  String selectedMonthDisplay = ''; // برای نمایش: "آبان 1403"

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // _loadServices(); // حذف شد - خدمات بر اساس رزروها لود می‌شوند
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

  Future<void> _loadServices() async {
    // این متد دیگر از دیتابیس استفاده نمی‌کند
    // خدمات بر اساس رزروهای موجود بارگذاری می‌شوند
  }

  // بارگذاری خدمات بر اساس رزروهای موجود
  void _loadServicesFromReservations() {
    try {
      // استخراج خدمات یونیک از رزروها
      Set<String> uniqueServices = {};
      for (var reservation in todayReservations) {
        if (reservation['service'] != null &&
            reservation['service'].toString().isNotEmpty) {
          uniqueServices.add(reservation['service'].toString());
        }
      }

      // تبدیل به فرمت مورد نیاز
      List<Map<String, dynamic>> servicesList = [
        {'id': 'all', 'label': 'همه خدمات'},
      ];

      for (String serviceName in uniqueServices) {
        servicesList.add({
          'id': serviceName,
          'label': serviceName,
        });
      }

      setState(() {
        services = servicesList;
        // اگر خدمت انتخابی دیگر در لیست نیست، به "همه خدمات" برگردان
        if (selectedService != 'همه خدمات' &&
            !uniqueServices.contains(selectedService)) {
          selectedService = 'همه خدمات';
        }
      });
    } catch (e) {
      print('خطا در بارگذاری خدمات از رزروها: $e');
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
        filteredReservations = data; // تنظیم اولیه
        _isLoading = false;
      });

      // بارگذاری خدمات بر اساس رزروهای لود شده
      _loadServicesFromReservations();

      _applyFilters();
      print('📋 کل رزروها برای شماره $userPhone: ${data.length} رزرو');
    } catch (e) {
      setState(() {
        _error = 'خطا در دریافت رزروها: ${e.toString()}';
        _isLoading = false;
      });
      print('📋 خطا در دریافت رزروها: $e');
    }
  }

  // نمایش دیالوگ انتخاب ماه
  Future<void> _selectMonth() async {
    final currentJalali = Jalali.now();
    int selectedYear = currentJalali.year;
    int selectedMonthNum = currentJalali.month;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('انتخاب ماه'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // انتخاب سال
              Row(
                children: [
                  const Text('سال: '),
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: selectedYear,
                      items: List.generate(11, (index) => 1400 + index)
                          .map((year) => DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              ))
                          .toList(),
                      onChanged: (year) {
                        setDialogState(() {
                          selectedYear = year ?? currentJalali.year;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // انتخاب ماه
              Row(
                children: [
                  const Text('ماه: '),
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: selectedMonthNum,
                      items: List.generate(12, (index) => index + 1)
                          .map((month) => DropdownMenuItem(
                                value: month,
                                child: Text(_getMonthName(month)),
                              ))
                          .toList(),
                      onChanged: (month) {
                        setDialogState(() {
                          selectedMonthNum = month ?? currentJalali.month;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedMonth =
                      '$selectedYear/${selectedMonthNum.toString().padLeft(2, '0')}';
                  selectedMonthDisplay =
                      '${_getMonthName(selectedMonthNum)} $selectedYear';
                  selectedDateRange = 'ماه انتخابی';
                });
                _applyFilters();
                Navigator.pop(context);
              },
              child: const Text('تأیید'),
            ),
          ],
        ),
      ),
    );
  }

  // تبدیل شماره ماه به نام فارسی
  String _getMonthName(int month) {
    const months = [
      '',
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند'
    ];
    return months[month];
  }

  // اعمال فیلترها
  void _applyFilters() {
    List<dynamic> filtered = List.from(todayReservations);

    // فیلتر بر اساس خدمت
    if (selectedService != 'همه خدمات') {
      filtered = filtered.where((reservation) {
        return reservation['service'] == selectedService;
      }).toList();
    }

    // فیلتر بر اساس وضعیت
    if (selectedStatus != 'همه') {
      filtered = filtered.where((reservation) {
        final status = reservation['status']?.toString().toLowerCase();
        switch (selectedStatus) {
          case 'در انتظار':
            return status == 'pending' || status == 'در انتظار';
          case 'تایید شده':
            return status == 'confirmed' || status == 'تایید شده';
          case 'لغو شده':
            return status == 'cancelled' ||
                status == 'لغو شده' ||
                status == 'user_cancelled' ||
                status == 'admin_cancelled';
          default:
            return true;
        }
      }).toList();
    }

    // فیلتر بر اساس تاریخ
    if (selectedDateRange != 'همه') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      filtered = filtered.where((reservation) {
        try {
          final reservationDate = DateTime.parse(reservation['date']);
          final reservationDateOnly = DateTime(
            reservationDate.year,
            reservationDate.month,
            reservationDate.day,
          );

          switch (selectedDateRange) {
            case 'امروز':
              return reservationDateOnly.isAtSameMomentAs(today);
            case 'این هفته':
              final weekStart =
                  today.subtract(Duration(days: today.weekday - 1));
              final weekEnd = weekStart.add(const Duration(days: 6));
              return reservationDateOnly
                      .isAfter(weekStart.subtract(const Duration(days: 1))) &&
                  reservationDateOnly
                      .isBefore(weekEnd.add(const Duration(days: 1)));
            case 'این ماه':
              return reservationDateOnly.year == today.year &&
                  reservationDateOnly.month == today.month;
            case 'ماه انتخابی':
              if (selectedMonth == null) return true;
              try {
                final parts = selectedMonth!.split('/');
                final selectedYear = int.parse(parts[0]);
                final selectedMonthNum = int.parse(parts[1]);
                final jalali = Jalali.fromDateTime(reservationDate);
                return jalali.year == selectedYear &&
                    jalali.month == selectedMonthNum;
              } catch (e) {
                return false;
              }
            default:
              return true;
          }
        } catch (e) {
          return false;
        }
      }).toList();
    }

    setState(() {
      filteredReservations = filtered;
    });
  }

  // بررسی اینکه آیا رزرو قابل حذف است یا نه
  bool _canDeleteReservation(Map<String, dynamic> reservation) {
    try {
      // 1. بررسی تاریخ - آیا رزرو برای آینده است؟
      final reservationDate = reservation['date'];
      if (reservationDate == null || reservationDate.isEmpty) {
        return false;
      }

      final DateTime reservationDateTime = DateTime.parse(reservationDate);
      final DateTime today = DateTime.now();

      // مقایسه فقط تاریخ (بدون ساعت)
      final DateTime reservationDateOnly = DateTime(
        reservationDateTime.year,
        reservationDateTime.month,
        reservationDateTime.day,
      );
      final DateTime todayDateOnly = DateTime(
        today.year,
        today.month,
        today.day,
      );

      // اگر تاریخ رزرو گذشته باشد، قابل حذف نیست
      if (reservationDateOnly.isBefore(todayDateOnly)) {
        return false;
      }

      // 2. بررسی وضعیت - آیا در حالت مناسب است؟
      final status = reservation['status']?.toString().toLowerCase();
      if (status == 'pending' ||
          status == 'confirmed' ||
          status == 'در انتظار' ||
          status == 'تایید شده') {
        return true;
      }

      // رزروهای لغو شده قابل حذف نیستند
      if (status == 'cancelled' ||
          status == 'user_cancelled' ||
          status == 'admin_cancelled' ||
          status == 'لغو شده') {
        return false;
      }

      return false;
    } catch (e) {
      print('❌ خطا در بررسی قابلیت حذف رزرو: $e');
      return false;
    }
  }

  // نمایش دیالوگ تأیید حذف
  Future<void> _showDeleteConfirmation(Map<String, dynamic> reservation) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأیید حذف رزرو'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('آیا مطمئن هستید که می‌خواهید این رزرو را حذف کنید؟'),
              const SizedBox(height: 8),
              Text('خدمت: ${reservation['service'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('تاریخ: ${_convertToPersianDate(reservation['date'])}'),
              Text('ساعت: ${reservation['time'] ?? ''}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteReservation(reservation);
    }
  }

  // لغو رزرو (تغییر وضعیت بجای حذف)
  Future<void> _deleteReservation(Map<String, dynamic> reservation) async {
    try {
      // نمایش لودینگ
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('در حال لغو رزرو...'),
            ],
          ),
        ),
      );

      // بررسی وضعیت قبلی رزرو
      final currentStatus = reservation['status']?.toString().toLowerCase();
      String newStatus;

      // اگر رزرو تایید شده بود، برای ادمین مهم است
      if (currentStatus == 'confirmed' || currentStatus == 'تایید شده') {
        newStatus = 'user_cancelled'; // ادمین باید بداند این رزرو تایید شده بود
      } else {
        newStatus = 'cancelled'; // رزرو در انتظار بود، عادی لغو می‌شود
      }

      // تغییر وضعیت بجای حذف
      await SupabaseConfig.client
          .from('reservations')
          .update({'status': newStatus}).eq('id', reservation['id']);

      // اگر رزرو تایید شده بود، نوتیفیکیشن برای ادمین ایجاد کن
      if (newStatus == 'user_cancelled') {
        try {
          final prefs = await SharedPreferences.getInstance();
          final notifications =
              prefs.getStringList('admin_notifications') ?? [];

          final notificationData = {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'type': 'user_cancellation',
            'title': 'لغو رزرو توسط کاربر',
            'message': 'رزرو تایید شده لغو شد',
            'customer_name': reservation['customer_name'] ?? 'کاربر',
            'customer_phone': reservation['customer_phone'] ?? '',
            'service_name': reservation['services']?['label'] ??
                reservation['service'] ??
                '',
            'model_name': reservation['models']?['name'] ?? '',
            'date': reservation['date'],
            'time': reservation['time'] ?? '',
            'created_at': DateTime.now().toIso8601String(),
            'is_read': false,
          };

          notifications.add(jsonEncode(notificationData));
          await prefs.setStringList('admin_notifications', notifications);

          print(
              '✅ نوتیفیکیشن برای ادمین ذخیره شد: ${reservation['customer_name']} - ${reservation['service']}');
        } catch (e) {
          print('⚠️ خطا در ذخیره نوتیفیکیشن: $e');
        }
      }

      // بستن لودینگ
      if (mounted) Navigator.pop(context);

      // نمایش پیام موفقیت
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رزرو با موفقیت لغو شد'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // بارگذاری مجدد لیست رزروها
      await _fetchTodayReservations();

      // بارگذاری مجدد خدمات بر اساس رزروهای جدید
      _loadServicesFromReservations();
    } catch (e) {
      // بستن لودینگ در صورت خطا
      if (mounted) Navigator.pop(context);

      print('❌ خطا در لغو رزرو: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در لغو رزرو: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      case 'user_cancelled':
      case 'لغو شده توسط شما':
        return Colors.deepOrange; // رنگ متفاوت برای لغو شده توسط کاربر
      case 'admin_cancelled':
      case 'لغو شده توسط ادمین':
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
      case 'user_cancelled':
        return 'لغو شده توسط شما';
      case 'admin_cancelled':
        return 'لغو شده توسط ادمین';
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
                  // فیلترها
                  _buildFilters(),
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
                  else if (filteredReservations.isEmpty)
                    const Center(
                      child: Text(
                        'هیچ رزروی با فیلتر انتخابی یافت نشد',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredReservations.length,
                      itemBuilder: (context, index) {
                        final reservation = filteredReservations[index];
                        final canDelete = _canDeleteReservation(reservation);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ردیف اول: نام خدمت و وضعیت
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        reservation['service'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                            reservation['status']),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusText(reservation['status']),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // اطلاعات رزرو
                                Text(
                                    'مدل: ${reservation['model']?['name'] ?? ''}'),
                                Text(
                                    'تاریخ: ${_convertToPersianDate(reservation['date'])}'),
                                Text('ساعت: ${reservation['time'] ?? ''}'),

                                const SizedBox(height: 12),

                                // دکمه حذف رزرو
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: canDelete
                                        ? () =>
                                            _showDeleteConfirmation(reservation)
                                        : null,
                                    icon: Icon(
                                      canDelete ? Icons.delete : Icons.block,
                                      size: 18,
                                    ),
                                    label: Text(
                                      canDelete ? 'حذف رزرو' : 'قابل حذف نیست',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          canDelete ? Colors.red : Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'فیلتر رزروها:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // ردیف اول: فیلتر خدمت
          Row(
            children: [
              const Text('خدمت: ', style: TextStyle(fontSize: 14)),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedService,
                  items: services.map((service) {
                    return DropdownMenuItem<String>(
                      value: service['label'],
                      child: Text(service['label'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedService = newValue ?? 'همه خدمات';
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ردیف دوم: فیلتر وضعیت و تاریخ
          Row(
            children: [
              // فیلتر وضعیت
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('وضعیت: ', style: TextStyle(fontSize: 14)),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedStatus,
                      items: const [
                        DropdownMenuItem(value: 'همه', child: Text('همه')),
                        DropdownMenuItem(
                            value: 'در انتظار', child: Text('در انتظار')),
                        DropdownMenuItem(
                            value: 'تایید شده', child: Text('تایید شده')),
                        DropdownMenuItem(
                            value: 'لغو شده', child: Text('لغو شده')),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedStatus = newValue ?? 'همه';
                        });
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // فیلتر تاریخ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تاریخ: ', style: TextStyle(fontSize: 14)),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedDateRange,
                      items: const [
                        DropdownMenuItem(value: 'همه', child: Text('همه')),
                        DropdownMenuItem(value: 'امروز', child: Text('امروز')),
                        DropdownMenuItem(
                            value: 'این هفته', child: Text('این هفته')),
                        DropdownMenuItem(
                            value: 'این ماه', child: Text('این ماه')),
                        DropdownMenuItem(
                            value: 'ماه انتخابی', child: Text('انتخاب ماه')),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue == 'ماه انتخابی') {
                          _selectMonth();
                        } else {
                          setState(() {
                            selectedDateRange = newValue ?? 'همه';
                            if (newValue != 'ماه انتخابی') {
                              selectedMonth = null;
                              selectedMonthDisplay = '';
                            }
                          });
                          _applyFilters();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // نمایش ماه انتخابی
          if (selectedDateRange == 'ماه انتخابی' &&
              selectedMonthDisplay.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month,
                      size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'ماه انتخابی: $selectedMonthDisplay',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _selectMonth,
                    child: const Icon(Icons.edit, size: 16, color: Colors.blue),
                  ),
                ],
              ),
            ),
        ],
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
