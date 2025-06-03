import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class ReservationData {
  final Jalali date;
  final String service;
  final Map<String, dynamic> model;

  ReservationData({
    required this.date,
    required this.service,
    required this.model,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toDateTime().toIso8601String(),
      'service': service,
      'model': model,
    };
  }

  factory ReservationData.fromJson(Map<String, dynamic> json) {
    return ReservationData(
      date: Jalali.fromDateTime(DateTime.parse(json['date'])),
      service: json['service'],
      model: json['model'],
    );
  }
} 