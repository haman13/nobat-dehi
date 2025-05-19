import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:flutter_application_1/pages/reservation_data.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({Key? key}) : super(key: key);

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedService;
  Jalali? _selectedDate;
  String? _selectedTime;
  int _selectedServicePrice = 0;
  bool _isLoading = false;

  final List<String> _services = [
    'کوتاهی مو',
    'رنگ مو',
    'هایلایت',
    'کراتینه',
    'مژه',
    'ابرو',
    'ناخن',
  ];

  final Map<String, int> _servicePrices = {
    'کوتاهی مو': 150000,
    'رنگ مو': 350000,
    'هایلایت': 450000,
    'کراتینه': 600000,
    'مژه': 250000,
    'ابرو': 100000,
    'ناخن': 200000,
  };

  final List<String> _times = [
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
  ];

  Future<void> _selectDate(BuildContext context) async {
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

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phone') ?? '';
      final fullName = prefs.getString('fullname') ?? 'نامشخص';

      final reservation = Reservation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        service: _selectedService!,
        date: _selectedDate!.toDateTime(),
        time: _selectedTime!,
        price: _selectedServicePrice,
        status: 'در انتظار',
        phoneNumber: phoneNumber,
        fullName: fullName,
      );

      await ReservationData.addReservation(reservation.toJson());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رزرو با موفقیت ثبت شد'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطا در ثبت رزرو'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رزرو نوبت'),
        centerTitle: true,
        backgroundColor: Colors.pink[400],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedService,
                decoration: const InputDecoration(
                  labelText: 'سرویس',
                  border: OutlineInputBorder(),
                ),
                items: _services.map((String service) {
                  return DropdownMenuItem<String>(
                    value: service,
                    child: Text(service),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedService = newValue;
                    _selectedServicePrice = _servicePrices[newValue!] ?? 0;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفاً یک سرویس انتخاب کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'تاریخ',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}'
                        : 'انتخاب تاریخ',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTime,
                decoration: const InputDecoration(
                  labelText: 'ساعت',
                  border: OutlineInputBorder(),
                ),
                items: _times.map((String time) {
                  return DropdownMenuItem<String>(
                    value: time,
                    child: Text(time),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTime = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفاً یک ساعت انتخاب کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_selectedService != null)
                Text(
                  'قیمت: $_selectedServicePrice تومان',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'ثبت رزرو',
                          style: TextStyle(fontSize: 16),
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