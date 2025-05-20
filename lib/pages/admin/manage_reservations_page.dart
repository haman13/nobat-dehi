import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class ManageReservationsPage extends StatefulWidget {
  const ManageReservationsPage({super.key});

  @override
  State<ManageReservationsPage> createState() => _ManageReservationsPageState();
}

class _ManageReservationsPageState extends State<ManageReservationsPage> {
  List<Reservation> allReservations = [];
  String selectedStatus = 'همه';
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final reservationsJson = prefs.getStringList('reservations') ?? [];
    setState(() {
      allReservations = reservationsJson
          .map((json) => Reservation.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  List<Reservation> get filteredReservations {
    return allReservations.where((reservation) {
      if (selectedStatus != 'همه' && reservation.status != selectedStatus) {
        return false;
      }
      if (selectedDate != null) {
        final reservationDate = DateTime(
          reservation.date.year,
          reservation.date.month,
          reservation.date.day,
        );
        final filterDate = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
        );
        if (reservationDate != filterDate) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _updateReservationStatus(Reservation reservation, String newStatus) async {
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
          status: newStatus,
          phoneNumber: res.phoneNumber,
          fullName: res.fullName,
        ).toJson());
      }
      return json;
    }).toList();

    await prefs.setStringList('reservations', updatedReservations);
    await _loadReservations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت رزروها'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'وضعیت',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'همه', child: Text('همه')),
                      DropdownMenuItem(value: 'در انتظار', child: Text('در انتظار')),
                      DropdownMenuItem(value: 'تأیید شده', child: Text('تأیید شده')),
                      DropdownMenuItem(value: 'لغو شده', child: Text('لغو شده')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final picked = await showPersianDatePicker(
                        context: context,
                        initialDate: selectedDate != null
                            ? Jalali.fromDateTime(selectedDate!)
                            : Jalali.now(),
                        firstDate: Jalali(1402, 1),
                        lastDate: Jalali(1410, 12),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked.toDateTime();
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(selectedDate == null
                        ? 'انتخاب تاریخ'
                        : '${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredReservations.length,
              itemBuilder: (context, index) {
                final reservation = filteredReservations[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    title: Text(reservation.service),
                    subtitle: Text('${reservation.date.toString().split(' ')[0]} - ${reservation.time}'),
                    trailing: Container(
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
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('نام: ${reservation.fullName}'),
                            Text('تلفن: ${reservation.phoneNumber}'),
                            Text('قیمت: ${reservation.price} تومان'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (reservation.status != 'لغو شده' && reservation.status != 'لغو شده از سمت ادمین') ...[
                                  if (reservation.status != 'تأیید شده')
                                    ElevatedButton(
                                      onPressed: () => _updateReservationStatus(
                                          reservation, 'تأیید شده'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      child: const Text('تأیید'),
                                    ),
                                  ElevatedButton(
                                    onPressed: () => _updateReservationStatus(
                                        reservation, 'لغو شده از سمت ادمین'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('لغو'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
            status: 'لغو شده از سمت ادمین',
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
        'cancelled_by': 'admin'
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
      
      _loadReservations(); // بارگذاری مجدد لیست رزروها
    }
  }
} 