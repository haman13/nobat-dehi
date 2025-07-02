import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<dynamic> allReservations = [];
  String selectedReportType = 'درآمد';
  bool _isLoading = true;
  String? _error;

  // متغیرهای فیلتر تاریخ
  String selectedDateRange = 'همه';
  String? selectedMonth; // فرمت: "1403/08"
  String selectedMonthDisplay = ''; // برای نمایش: "آبان 1403"

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

      // بارگذاری رزروها از دیتابیس با اطلاعات مدل‌ها و خدمات
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

      setState(() {
        allReservations = reservationsResponse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'خطا در بارگذاری گزارش‌ها: $e';
        _isLoading = false;
      });
      print('خطا در بارگذاری گزارش‌ها: $e');
    }
  }

  // تابع فرمت کردن عدد با جداسازی سه رقمی
  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return formatter.format(amount);
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

  // فیلتر رزروها بر اساس تاریخ
  List<dynamic> get filteredReservations {
    if (selectedDateRange == 'همه') {
      return allReservations;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return allReservations.where((reservation) {
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
            final weekStart = today.subtract(Duration(days: today.weekday - 1));
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

  Map<String, dynamic> get reportData {
    final reservations = filteredReservations;

    if (reservations.isEmpty) {
      return {
        'totalIncome': 0,
        'totalReservations': 0,
        'completedReservations': 0,
        'cancelledReservations': 0,
        'pendingReservations': 0,
        'serviceIncome': <String, int>{},
      };
    }

    // محاسبه آمار
    final totalReservations = reservations.length;

    final completedReservations =
        reservations.where((r) => r['status'] == 'confirmed').length;

    final cancelledReservations = reservations
        .where((r) =>
            r['status'] == 'cancelled' || r['status'] == 'admin_cancelled')
        .length;

    final pendingReservations =
        reservations.where((r) => r['status'] == 'pending').length;

    // محاسبه درآمد کل (فقط رزروهای تأیید شده)
    final totalIncome = reservations
        .where((r) => r['status'] == 'confirmed')
        .fold(0, (sum, r) => sum + (r['models']?['price'] ?? 0) as int);

    // محاسبه درآمد به تفکیک خدمات
    final serviceIncome = <String, int>{};
    for (var reservation
        in reservations.where((r) => r['status'] == 'confirmed')) {
      final serviceName = reservation['services']?['label'] ?? 'نامشخص';
      final price = reservation['models']?['price'] ?? 0;
      serviceIncome[serviceName] =
          (serviceIncome[serviceName] ?? 0) + price as int;
    }

    return {
      'totalIncome': totalIncome,
      'totalReservations': totalReservations,
      'completedReservations': completedReservations,
      'cancelledReservations': cancelledReservations,
      'pendingReservations': pendingReservations,
      'serviceIncome': serviceIncome,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارش‌ها'),
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
                    // انتخاب نوع گزارش و فیلتر تاریخ
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: Column(
                        children: [
                          // نوع گزارش
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedReportType,
                                  decoration: const InputDecoration(
                                    labelText: 'نوع گزارش',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.assessment),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'درآمد',
                                        child: Text('گزارش درآمد')),
                                    DropdownMenuItem(
                                        value: 'رزرو',
                                        child: Text('گزارش رزرو')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedReportType = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // فیلتر تاریخ
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedDateRange,
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
                                        child: Text('انتخاب ماه')),
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
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          // نمایش ماه انتخابی
                          if (selectedDateRange == 'ماه انتخابی' &&
                              selectedMonthDisplay.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_month,
                                        size: 20, color: Colors.blue[700]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'ماه انتخابی: $selectedMonthDisplay',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _selectMonth,
                                      child: Icon(Icons.edit,
                                          size: 18, color: Colors.blue[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // نمایش تعداد کل رزروها
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
                            'مجموع ${filteredReservations.length} رزرو${selectedDateRange != 'همه' ? ' (فیلتر شده از ${allReservations.length} رزرو)' : ' یافت شد'}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // محتوای گزارش
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadReservations,
                        child: selectedReportType == 'درآمد'
                            ? _buildIncomeReport(reportData)
                            : _buildReservationReport(reportData),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildIncomeReport(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            'درآمد کل',
            '${_formatCurrency(data['totalIncome'])} تومان',
            Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            'درآمد به تفکیک خدمات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (data['serviceIncome'].isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'هیچ درآمدی ثبت نشده است',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            ...data['serviceIncome'].entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: const Icon(Icons.attach_money, color: Colors.green),
                  ),
                  title: Text(entry.key),
                  trailing: Text(
                    '${_formatCurrency(entry.value)} تومان',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildReservationReport(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            'کل رزروها',
            data['totalReservations'].toString(),
            Colors.blue,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'تأیید شده',
                  data['completedReservations'].toString(),
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'در انتظار',
                  data['pendingReservations'].toString(),
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'لغو شده',
            data['cancelledReservations'].toString(),
            Colors.red,
          ),

          // نمودار ساده با درصدها
          const SizedBox(height: 24),
          const Text(
            'توزیع وضعیت‌ها',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusChart(data),
        ],
      ),
    );
  }

  Widget _buildStatusChart(Map<String, dynamic> data) {
    final total = data['totalReservations'] as int;
    if (total == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'هیچ رزروی یافت نشد',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    final confirmed = data['completedReservations'] as int;
    final pending = data['pendingReservations'] as int;
    final cancelled = data['cancelledReservations'] as int;

    return Column(
      children: [
        _buildProgressBar('تأیید شده', confirmed, total, Colors.green),
        _buildProgressBar('در انتظار', pending, total, Colors.orange),
        _buildProgressBar('لغو شده', cancelled, total, Colors.red),
      ],
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total * 100).round() : 0;
    final progress = total > 0 ? value / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text('$value ($percentage%)'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
