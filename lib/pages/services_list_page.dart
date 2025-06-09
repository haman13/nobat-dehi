import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/utils/custom_page_transition.dart';
import 'package:flutter_application_1/models/reservation_data.dart';
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

class _ServicesListPageState extends State<ServicesListPage> {
  List<Map<String, dynamic>> servicesList = [];
  bool isLoading = true;
  int columns = 2;

  // فرمت کردن قیمت با جداکننده هزارگان
  String formatPrice(dynamic price) {
    if (price == null) return '0';
    final formatter = NumberFormat('#,###');
    return formatter.format(int.tryParse(price.toString()) ?? 0);
  }

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final response = await SupabaseConfig.client.from('services').select();
      setState(() {
        servicesList = List<Map<String, dynamic>>.from(response);
        columns = servicesList.length <= 5 ? 2 : 3;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگذاری خدمات: $e')),
      );
    }
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
                  'تاریخ: ${selectedDate.year}/${selectedDate.month}/${selectedDate.day}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('انتخاب خدمت'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // لوگو در پس زمینه
                Builder(
                  builder: (context) {
                    final size = MediaQuery.of(context).size;
                    final minSide =
                        size.width < size.height ? size.width : size.height;
                    final logoSize = minSide * 0.4;
                    return Center(
                      child: Opacity(
                        opacity: 0.1,
                        child: AppTheme.getLogo(size: logoSize),
                      ),
                    );
                  },
                ),
                // محتوای اصلی
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'لطفاً خدمت مورد نظر خود را انتخاب کنید:',
                              style: AppTheme.titleStyle.copyWith(fontSize: 20),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showFullDatabaseDebug(),
                            icon: const Icon(Icons.bug_report,
                                color: AppTheme.primaryColor),
                            tooltip: 'بررسی کامل دیتابیس',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: servicesList.isEmpty
                            ? const Center(
                                child: Text(
                                  'هیچ خدمتی ثبت نشده است',
                                  style: AppTheme.bodyStyle,
                                ),
                              )
                            : GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: servicesList.length,
                                itemBuilder: (context, index) {
                                  final service = servicesList[index];
                                  return _buildServiceCard(service);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return GestureDetector(
      onTap: () => _onServiceSelected(service),
      child: Container(
        decoration: AppTheme.cardDecoration.copyWith(
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              service['label'] ?? 'خدمت',
              textAlign: TextAlign.center,
              style: AppTheme.subtitleStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (service['description'] != null &&
                service['description'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  service['description'],
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: 12,
                    color: AppTheme.textPrimaryColor.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
