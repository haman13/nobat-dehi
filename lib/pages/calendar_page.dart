// ignore_for_file: unused_local_variable, use_build_context_synchronously, unnecessary_string_interpolations, unused_element

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:flutter_application_1/pages/servicesList.dart';
import 'package:flutter_application_1/pages/models_list.dart';
import 'package:flutter_application_1/pages/main_screen.dart';
import 'package:flutter_application_1/pages/services_page.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';
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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadModels();
    _loadReservations();
  }

  Future<void> _loadServices() async {
    try {
      final response = await SupabaseConfig.client
          .from('services')
          .select();
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

  Future<void> _loadReservations() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final response = await SupabaseConfig.client
          .from('reservations')
          .select()
          .eq('user_id', user.id)
          .order('date', ascending: true);

      setState(() {
        myReservations = response.map((json) => Reservation.fromJson(json)).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگذاری رزروها: $e')),
      );
    }
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
      _onDateSelected(picked);
    }
  }

  void _onDateSelected(Jalali date) {
    setState(() {
      _selectedDate = date;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServicesPage(selectedDate: date),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
