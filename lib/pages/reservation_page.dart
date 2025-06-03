import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation_data.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/pages/calendar_page.dart';
import 'package:flutter_application_1/pages/main_screen.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  late final ReservationData _reservationData;
  String _userFullName = '';
  String _userPhone = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reservationData = ModalRoute.of(context)!.settings.arguments as ReservationData;
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone') ?? '';
    if (phone.isNotEmpty) {
      final user = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('phone', phone)
          .maybeSingle();
      setState(() {
        _userFullName = user?['full_name'] ?? '';
        _userPhone = user?['phone'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // بررسی وجود رزرو فعال برای این زمان
      final existingReservations = await SupabaseConfig.client
          .from('reservations')
          .select()
          .eq('date', _reservationData.date.toDateTime().toIso8601String().substring(0, 10))
          .eq('time', _reservationData.model['time'].toString())
          .eq('model_id', _reservationData.model['id'])
          .or('status.eq.pending,status.eq.confirmed,status.eq.در انتظار,status.eq.تایید شده');

      if (existingReservations != null && existingReservations.isNotEmpty) {
        throw Exception('این بازه زمانی قبلاً رزرو شده است. لطفاً ساعت دیگری را انتخاب کنید.');
      }

      // بررسی مجدد قبل از ثبت نهایی
      final finalCheck = await SupabaseConfig.client
          .from('reservations')
          .select()
          .eq('date', _reservationData.date.toDateTime().toIso8601String().substring(0, 10))
          .eq('time', _reservationData.model['time'].toString())
          .eq('model_id', _reservationData.model['id'])
          .or('status.eq.pending,status.eq.confirmed,status.eq.در انتظار,status.eq.تایید شده');

      if (finalCheck != null && finalCheck.isNotEmpty) {
        throw Exception('این بازه زمانی در لحظه ثبت رزرو شده است. لطفاً ساعت دیگری را انتخاب کنید.');
      }

      await SupabaseConfig.client.from('reservations').insert({
        'date': _reservationData.date.toDateTime().toIso8601String().substring(0, 10),
        'service': _reservationData.service,
        'model_id': _reservationData.model['id'],
        'service_id': _reservationData.model['service_id'] ?? null,
        'customer_name': _userFullName,
        'customer_phone': _userPhone,
        'notes': _notesController.text,
        'status': 'pending',
        'time': _reservationData.model['time'].toString(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رزرو با موفقیت ثبت شد')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen(isLoggedIn: true)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      String errorMsg = 'خطا در ثبت رزرو: $e';
      if (e.toString().contains('unique_reservation_per_slot') || e.toString().contains('23505')) {
        errorMsg = 'این بازه زمانی قبلاً رزرو شده است. لطفاً ساعت دیگری را انتخاب کنید.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
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
        title: const Text('تکمیل رزرو'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اطلاعات رزرو',
                        style: AppTheme.subtitleStyle,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('تاریخ', _reservationData.date.formatFullDate()),
                      _buildInfoRow('خدمت', _reservationData.service),
                      _buildInfoRow('مدل', _reservationData.model['name']),
                      _buildInfoRow('قیمت', '${_reservationData.model['price']} تومان'),
                      _buildInfoRow('مدت زمان', _reservationData.model['duration']),
                      _buildInfoRow('نام شما', _userFullName),
                      _buildInfoRow('شماره تماس', _userPhone),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'توضیحات (اختیاری)',
                style: AppTheme.subtitleStyle,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'توضیحات (اختیاری)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReservation,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('ثبت رزرو'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          Text(
            value,
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