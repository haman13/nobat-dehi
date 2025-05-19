import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class AppointmentsList extends StatefulWidget {
  const AppointmentsList({super.key});

  @override
  State<AppointmentsList> createState() => _AppointmentsListState();
}

class _AppointmentsListState extends State<AppointmentsList> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appointmentsList = prefs.getStringList('appointments') ?? [];
      
      setState(() {
        _appointments = appointmentsList
            .map((appointment) => jsonDecode(appointment) as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
    }
  }

  Future<void> _deleteAppointment(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appointmentsList = prefs.getStringList('appointments') ?? [];
      
      appointmentsList.removeAt(index);
      await prefs.setStringList('appointments', appointmentsList);
      
      setState(() {
        _appointments.removeAt(index);
      });
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نوبت‌های من'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: AppTheme.primaryLightColor2,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'شما هنوز نوبتی ثبت نکرده‌اید',
                        style: AppTheme.subtitleStyle,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    final date = DateFormat('yyyy-MM-dd').parse(appointment['date']);
                    final time = appointment['time'];
                    final service = appointment['service'];
                    final model = appointment['model'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('yyyy/MM/dd').format(date),
                                  style: AppTheme.subtitleStyle,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () => _deleteAppointment(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  time,
                                  style: AppTheme.bodyStyle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.category, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  service,
                                  style: AppTheme.bodyStyle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.style, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  model,
                                  style: AppTheme.bodyStyle,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 