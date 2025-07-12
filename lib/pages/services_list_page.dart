import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/utils/custom_page_transition.dart';
import 'package:flutter_application_1/models/reservation_data.dart';
import 'package:flutter_application_1/utils/responsive_helper.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class ServicesListPage extends StatefulWidget {
  final bool isLoggedIn;

  const ServicesListPage({
    super.key,
    required this.isLoggedIn,
  });

  @override
  State<ServicesListPage> createState() => _ServicesListPageState();
}

class _ServicesListPageState extends State<ServicesListPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> servicesList = [];
  bool isLoading = true;
  int columns = 2;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadServices();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // فرمت کردن قیمت با جداکننده هزارگان
  String formatPrice(dynamic price) {
    if (price == null) return '0';
    final formatter = NumberFormat('#,###');
    return formatter.format(int.tryParse(price.toString()) ?? 0);
  }

  // تابع تبدیل عدد روز هفته به نام فارسی
  String getPersianWeekDay(int weekDay) {
    switch (weekDay) {
      case 1:
        return 'شنبه';
      case 2:
        return 'یکشنبه';
      case 3:
        return 'دوشنبه';
      case 4:
        return 'سه‌شنبه';
      case 5:
        return 'چهارشنبه';
      case 6:
        return 'پنج‌شنبه';
      case 7:
        return 'جمعه';
      default:
        return '';
    }
  }

  Future<void> _loadServices() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      // گام اول: دریافت لیست یکتای service_idهایی که مدل دارند
      final modelServiceIdsResponse =
          await SupabaseConfig.client.from('models').select('service_id');
      final ids =
          modelServiceIdsResponse.map((m) => m['service_id']).toSet().toList();
      print('service ids with model:');
      print(ids);

      // گام دوم: دریافت خدماتی که id آن‌ها در ids است
      final response = await SupabaseConfig.client
          .from('services')
          .select()
          .inFilter('id', ids)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        servicesList = List<Map<String, dynamic>>.from(response);
        columns = _calculateColumns();
        isLoading = false;
      });

      // شروع انیمیشن بعد از لود شدن داده‌ها
      if (mounted) {
        _fadeController.forward();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('خطا در بارگذاری خدمات: $e');
    }
  }

  int _calculateColumns() {
    final screenWidth = ResponsiveHelper.screenWidth(context);

    // بر اساس عرض صفحه تعداد کاشی‌ها را تعیین کن
    if (screenWidth >= 1200) return 5; // خیلی بزرگ - 5 کاشی
    if (screenWidth >= 900) return 4; // بزرگ - 4 کاشی
    if (screenWidth >= 600) return 3; // متوسط/تبلت - 3 کاشی
    if (screenWidth >= 400) return 2; // موبایل متوسط - 2 کاشی
    return 1; // موبایل کوچک - 1 کاشی
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.statusCancelledColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.primaryLightColor2,
        ),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            if (isLoading)
              _buildLoadingSliver()
            else if (servicesList.isEmpty)
              _buildEmptyStateSliver()
            else
              _buildServicesGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'خدمات سالن زیبایی',
          style: AppTheme.titleStyle.copyWith(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadServices,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'در حال بارگذاری خدمات...',
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.spa_outlined,
                    size: 80,
                    color: AppTheme.primaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'خدمتی موجود نیست',
                    style: AppTheme.subtitleStyle,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'در حال حاضر هیچ خدمتی برای رزرو موجود نمی‌باشد',
                    style: AppTheme.captionStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadServices,
                    icon: const Icon(Icons.refresh),
                    label: const Text('تلاش مجدد'),
                    style: AppTheme.primaryButtonStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return SliverPadding(
      padding: EdgeInsets.all(
          AppTheme.paddingSmall(context) * 2), // کوچک‌تر کردن padding
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing:
              AppTheme.paddingSmall(context) * 1.5, // کوچک‌تر کردن spacing
          mainAxisSpacing: AppTheme.paddingSmall(context) * 1.5,
          childAspectRatio: 0.9, // کمی بلندتر کردن کارت‌ها
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildServiceCard(servicesList[index], index),
            );
          },
          childCount: servicesList.length,
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: _ServiceCard(
            service: service,
            onTap: () => _onServiceSelected(service),
          ),
        );
      },
    );
  }

  void _onServiceSelected(Map<String, dynamic> service) async {
    await _showModelsDialog(service);
  }

  Future<void> _showModelsDialog(Map<String, dynamic> service) async {
    // نمایش لودینگ بهتر
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'در حال بارگذاری مدل‌های ${service['label']}...',
                style: AppTheme.bodyStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    // دریافت مدل‌های مربوط به این خدمت
    List<Map<String, dynamic>> serviceModels = [];
    try {
      print(
          '🔍 شروع جستجوی مدل‌ها برای خدمت: ${service['label']} با ID: ${service['id']}');

      // ابتدا تمام مدل‌ها را دریافت کنیم تا ببینیم چه داده‌هایی موجود است
      final allModelsResponse =
          await SupabaseConfig.client.from('models').select();

      print('📊 تمام مدل‌های موجود در دیتابیس: $allModelsResponse');

      // حالا مدل‌های مربوط به این خدمت را فیلتر کنیم
      // تبدیل ID به int در صورت نیاز
      final serviceId = service['id'];
      final searchId = serviceId is String
          ? int.tryParse(serviceId) ?? serviceId
          : serviceId;

      print('🔍 serviceId اصلی: $serviceId (نوع: ${serviceId.runtimeType})');
      print('🔍 searchId تبدیل شده: $searchId (نوع: ${searchId.runtimeType})');

      // ابتدا بدون فیلتر کوئری کنیم
      final allModelsForDebug =
          await SupabaseConfig.client.from('models').select();
      print('🔍 تمام مدل‌ها: $allModelsForDebug');

      // حالا با فیلتر
      final response = await SupabaseConfig.client
          .from('models')
          .select()
          .eq('service_id', searchId);

      print('🎯 مدل‌های فیلتر شده برای service_id $searchId: $response');

      serviceModels = List<Map<String, dynamic>>.from(response);
      print('✅ تعداد مدل‌های یافت شده: ${serviceModels.length}');

      // اگر مدلی یافت نشد، بیایید با تمام انواع ممکن جستجو کنیم
      if (serviceModels.isEmpty) {
        print('⚠️ هیچ مدلی یافت نشد. تلاش مجدد با انواع مختلف...');

        // تلاش با String
        if (searchId is! String) {
          final stringResponse = await SupabaseConfig.client
              .from('models')
              .select()
              .eq('service_id', searchId.toString());
          print('🔍 جستجو با String: $stringResponse');

          if (stringResponse.isNotEmpty) {
            serviceModels = List<Map<String, dynamic>>.from(stringResponse);
            print('✅ با String یافت شد: ${serviceModels.length} مدل');
          }
        }

        // تلاش با int
        if (serviceModels.isEmpty && searchId is! int) {
          final intValue = int.tryParse(searchId.toString());
          if (intValue != null) {
            final intResponse = await SupabaseConfig.client
                .from('models')
                .select()
                .eq('service_id', intValue);
            print('🔍 جستجو با int: $intResponse');

            if (intResponse.isNotEmpty) {
              serviceModels = List<Map<String, dynamic>>.from(intResponse);
              print('✅ با int یافت شد: ${serviceModels.length} مدل');
            }
          }
        }
      }
    } catch (e) {
      print('❌ خطا در دریافت مدل‌ها: $e');
      if (mounted) {
        Navigator.pop(context); // بستن لودینگ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بارگذاری مدل‌ها: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.pop(context); // بستن لودینگ

    // نمایش دیالوگ انتخاب مدل
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('انتخاب مدل ${service['label']}'),
          content: SizedBox(
            width: double.maxFinite,
            height: serviceModels.isEmpty ? 200 : 400,
            child: serviceModels.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      const Text('مدلی برای این خدمت ثبت نشده است.'),
                      const SizedBox(height: 16),
                      Text(
                        'ID خدمت: ${service['id']} (نوع: ${service['id'].runtimeType})\nنام خدمت: ${service['label']}\n\nبرای مشاهده اطلاعات تکمیلی روی دکمه زیر کلیک کنید.',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: serviceModels.length,
                    itemBuilder: (context, index) {
                      final model = serviceModels[index];
                      return _buildModelListTile(model, service);
                    },
                  ),
          ),
          actions: [
            if (serviceModels.isEmpty)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showDebugInfo(service);
                },
                child: const Text('اطلاعات تکمیلی'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('بستن'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModelListTile(
      Map<String, dynamic> model, Map<String, dynamic> service) {
    // تبدیل امن مقادیر
    final String modelName = (model['name'] ?? 'مدل').toString();
    final String duration = (model['duration'] ?? 'مدت زمان نامشخص').toString();
    final String price = (model['price'] ?? 0).toString();
    final String description = (model['description'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          modelName,
          style: AppTheme.subtitleStyle.copyWith(fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('$duration دقیقه'),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${formatPrice(model['price'])} تومان',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pop(context); // بستن دیالوگ
          _onModelSelected(model, service);
        },
      ),
    );
  }

  void _onModelSelected(
      Map<String, dynamic> model, Map<String, dynamic> service) {
    // اطمینان از تبدیل امن داده‌ها قبل از انتقال
    final cleanModel = {
      'id': model['id'],
      'name': (model['name'] ?? 'مدل نامشخص').toString(),
      'price': model['price'] ?? 0,
      'duration': (model['duration'] ?? 'نامشخص').toString(),
      'description': (model['description'] ?? '').toString(),
      'service_id': model['service_id'],
    };

    final cleanService = {
      'id': service['id'],
      'label': (service['label'] ?? 'خدمت نامشخص').toString(),
      'description': (service['description'] ?? '').toString(),
    };

    print('📤 انتقال داده‌ها:');
    print('Service: $cleanService');
    print('Model: $cleanModel');

    // مستقیماً تقویم را باز کن
    _selectDateForModel(cleanService, cleanModel);
  }

  Future<void> _selectDateForModel(
      Map<String, dynamic> service, Map<String, dynamic> model) async {
    final now = Jalali.now();
    final lastDate = now.addDays(30);

    final Jalali? picked = await showPersianDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: lastDate,
      initialEntryMode: PDatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.pinkAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      print(
          '📅 تاریخ انتخاب شده: ${picked.year}/${picked.month}/${picked.day}');

      // مستقیماً دیالوگ انتخاب ساعت را نمایش دهیم
      await _showTimeSelectionDialog(picked, service, model);
    }
  }

  Future<void> _showTimeSelectionDialog(Jalali selectedDate,
      Map<String, dynamic> service, Map<String, dynamic> model) async {
    print('شروع دریافت ساعت‌های آزاد برای مدل: $model');

    // نمایش لودینگ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('بررسی ساعت‌های آزاد...'),
          ],
        ),
      ),
    );

    // لیست ساعت‌های پایه
    final List<String> baseTimes = [
      '09:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00'
    ];

    final dateIso =
        selectedDate.toDateTime().toIso8601String().substring(0, 10);
    print('dateIso: $dateIso');
    print('service: ${service['label']}');
    print('model_id: ${model['id']}');

    try {
      print(
          'دریافت رزروها برای تاریخ: $dateIso, خدمت: ${service['id']}, مدل: ${model['id']}');
      final reservations = await SupabaseConfig.client
          .from('reservations')
          .select()
          .eq('date', dateIso)
          .eq('service_id', service['id'])
          .eq('model_id', model['id'])
          .or('status.eq.pending,status.eq.confirmed,status.eq.در انتظار,status.eq.تایید شده');

      print('رزروهای دریافت شده برای این خدمت و مدل: $reservations');
      final List<dynamic> reservationList = reservations ?? [];
      print('تعداد رزروهای موجود: ${reservationList.length}');

      // تابع کمکی برای نرمال کردن فرمت ساعت
      String normalizeTime(String t) {
        final parts = t.split(':');
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }

      // فیلتر کردن ساعت‌های رزرو شده
      final reservedTimes = reservationList
          .where((r) =>
              ['pending', 'confirmed', 'در انتظار', 'تایید شده']
                  .contains(r['status']) &&
              r['time'] != null)
          .map<String>((r) {
        print('رزرو با زمان: ${r['time']} - نوع: ${r['time'].runtimeType}');
        return normalizeTime(r['time'].toString());
      }).toList();

      print('ساعت‌های رزرو شده: $reservedTimes');

      // حذف زمان‌های رزرو شده از لیست زمان‌های پایه
      final availableTimes = baseTimes.where((t) {
        final normalizedBaseTime = normalizeTime(t);
        final isAvailable = !reservedTimes.contains(normalizedBaseTime);
        print(
            'ساعت $normalizedBaseTime ${isAvailable ? "آزاد است" : "رزرو شده است"}');
        return isAvailable;
      }).toList();

      print('ساعت‌های آزاد: $availableTimes');

      if (!mounted) return;
      Navigator.pop(context); // بستن لودینگ

      // نمایش دیالوگ انتخاب ساعت
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('انتخاب ساعت'),
            content: SizedBox(
              width: double.maxFinite,
              child: availableTimes.isEmpty
                  ? const Text('همه‌ی ساعت‌های این روز رزرو شده‌اند.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: baseTimes.map((time) {
                        final normalizedTime = normalizeTime(time);
                        final isReserved =
                            reservedTimes.contains(normalizedTime);
                        return ElevatedButton(
                          onPressed: isReserved
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _goToReservationPage(
                                      selectedDate, service, model, time);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isReserved
                                ? Colors.grey
                                : AppTheme.primaryColor,
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                time,
                                style: TextStyle(
                                  color: isReserved
                                      ? Colors.grey.shade600
                                      : Colors.white,
                                ),
                              ),
                              if (isReserved)
                                const Text(
                                  '(رزرو شده)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بستن'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('خطا در دریافت رزروها: $e');
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در دریافت ساعت‌های آزاد: $e')),
      );
    }
  }

  void _goToReservationPage(Jalali selectedDate, Map<String, dynamic> service,
      Map<String, dynamic> model, String time) async {
    // نمایش دیالوگ تایید نهایی
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تایید نهایی رزرو'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('سرویس: ${service['label']}'),
              const SizedBox(height: 8),
              Text('مدل: ${model['name']}'),
              const SizedBox(height: 8),
              Text('قیمت: ${formatPrice(model['price'])} تومان'),
              const SizedBox(height: 8),
              Text(
                  'تاریخ: ${selectedDate.year}/${selectedDate.month}/${selectedDate.day} (${getPersianWeekDay(selectedDate.weekDay)})'),
              const SizedBox(height: 8),
              Text('ساعت: $time'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تایید'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final reservationData = ReservationData(
        date: selectedDate,
        service: service['label'].toString(),
        model: {
          ...model,
          'time': time.toString(),
          'name': model['name'].toString(),
          'price': model['price'].toString(),
          'duration': model['duration'].toString(),
          'service_id': service['id']
              .toString(), // استفاده از service['id'] به جای model['service_id']
          'model_id': model['id'].toString(),
        },
      );

      Navigator.pushNamed(
        context,
        '/reservation',
        arguments: reservationData,
      );
    }
  }

  void _showDebugInfo(Map<String, dynamic> service) async {
    try {
      // دریافت تمام خدمات
      final allServices = await SupabaseConfig.client.from('services').select();

      // دریافت تمام مدل‌ها
      final allModels = await SupabaseConfig.client.from('models').select();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('اطلاعات Debug'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'خدمت انتخاب شده:',
                      style: AppTheme.subtitleStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID: ${service['id']} (نوع: ${service['id'].runtimeType})\nLabel: ${service['label']}\nDescription: ${service['description'] ?? "ندارد"}',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    const Divider(height: 32),
                    const Text(
                      'تمام خدمات موجود:',
                      style: AppTheme.subtitleStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      allServices.toString(),
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12),
                    ),
                    const Divider(height: 32),
                    const Text(
                      'تمام مدل‌های موجود:',
                      style: AppTheme.subtitleStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      allModels.toString(),
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بستن'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در دریافت اطلاعات debug: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFullDatabaseDebug() async {
    // نمایش لودینگ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('در حال بررسی دیتابیس...'),
            ],
          ),
        );
      },
    );

    try {
      print('🔍 شروع بررسی کامل دیتابیس...');

      // 1. تست اتصال به services
      print('1️⃣ بررسی جدول services...');
      final servicesResponse =
          await SupabaseConfig.client.from('services').select();
      print('✅ Services موفق: ${servicesResponse.length} رکورد');
      print('📊 محتویات services: $servicesResponse');

      // 2. تست اتصال به models
      print('2️⃣ بررسی جدول models...');
      final modelsResponse =
          await SupabaseConfig.client.from('models').select();
      print('✅ Models موفق: ${modelsResponse.length} رکورد');
      print('📊 محتویات models: $modelsResponse');

      // 3. بررسی ساختار جدول models
      print('3️⃣ بررسی ساختار models...');
      if (modelsResponse.isNotEmpty) {
        final firstModel = modelsResponse[0];
        print('🔍 فیلدهای موجود در models: ${firstModel.keys.toList()}');
        firstModel.forEach((key, value) {
          print('   $key: $value (${value.runtimeType})');
        });
      }

      // 4. بررسی ساختار جدول services
      print('4️⃣ بررسی ساختار services...');
      if (servicesResponse.isNotEmpty) {
        final firstService = servicesResponse[0];
        print('🔍 فیلدهای موجود در services: ${firstService.keys.toList()}');
        firstService.forEach((key, value) {
          print('   $key: $value (${value.runtimeType})');
        });
      }

      if (!mounted) return;
      Navigator.pop(context); // بستن لودینگ

      // نمایش نتایج
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('گزارش کامل دیتابیس'),
            content: SizedBox(
              width: double.maxFinite,
              height: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // خلاصه
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📊 خلاصه:',
                              style: AppTheme.subtitleStyle),
                          Text('خدمات: ${servicesResponse.length} عدد'),
                          Text('مدل‌ها: ${modelsResponse.length} عدد'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // جدول خدمات
                    const Text('🏪 جدول Services:',
                        style: AppTheme.subtitleStyle),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        servicesResponse.toString(),
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // جدول مدل‌ها
                    const Text('⭐ جدول Models:', style: AppTheme.subtitleStyle),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        modelsResponse.toString(),
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // تحلیل روابط
                    const Text('🔗 تحلیل روابط:',
                        style: AppTheme.subtitleStyle),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var service in servicesResponse)
                            ...() {
                              final relatedModels = modelsResponse
                                  .where((model) =>
                                      model['service_id'].toString() ==
                                      service['id'].toString())
                                  .toList();
                              return [
                                Text(
                                    '${service['label']} (ID: ${service['id']}): ${relatedModels.length} مدل'),
                                if (relatedModels.isNotEmpty)
                                  for (var model in relatedModels)
                                    Text(
                                        '  • ${model['name']} - ${model['price']} تومان',
                                        style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                              ];
                            }(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بستن'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('❌ خطای کلی: $e');
      if (mounted) {
        Navigator.pop(context); // بستن لودینگ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در بررسی دیتابیس: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onTap;

  const _ServiceCard({
    Key? key,
    required this.service,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // محاسبه اندازه فونت بر اساس عرض کاشی
    final screenWidth = ResponsiveHelper.screenWidth(context);
    double cardFontSize;

    if (screenWidth >= 1200) {
      cardFontSize =
          AppTheme.fontLarge(context) * 1.5; // برای 5 کاشی - بزرگ‌تر شد
    } else if (screenWidth >= 900) {
      cardFontSize =
          AppTheme.fontLarge(context) * 1.6; // برای 4 کاشی - بزرگ‌تر شد
    } else if (screenWidth >= 600) {
      cardFontSize =
          AppTheme.fontMedium(context) * 1.7; // برای 3 کاشی - همون قبل
    } else if (screenWidth >= 400) {
      cardFontSize =
          AppTheme.fontMedium(context) * 1.6; // برای 2 کاشی - همون قبل
    } else {
      cardFontSize = AppTheme.fontLarge(context); // برای 1 کاشی - همون قبل
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.paddingMedium(context)),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius:
                BorderRadius.circular(AppTheme.paddingMedium(context)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                top: -15,
                right: -15,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentColor.withOpacity(0.1),
                  ),
                ),
              ),
              // Content - کاملاً وسط‌چین
              Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.paddingSmall(context) * 2),
                  child: Text(
                    service['label'] ?? 'خدمت',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: cardFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                      letterSpacing: -0.3,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
