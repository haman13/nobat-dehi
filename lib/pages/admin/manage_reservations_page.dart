// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class ManageReservationsPage extends StatefulWidget {
  const ManageReservationsPage({super.key});

  @override
  State<ManageReservationsPage> createState() => _ManageReservationsPageState();
}

class _ManageReservationsPageState extends State<ManageReservationsPage> {
  List<dynamic> originalData = [];
  List<dynamic> filteredData = [];
  List<String> availableServices = ['همه خدمات'];
  bool _isLoading = true;
  String? _error;

  // فیلترهای پیشرفته
  String selectedService = 'همه خدمات';
  String selectedStatus = 'همه';
  String selectedDateFilter = 'همه';
  int selectedYear = 1403;
  int selectedMonth = 1;

  final List<String> persianMonths = [
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

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
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

      // بارگذاری خدمات از دیتابیس
      final servicesResponse =
          await SupabaseConfig.client.from('services').select('id, label');

      final services = servicesResponse
          .map((service) => service['label'] as String)
          .toList();

      setState(() {
        originalData = reservationsResponse;
        availableServices = ['همه خدمات', ...services];
        filteredData = List.from(originalData);
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        _error = 'خطا در بارگذاری رزروها: $e';
        _isLoading = false;
      });
      print('خطا در بارگذاری رزروها: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      filteredData = originalData.where((reservation) {
        // فیلتر خدمات
        if (selectedService != 'همه خدمات') {
          final serviceName = reservation['services']?['label'] ?? '';
          if (serviceName != selectedService) {
            return false;
          }
        }

        // فیلتر وضعیت
        if (selectedStatus != 'همه') {
          String reservationStatus = reservation['status'] ?? 'در انتظار';
          // تبدیل وضعیت‌های انگلیسی به فارسی
          switch (reservationStatus) {
            case 'pending':
              reservationStatus = 'در انتظار';
              break;
            case 'confirmed':
              reservationStatus = 'تأیید شده';
              break;
            case 'cancelled':
              reservationStatus = 'لغو شده';
              break;
            case 'user_cancelled':
              reservationStatus = '🔔 لغو شده توسط کاربر';
              break;
            case 'admin_cancelled':
              reservationStatus = 'لغو شده';
              break;
          }
          if (reservationStatus != selectedStatus) {
            return false;
          }
        }

        // فیلتر تاریخ
        if (selectedDateFilter != 'همه') {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final reservationDate = DateTime.parse(reservation['date']);
          final reservationDateOnly = DateTime(
            reservationDate.year,
            reservationDate.month,
            reservationDate.day,
          );

          switch (selectedDateFilter) {
            case 'امروز':
              if (reservationDateOnly != today) return false;
              break;
            case 'این هفته':
              final weekStart =
                  today.subtract(Duration(days: today.weekday - 1));
              final weekEnd = weekStart.add(const Duration(days: 6));
              if (reservationDateOnly.isBefore(weekStart) ||
                  reservationDateOnly.isAfter(weekEnd)) {
                return false;
              }
              break;
            case 'این ماه':
              if (reservationDateOnly.year != today.year ||
                  reservationDateOnly.month != today.month) {
                return false;
              }
              break;
            case 'ماه انتخابی':
              final targetYear = selectedYear;
              final targetMonth = selectedMonth;

              // تبدیل تاریخ شمسی به میلادی (تقریبی)
              final gregorianYear = targetYear + 621;
              final gregorianMonth =
                  targetMonth <= 6 ? targetMonth + 3 : targetMonth - 6;
              final adjustedYear =
                  targetMonth <= 6 ? gregorianYear : gregorianYear + 1;

              if (reservationDateOnly.year != adjustedYear ||
                  (reservationDateOnly.month - gregorianMonth).abs() > 1) {
                return false;
              }
              break;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _updateReservationStatus(
      dynamic reservation, String newStatus) async {
    try {
      // تبدیل وضعیت فارسی به انگلیسی برای دیتابیس
      String dbStatus = newStatus;
      switch (newStatus) {
        case 'در انتظار':
          dbStatus = 'pending';
          break;
        case 'تأیید شده':
          dbStatus = 'confirmed';
          break;
        case 'لغو شده':
          dbStatus = 'cancelled';
          break;
        case 'لغو شده از سمت ادمین':
          dbStatus = 'admin_cancelled';
          break;
      }

      await SupabaseConfig.client
          .from('reservations')
          .update({'status': dbStatus}).eq('id', reservation['id']);

      await _loadReservations();

      // نمایش پیام موفقیت
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('وضعیت رزرو به "$newStatus" تغییر یافت'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در تغییر وضعیت: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMonthPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتخاب ماه'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: selectedYear,
                decoration: const InputDecoration(
                  labelText: 'سال',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(11, (index) {
                  final year = 1400 + index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    selectedYear = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedMonth,
                decoration: const InputDecoration(
                  labelText: 'ماه',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(12, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(persianMonths[index]),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                selectedDateFilter = 'ماه انتخابی';
              });
              _applyFilters();
            },
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
  }

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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'user_cancelled':
        return Colors.deepOrange; // رنگ خاص برای لغو توسط کاربر
      case 'admin_cancelled':
        return Colors.red;
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
      return gregorianDate; // در صورت خطا همان تاریخ اصلی را نمایش بده
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت رزروها'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryLightColor3,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservations,
            tooltip: 'بروزرسانی',
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
                        onPressed: _loadReservations,
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // فیلترهای پیشرفته
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedService,
                                  decoration: const InputDecoration(
                                    labelText: 'خدمت',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.category),
                                  ),
                                  items: availableServices.map((service) {
                                    return DropdownMenuItem(
                                      value: service,
                                      child: Text(service),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedService = value!;
                                    });
                                    _applyFilters();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedStatus,
                                  decoration: const InputDecoration(
                                    labelText: 'وضعیت',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.info),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'همه', child: Text('همه')),
                                    DropdownMenuItem(
                                        value: 'در انتظار',
                                        child: Text('در انتظار')),
                                    DropdownMenuItem(
                                        value: 'تأیید شده',
                                        child: Text('تأیید شده')),
                                    DropdownMenuItem(
                                        value: 'لغو شده',
                                        child: Text('لغو شده')),
                                    DropdownMenuItem(
                                        value: '🔔 لغو شده توسط کاربر',
                                        child: Text('🔔 لغو شده توسط کاربر')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedStatus = value!;
                                    });
                                    _applyFilters();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedDateFilter,
                                  decoration: const InputDecoration(
                                    labelText: 'بازه زمانی',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.date_range),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'همه', child: Text('همه')),
                                    DropdownMenuItem(
                                        value: 'امروز', child: Text('امروز')),
                                    DropdownMenuItem(
                                        value: 'این هفته',
                                        child: Text('این هفته')),
                                    DropdownMenuItem(
                                        value: 'این ماه',
                                        child: Text('این ماه')),
                                    DropdownMenuItem(
                                        value: 'ماه انتخابی',
                                        child: Text('ماه انتخابی')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedDateFilter = value!;
                                    });
                                    if (value == 'ماه انتخابی') {
                                      _showMonthPicker();
                                    } else {
                                      _applyFilters();
                                    }
                                  },
                                ),
                              ),
                              if (selectedDateFilter == 'ماه انتخابی') ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_month,
                                            color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'ماه انتخابی: ${persianMonths[selectedMonth - 1]} $selectedYear',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        IconButton(
                                          icon:
                                              const Icon(Icons.edit, size: 20),
                                          onPressed: _showMonthPicker,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // نمایش تعداد نتایج
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Colors.blue[50],
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${filteredData.length} رزرو یافت شد',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // لیست رزروها
                    Expanded(
                      child: filteredData.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('هیچ رزروی با این فیلترها یافت نشد'),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadReservations,
                              child: ListView.builder(
                                itemCount: filteredData.length,
                                itemBuilder: (context, index) {
                                  final reservation = filteredData[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ExpansionTile(
                                      title: Text(
                                        reservation['services']?['label'] ??
                                            'خدمت نامشخص',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                              'نام: ${reservation['customer_name'] ?? 'نامشخص'}'),
                                          Text(
                                              '${_convertToPersianDate(reservation['date'])} - ${reservation['time'] ?? ''}'),
                                        ],
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                              reservation['status'] ??
                                                  'pending'),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusText(
                                              reservation['status'] ??
                                                  'pending'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.person,
                                                      size: 16,
                                                      color: Colors.grey),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                      child: Text(
                                                          'نام: ${reservation['customer_name'] ?? 'نامشخص'}')),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.phone,
                                                      size: 16,
                                                      color: Colors.grey),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                      child: Text(
                                                          'تلفن: ${reservation['customer_phone'] ?? 'نامشخص'}')),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.category,
                                                      size: 16,
                                                      color: Colors.grey),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                      child: Text(
                                                          'مدل: ${reservation['models']?['name'] ?? 'نامشخص'}')),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.payments,
                                                      size: 16,
                                                      color: Colors.grey),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                      child: Text(
                                                          'قیمت: ${reservation['models']?['price'] ?? 0} تومان')),
                                                ],
                                              ),
                                              if (reservation['notes'] !=
                                                      null &&
                                                  reservation['notes']
                                                      .toString()
                                                      .isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.note,
                                                        size: 16,
                                                        color: Colors.grey),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                        child: Text(
                                                            'یادداشت: ${reservation['notes']}')),
                                                  ],
                                                ),
                                              ],
                                              const SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  if (reservation['status'] !=
                                                          'cancelled' &&
                                                      reservation['status'] !=
                                                          'user_cancelled' &&
                                                      reservation['status'] !=
                                                          'admin_cancelled') ...[
                                                    if (reservation['status'] !=
                                                        'confirmed')
                                                      Expanded(
                                                        child:
                                                            ElevatedButton.icon(
                                                          onPressed: () =>
                                                              _updateReservationStatus(
                                                                  reservation,
                                                                  'تأیید شده'),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors.green,
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                          icon: const Icon(
                                                              Icons.check,
                                                              size: 16),
                                                          label: const Text(
                                                              'تأیید'),
                                                        ),
                                                      ),
                                                    if (reservation['status'] !=
                                                        'confirmed')
                                                      const SizedBox(width: 12),
                                                    Expanded(
                                                      child:
                                                          ElevatedButton.icon(
                                                        onPressed: () =>
                                                            _updateReservationStatus(
                                                                reservation,
                                                                'لغو شده از سمت ادمین'),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                          foregroundColor:
                                                              Colors.white,
                                                        ),
                                                        icon: const Icon(
                                                            Icons.cancel,
                                                            size: 16),
                                                        label:
                                                            const Text('لغو'),
                                                      ),
                                                    ),
                                                  ] else ...[
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[200],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(Icons.block,
                                                              color: Colors
                                                                  .grey[600],
                                                              size: 16),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                            'رزرو لغو شده',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .grey[600]),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
