import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/animated_button.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/utils/supabase_config.dart';

class ReservationDetailsPage extends StatefulWidget {
  final Reservation reservation;

  const ReservationDetailsPage({
    Key? key,
    required this.reservation,
  }) : super(key: key);

  @override
  State<ReservationDetailsPage> createState() => _ReservationDetailsPageState();
}

class _ReservationDetailsPageState extends State<ReservationDetailsPage> {
  bool _isLoading = false;

  Future<void> _cancelReservation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('لغو نوبت'),
        content: const Text('آیا از لغو این نوبت اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('لغو نوبت'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // به‌روزرسانی وضعیت رزرو در Supabase
        await SupabaseConfig.client
            .from('reservations')
            .update({'status': 'لغو شده'}).eq('id', widget.reservation.id);

        // اگر رزرو قبلاً تأیید شده بود، نوتیفیکیشن برای ادمین ایجاد می‌کنیم
        if (widget.reservation.status == 'تأیید شده') {
          await SupabaseConfig.client.from('notifications').insert({
            'type': 'cancellation',
            'reservation_id': widget.reservation.id,
            'service': widget.reservation.service,
            'date': widget.reservation.date.toIso8601String(),
            'time': widget.reservation.time,
            'user_name': widget.reservation.fullName,
            'user_phone': widget.reservation.phoneNumber,
            'timestamp': DateTime.now().toIso8601String(),
            'cancelled_by': 'user'
          });
        }

        if (mounted) {
          Navigator.pop(
              context, true); // برگشت به صفحه قبل با نشان دادن به‌روزرسانی
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطا در لغو نوبت'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
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
        title: const Text('جزئیات نوبت'),
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
                  // کارت اصلی
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.modernCardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.reservation.service,
                          style: AppTheme.titleStyle.copyWith(
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'تاریخ',
                          DateFormat('yyyy/MM/dd')
                              .format(widget.reservation.date),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'ساعت',
                          widget.reservation.time,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'قیمت',
                          '${NumberFormat('#,###').format(widget.reservation.price)} تومان',
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'وضعیت',
                          widget.reservation.status,
                          statusColor:
                              _getStatusColor(widget.reservation.status),
                        ),
                        if (widget.reservation.note != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'یادداشت',
                            widget.reservation.note!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.reservation.status != 'لغو شده' &&
                      widget.reservation.status != 'لغو شده از سمت ادمین')
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedButton(
                        onPressed: _cancelReservation,
                        style: AppTheme.primaryButtonStyle.copyWith(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.red),
                        ),
                        child: const Text('لغو نوبت'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: AppTheme.bodyStyle.copyWith(
            color: statusColor ?? AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'در انتظار':
        return Colors.orange;
      case 'تأیید شده':
        return Colors.green;
      case 'لغو شده':
      case 'لغو شده از سمت ادمین':
        return Colors.red;
      default:
        return AppTheme.textPrimaryColor;
    }
  }
}
