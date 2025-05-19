import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Reservation> allReservations = [];
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();
  String selectedReportType = 'درآمد';

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
          .toList();
    });
  }

  List<Reservation> get filteredReservations {
    return allReservations.where((reservation) {
      final date = reservation.date;
      return date.isAfter(startDate) && date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  Map<String, dynamic> get reportData {
    final reservations = filteredReservations;
    final totalIncome = reservations
        .where((r) => r.status == 'تأیید شده')
        .fold(0, (sum, r) => sum + r.price);
    final totalReservations = reservations.length;
    final completedReservations = reservations.where((r) => r.status == 'تأیید شده').length;
    final cancelledReservations = reservations.where((r) => r.status == 'لغو شده').length;
    final pendingReservations = reservations.where((r) => r.status == 'در انتظار').length;

    // محاسبه درآمد به تفکیک سرویس
    final serviceIncome = <String, int>{};
    for (var reservation in reservations.where((r) => r.status == 'تأیید شده')) {
      serviceIncome[reservation.service] = (serviceIncome[reservation.service] ?? 0) + reservation.price;
    }

    return {
      'totalIncome': totalIncome,
      'totalReservations': totalReservations,
      'completedReservations': completedReservations,
      'cancelledReservations': cancelledReservations,
      'pendingReservations': pendingReservations,
      'serviceIncome': serviceIncome,
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = reportData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارش‌ها'),
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
                    value: selectedReportType,
                    decoration: const InputDecoration(
                      labelText: 'نوع گزارش',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'درآمد', child: Text('گزارش درآمد')),
                      DropdownMenuItem(value: 'رزرو', child: Text('گزارش رزرو')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedReportType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2025),
                        initialDateRange: DateTimeRange(
                          start: startDate,
                          end: endDate,
                        ),
                      );
                      if (date != null) {
                        setState(() {
                          startDate = date.start;
                          endDate = date.end;
                        });
                      }
                    },
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      '${startDate.year}/${startDate.month}/${startDate.day} - '
                      '${endDate.year}/${endDate.month}/${endDate.day}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: selectedReportType == 'درآمد'
                ? _buildIncomeReport(data)
                : _buildReservationReport(data),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeReport(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            'درآمد کل',
            '${data['totalIncome']} تومان',
            Colors.green,
          ),
          const SizedBox(height: 16),
          const Text(
            'درآمد به تفکیک سرویس',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...data['serviceIncome'].entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(entry.key),
                trailing: Text(
                  '${entry.value} تومان',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildReservationReport(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            'کل رزروها',
            data['totalReservations'].toString(),
            Colors.blue,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'تأیید شده',
                  data['completedReservations'].toString(),
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'در انتظار',
                  data['pendingReservations'].toString(),
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            'لغو شده',
            data['cancelledReservations'].toString(),
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 