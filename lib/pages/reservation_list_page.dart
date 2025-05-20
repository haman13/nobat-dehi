// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:flutter_application_1/pages/reservation_data.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
// import '../models/reservation.dart';

class ReservationListPage extends StatefulWidget {
  const ReservationListPage({Key? key}) : super(key: key);

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  String _userPhone = '';
  List<Reservation> _userReservations = [];

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'در انتظار':
        return Colors.orange;
      case 'تأیید شده':
        return Colors.green;
      case 'لغو شده':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لیست رزروها'),
        centerTitle: true,
        backgroundColor: Colors.pink[400],
      ),
      body: _userReservations.isEmpty
          ? const Center(child: Text('هیچ رزروی برای شما ثبت نشده است.'))
          : ListView.builder(
              itemCount: _userReservations.length,
              itemBuilder: (context, index) {
                final reservation = _userReservations[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: _getStatusColor(reservation.status),
                          width: 4,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                reservation.service,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(reservation.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  reservation.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('تاریخ: ${formatToJalali(reservation.date)}'),
                          Text('ساعت: ${reservation.time}'),
                          Text('قیمت: ${reservation.price} تومان'),
                          if (reservation.status != 'لغو شده')
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: ElevatedButton(
                                onPressed: reservation.status == 'لغو شده از سمت ادمین' 
                                    ? null 
                                    : () => _cancelReservation(reservation),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey,
                                  disabledForegroundColor: Colors.white70,
                                ),
                                child: const Text('لغو رزرو'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _cancelReservation(Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('لغو رزرو'),
        content: const Text('آیا از لغو این رزرو اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('خیر'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('بله'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final reservationsJson = prefs.getStringList('reservations') ?? [];
      
      final updatedReservations = reservationsJson.map((json) {
        final res = Reservation.fromJson(jsonDecode(json));
        if (res.id == reservation.id) {
          return jsonEncode(Reservation(
            id: res.id,
            service: res.service,
            date: res.date,
            time: res.time,
            price: res.price,
            status: 'لغو شده',
            phoneNumber: res.phoneNumber,
            fullName: res.fullName,
          ).toJson());
        }
        return json;
      }).toList();

      await prefs.setStringList('reservations', updatedReservations);
      
      // ذخیره نوتیفیکیشن برای ادمین
      final notifications = prefs.getStringList('admin_notifications') ?? [];
      final notification = jsonEncode({
        'type': 'cancellation',
        'reservation_id': reservation.id,
        'service': reservation.service,
        'date': reservation.date.toIso8601String(),
        'time': reservation.time,
        'user_name': reservation.fullName,
        'user_phone': reservation.phoneNumber,
        'timestamp': DateTime.now().toIso8601String(),
        'cancelled_by': 'user'
      });
      notifications.add(notification);
      await prefs.setStringList('admin_notifications', notifications);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رزرو با موفقیت لغو شد'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadUserPhone(); // بارگذاری مجدد لیست رزروها
    }
  }

  String formatToJalali(DateTime date) {
    final jDate = Jalali.fromDateTime(date);
    return '${jDate.year}/${jDate.month}/${jDate.day}';
  }

  Future<void> _loadUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone') ?? '';
    
    final userReservations = await ReservationData.getUserReservations(phone);
    
    setState(() {
      _userPhone = phone;
      _userReservations = userReservations.map((e) => Reservation.fromJson(e)).toList();
    });
  }
}