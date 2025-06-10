class Reservation {
  final String id;
  final String service;
  final DateTime date;
  final String time;
  final String? note;
  final String status;
  final String phoneNumber;
  final int price;
  final String fullName;
  final String? serviceId;
  final String? modelId;

  Reservation({
    required this.id,
    required this.service,
    required this.date,
    required this.time,
    this.note,
    this.status = 'در انتظار',
    required this.phoneNumber,
    required this.price,
    required this.fullName,
    this.serviceId,
    this.modelId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service': service,
      'date': date.toIso8601String(),
      'time': time,
      'note': note,
      'status': status,
      'phone_number': phoneNumber,
      'price': price,
      'full_name': fullName,
      'service_id': serviceId,
      'model_id': modelId,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'],
      service: map['service'],
      date: DateTime.parse(map['date']),
      time: map['time'],
      note: map['note'],
      status: map['status'] ?? 'در انتظار',
      phoneNumber: map['phone_number'],
      price: map['price'],
      fullName: map['full_name'],
      serviceId: map['service_id'],
      modelId: map['model_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service': service,
      'date': date.toIso8601String(),
      'time': time,
      'status': status,
      'note': note,
      'phone_number': phoneNumber,
      'price': price,
      'full_name': fullName,
      'service_id': serviceId,
      'model_id': modelId,
    };
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'].toString(),
      service: json['service'].toString(),
      date: DateTime.parse(json['date'].toString()),
      time: json['time'].toString(),
      status: json['status']?.toString() ?? 'در انتظار',
      note: json['note']?.toString(),
      phoneNumber: json['phone_number'].toString(),
      price: int.tryParse(json['price'].toString()) ?? 0,
      fullName: json['full_name'].toString(),
      serviceId: json['service_id']?.toString(),
      modelId: json['model_id']?.toString(),
    );
  }
}
