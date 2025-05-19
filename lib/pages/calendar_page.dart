// ignore_for_file: unused_local_variable, use_build_context_synchronously, unnecessary_string_interpolations, unused_element

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:flutter_application_1/pages/servicesList.dart';
import 'package:flutter_application_1/pages/models_list.dart';
import 'package:flutter_application_1/pages/main_screen.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class CalendarPage extends StatefulWidget {
  final bool isLoggedIn;
  const CalendarPage({super.key, required this.isLoggedIn});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int columns = 2;
  List<Reservation> myReservations = [];
  String selectedService = '';
  Map<String, dynamic> selectedModel = {};
  List<Map<String, dynamic>> servicesList = [];
  List<Map<String, dynamic>> modelsList = [];
  Jalali? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadModels();
    _loadReservations();
  }

  Future<void> _loadServices() async {
    final services = await getServices();
    setState(() {
      servicesList = services;
      columns = services.length <= 5 ? 2 : 3;
    });
  }

  Future<void> _loadModels() async {
    final models = await getModels();
    setState(() {
      modelsList = models;
    });
  }

  Future<void> _loadReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final reservationsJson = prefs.getStringList('reservations') ?? [];
    setState(() {
      myReservations = reservationsJson
          .map((json) => Reservation.fromJson(jsonDecode(json)))
          .toList();
    });
  }

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
      _showServiceSelectionDialog();
    }
  }

  void _showServiceSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: FractionallySizedBox(
            widthFactor: 0.8,
            heightFactor: servicesList.length <= 4 ? 0.5 : (servicesList.length <= 8 ? 0.7 : 0.8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'انتخاب خدمات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: servicesList.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemBuilder: (context, index) {
                        final service = servicesList[index];
                        return GestureDetector(
                          onTap: () => _onServiceSelected(service['label']),
                          child: _buildServiceTile(
                            service['icon'],
                            service['label']
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'بستن',
                      style: TextStyle(color: Colors.white)
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onServiceSelected(String service) {
    setState(() {
      selectedService = service;
    });
    Navigator.pop(context);
    _showModelSelectionDialog();
  }

  void _showModelSelectionDialog() {
    final serviceModels = modelsList.where((model) => model['service'] == selectedService).toList();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('انتخاب مدل $selectedService'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: serviceModels.length,
              itemBuilder: (context, index) {
                final model = serviceModels[index];
                return ListTile(
                  title: Text(model['name']),
                  subtitle: Text('${model['price']} تومان - ${model['duration']}'),
                  onTap: () {
                    setState(() {
                      selectedModel = model;
                    });
                    Navigator.pop(context);
                    _showTimeSelectionDialog();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showTimeSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('انتخاب ساعت'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ساعات در دسترس:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  '09:00',
                  '10:00',
                  '11:00',
                  '12:00',
                  '13:00',
                  '14:00',
                  '15:00',
                  '16:00',
                  '17:00',
                  '18:00',
                ].map((time) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showFinalConfirmationDialog(time);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                    ),
                    child: Text(time),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFinalConfirmationDialog(String selectedTime) async {
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('phone') ?? '';
    final fullName = prefs.getString('fullname') ?? 'نامشخص';

    // چک کردن رزروهای قبلی
    final reservationsJson = prefs.getStringList('reservations') ?? [];
    final existingReservations = reservationsJson
        .map((json) => Reservation.fromJson(jsonDecode(json)))
        .toList();

    final newReservation = Reservation(
      id: UniqueKey().toString(),
      service: selectedService,
      date: _selectedDate!.toDateTime(),
      time: selectedTime,
      price: selectedModel['price'],
      status: 'در انتظار',
      phoneNumber: userPhone,
      fullName: fullName,
    );

    if (isDuplicateReservation(existingReservations, newReservation)) {
      showErrorDialog(
        context,
        'شما قبلاً این خدمت را در این تاریخ و ساعت رزرو کرده‌اید.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأیید نهایی'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    selectedService,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(width: 5.0),
                  const Text(':خدمت انتخابی'),
                ],
              ),
              const SizedBox(height: 8),
              Text('مدل: ${selectedModel['name']}'),
              const SizedBox(height: 4),
              Text('تاریخ: ${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}'),
              const SizedBox(height: 4),
              Text('ساعت: $selectedTime'),
              const SizedBox(height: 4),
              Text('مدت زمان: ${selectedModel['duration']}'),
              const SizedBox(height: 4),
              Text('قیمت: ${selectedModel['price']} تومان'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(
                      isLoggedIn: true,
                      initialIndex: 0,
                    ),
                  ),
                );
              },
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context, true);
                final reservation = Reservation(
                  id: UniqueKey().toString(),
                  service: selectedService,
                  date: _selectedDate!.toDateTime(),
                  time: selectedTime,
                  price: selectedModel['price'],
                  status: 'در انتظار',
                  phoneNumber: userPhone,
                  fullName: fullName,
                );

                await saveReservation(reservation);
                setState(() {
                  myReservations.add(reservation);
                });
                
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(
                      isLoggedIn: true,
                      initialIndex: 0,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
              ),
              child: const Text('تأیید'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رزرو نوبت'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Stack(
        children: [
          Builder(
            builder: (context) {
              final size = MediaQuery.of(context).size;
              final minSide = size.width < size.height ? size.width : size.height;
              final logoSize = minSide * 0.5;
              return Center(
                child: AppTheme.getLogo(size: logoSize),
              );
            },
          ),
          Column(
            children: [
              Builder(
                builder: (context) {
                  final size = MediaQuery.of(context).size;
                  final minSide = size.width < size.height ? size.width : size.height;
                  return SizedBox(height: minSide * 0.1);
                }
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => _selectDate(context),
                    style: AppTheme.primaryButtonStyle,
                    child: const Text('انتخاب تاریخ'),
                  ),
                ),
              ),
              if (_selectedDate != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'تاریخ انتخاب شده: ${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}',
                    style: AppTheme.bodyStyle,
                  ),
                ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('خطا'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('باشه'),
          ),
        ],
      );
    },
  );
}

bool isDuplicateReservation(List<Reservation> existingReservations, Reservation newReservation) {
  return existingReservations.any((reservation) =>
      reservation.service == newReservation.service &&
      reservation.date.year == newReservation.date.year &&
      reservation.date.month == newReservation.date.month &&
      reservation.date.day == newReservation.date.day &&
      reservation.time == newReservation.time);
}

Future<void> saveReservation(Reservation reservation) async {
  final prefs = await SharedPreferences.getInstance();
  final reservationsJson = prefs.getStringList('reservations') ?? [];
  reservationsJson.add(jsonEncode(reservation.toJson()));
  await prefs.setStringList('reservations', reservationsJson);
}
