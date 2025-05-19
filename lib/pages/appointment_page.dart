import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedTime;
  String _selectedService = 'کوتاهی مو';
  String _selectedModel = 'مدل 1';
  bool _isLoading = false;

  final List<String> _services = ['کوتاهی مو', 'رنگ مو', 'اصلاح صورت'];
  final Map<String, List<String>> _models = {
    'کوتاهی مو': ['مدل 1', 'مدل 2', 'مدل 3'],
    'رنگ مو': ['رنگ 1', 'رنگ 2', 'رنگ 3'],
    'اصلاح صورت': ['اصلاح 1', 'اصلاح 2', 'اصلاح 3'],
  };

  @override
  Widget build(BuildContext context) {
    void selectTime() async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now(),
      );
      if (picked != null && picked != _selectedTime) {
        setState(() {
          _selectedTime = picked;
        });
      }
    }

    void saveAppointment() async {
      if (_selectedDay == null || _selectedTime == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خطا'),
            content: const Text('لطفاً تاریخ و ساعت را انتخاب کنید.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('باشه'),
              ),
            ],
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final appointments = prefs.getStringList('appointments') ?? [];
        
        final appointment = {
          'date': DateFormat('yyyy-MM-dd').format(_selectedDay!),
          'time': '${_selectedTime!.hour}:${_selectedTime!.minute}',
          'service': _selectedService,
          'model': _selectedModel,
        };

        appointments.add(jsonEncode(appointment));
        await prefs.setStringList('appointments', appointments);

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('موفق'),
            content: const Text('نوبت شما با موفقیت ثبت شد.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // بستن دیالوگ
                  Navigator.pop(context); // برگشت به صفحه قبل
                },
                child: const Text('باشه'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خطا'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('باشه'),
              ),
            ],
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('رزرو نوبت'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'انتخاب تاریخ',
                            style: AppTheme.subtitleStyle,
                          ),
                          const SizedBox(height: 16),
                          TableCalendar(
                            firstDay: DateTime.now(),
                            lastDay: DateTime.now().add(const Duration(days: 30)),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            selectedDayPredicate: (day) {
                              return isSameDay(_selectedDay, day);
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onFormatChanged: (format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            },
                            calendarStyle: const CalendarStyle(
                              selectedDecoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: AppTheme.primaryLightColor2,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'انتخاب ساعت',
                            style: AppTheme.subtitleStyle,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: selectTime,
                            style: AppTheme.primaryButtonStyle,
                            child: Text(
                              _selectedTime != null
                                  ? '${_selectedTime!.hour}:${_selectedTime!.minute}'
                                  : 'انتخاب ساعت',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'انتخاب خدمت',
                            style: AppTheme.subtitleStyle,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedService,
                            decoration: AppTheme.textFieldDecoration,
                            items: _services.map((String service) {
                              return DropdownMenuItem<String>(
                                value: service,
                                child: Text(service),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedService = newValue;
                                  _selectedModel = _models[newValue]![0];
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'انتخاب مدل',
                            style: AppTheme.subtitleStyle,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedModel,
                            decoration: AppTheme.textFieldDecoration,
                            items: _models[_selectedService]!.map((String model) {
                              return DropdownMenuItem<String>(
                                value: model,
                                child: Text(model),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedModel = newValue;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: saveAppointment,
                      style: AppTheme.primaryButtonStyle,
                      child: const Text('ثبت نوبت'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 