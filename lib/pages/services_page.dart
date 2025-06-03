import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/models/reservation_data.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class ServicesPage extends StatefulWidget {
  final Jalali selectedDate;
  
  const ServicesPage({
    super.key,
    required this.selectedDate,
  });

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<Map<String, dynamic>> servicesList = [];
  List<Map<String, dynamic>> modelsList = [];
  Map<String, dynamic>? selectedService;
  Map<String, dynamic>? selectedModel;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadModels();
  }

  Future<void> _loadServices() async {
    try {
      final response = await SupabaseConfig.client
          .from('services')
          .select();
      setState(() {
        servicesList = List<Map<String, dynamic>>.from(response);
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

  Future<void> _loadModels() async {
    try {
      final response = await SupabaseConfig.client
          .from('models')
          .select();
      setState(() {
        modelsList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگذاری مدل‌ها: $e')),
      );
    }
  }

  void _onServiceSelected(Map<String, dynamic> service) {
    setState(() {
      selectedService = service;
      selectedModel = null;
    });
    _showModelsDialog(service);
  }

  void _showModelsDialog(Map<String, dynamic> service) async {
    print('modelsList: ' + modelsList.toString());
    print('service: ' + service.toString());
    final serviceModels = modelsList.where((model) => model['service_id'] == service['id']).toList();
    print('serviceModels: ' + serviceModels.toString());
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('انتخاب مدل ${service['label']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: serviceModels.isEmpty
                ? const Text('مدلی برای این خدمت ثبت نشده است.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: serviceModels.length,
                    itemBuilder: (context, index) {
                      final model = serviceModels[index];
                      return ListTile(
                        title: Text(model['name']),
                        subtitle: Text('${model['price']} تومان - ${model['duration']}'),
                        onTap: () {
                          _onModelSelected(model);
                        },
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  void _onModelSelected(Map<String, dynamic> model) async {
    setState(() {
      selectedModel = model;
    });
    Navigator.pop(context);
    await _showTimeSelectionDialog(model);
  }

  Future<void> _showTimeSelectionDialog(Map<String, dynamic> model) async {
    print('شروع دریافت ساعت‌های آزاد برای مدل: ' + model.toString());
    // نمایش لودینگ قبل از کوئری
    print('قبل از نمایش لودینگ');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    print('بعد از نمایش لودینگ');
    // لیست ساعت‌های پایه
    final List<String> baseTimes = [
      '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00'
    ];
    final dateIso = widget.selectedDate.toDateTime().toIso8601String().substring(0, 10);
    print('dateIso: ' + dateIso);
    print('service: ' + selectedService!['label'].toString());
    print('model_id: ' + model['id'].toString());
    try {
      print('دریافت رزروها برای تاریخ: $dateIso');
      final reservations = await SupabaseConfig.client
        .from('reservations')
        .select()
        .eq('date', dateIso)
        .or('status.eq.pending,status.eq.confirmed,status.eq.در انتظار,status.eq.تایید شده');

      print('رزروهای دریافت شده: $reservations');
      // تبدیل نتیجه به لیست
      final List<dynamic> reservationList = reservations ?? [];
      print('تعداد رزروهای موجود: ${reservationList.length}');

      // تابع کمکی برای نرمال کردن فرمت ساعت
      String normalizeTime(String t) {
        final parts = t.split(':');
        return parts[0].padLeft(2, '0') + ':' + parts[1].padLeft(2, '0');
      }

      // فیلتر کردن ساعت‌های رزرو شده با وضعیت‌های مختلف
      final reservedTimes = reservationList
        .where((r) => 
          ['pending', 'confirmed', 'در انتظار', 'تایید شده'].contains(r['status']) &&
          r['time'] != null
        )
        .map<String>((r) {
          print('رزرو با زمان: ${r['time']} - نوع: ${r['time'].runtimeType}');
          return normalizeTime(r['time'].toString());
        })
        .toList();
      
      print('ساعت‌های رزرو شده: $reservedTimes');
      
      // حذف زمان‌های رزرو شده از لیست زمان‌های پایه
      final availableTimes = baseTimes.where((t) {
        final normalizedBaseTime = normalizeTime(t);
        print('مقایسه ساعت پایه: $normalizedBaseTime با ساعت‌های رزرو شده: $reservedTimes');
        final isAvailable = !reservedTimes.contains(normalizedBaseTime);
        print('ساعت $normalizedBaseTime ${isAvailable ? "آزاد است" : "رزرو شده است"}');
        return isAvailable;
      }).toList();

      print('ساعت‌های آزاد: $availableTimes');
      if (!mounted) return;
      print('قبل از بستن لودینگ');
      Navigator.pop(context); // بستن لودینگ
      print('بعد از بستن لودینگ و قبل از نمایش دیالوگ ساعت');
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('انتخاب ساعت'),
            content: SizedBox(
              width: double.maxFinite,
              child: availableTimes.isEmpty
                  ? const Text('همه‌ی ساعت‌های این مدل برای این تاریخ رزرو شده‌اند.')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: baseTimes.map((time) {
                        final normalizedTime = normalizeTime(time);
                        final isReserved = reservedTimes.contains(normalizedTime);
                        return ElevatedButton(
                          onPressed: isReserved ? null : () {
                            Navigator.pop(context);
                            _goToReservationPage(model, time);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isReserved ? Colors.grey : AppTheme.primaryColor,
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                time,
                                style: TextStyle(
                                  color: isReserved ? Colors.grey.shade600 : Colors.white,
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

  void _goToReservationPage(Map<String, dynamic> model, String time) async {
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
              Text('سرویس: ${selectedService!['label']}'),
              const SizedBox(height: 8),
              Text('مدل: ${model['name']}'),
              const SizedBox(height: 8),
              Text('تاریخ: ${widget.selectedDate.formatFullDate()}'),
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
        date: widget.selectedDate,
        service: selectedService!['label'],
        model: {
          ...model,
          'time': time.toString(),
          'name': model['name'].toString(),
          'price': model['price'].toString(),
          'duration': model['duration'].toString(),
          'service_id': model['service_id']?.toString() ?? '',
        },
      );
      Navigator.pushNamed(
        context,
        '/reservation',
        arguments: reservationData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('انتخاب خدمت'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'لطفاً خدمت مورد نظر خود را انتخاب کنید',
              style: AppTheme.subtitleStyle,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: servicesList.length,
              itemBuilder: (context, index) {
                final service = servicesList[index];
                final isSelected = selectedService != null && service['id'] == selectedService!['id'];
                
                return GestureDetector(
                  onTap: () => _onServiceSelected(service),
                  child: Card(
                    elevation: isSelected ? 8 : 2,
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          service['label'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 