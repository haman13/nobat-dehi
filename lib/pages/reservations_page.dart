import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_application_1/theme.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({super.key});

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  List<Reservation> myReservations = [];

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final reservationsJson = prefs.getStringList('reservations') ?? [];
    final allReservations = reservationsJson
        .map((json) => Reservation.fromJson(jsonDecode(json)))
        .toList();

    final userPhone = prefs.getString('phone') ?? '';
    setState(() {
      myReservations = allReservations
          .where((r) => r.phoneNumber == userPhone)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  String formatToJalali(DateTime date) {
    final jDate = Jalali.fromDateTime(date);
    return '${jDate.year}/${jDate.month}/${jDate.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رزروهای من'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReservations,
        child: myReservations.isEmpty
            ? const Center(
                child: Text('شما هنوز رزروی ندارید'),
              )
            : ListView.builder(
                itemCount: myReservations.length,
                itemBuilder: (context, index) {
                  return _buildReservationCard(myReservations[index]);
                },
              ),
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    Color statusColor;
    switch (reservation.status) {
      case 'در انتظار':
        statusColor = AppTheme.statusPendingColor;
        break;
      case 'تأیید شده':
        statusColor = AppTheme.statusConfirmedColor;
        break;
      case 'لغو شده':
        statusColor = AppTheme.statusCancelledColor;
        break;
      default:
        statusColor = AppTheme.statusDefaultColor;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: statusColor,
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
                    style: AppTheme.subtitleStyle,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
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
              if (reservation.status != 'لغو شده' && reservation.status != 'لغو شده از سمت ادمین')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ElevatedButton(
                    onPressed: () => _cancelReservation(reservation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('لغو رزرو'),
                  ),
                ),
            ],
          ),
        ),
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

      // اگر رزرو قبلاً تأیید شده بود، نوتیفیکیشن برای ادمین ایجاد می‌کنیم
      if (reservation.status == 'تأیید شده') {
        final notificationsJson = prefs.getStringList('admin_notifications') ?? [];
        final notification = {
          'type': 'cancellation',
          'reservation_id': reservation.id,
          'service': reservation.service,
          'date': reservation.date.toIso8601String(),
          'time': reservation.time,
          'user_name': reservation.fullName,
          'user_phone': reservation.phoneNumber,
          'timestamp': DateTime.now().toIso8601String(),
          'cancelled_by': 'user'
        };
        notificationsJson.add(jsonEncode(notification));
        await prefs.setStringList('admin_notifications', notificationsJson);
      }

      await _loadReservations();
    }
  }
} 