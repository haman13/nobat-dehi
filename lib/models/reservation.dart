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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service': service,
      'date': date.toIso8601String(),
      'time': time,
      'note': note,
      'status': status,
      'phoneNumber': phoneNumber,
      'price': price,
      'fullName': fullName,
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
      phoneNumber: map['phoneNumber'],
      price: map['price'],
      fullName: map['fullName'],
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
      'phoneNumber': phoneNumber,
      'price': price,
      'fullName': fullName,
    };
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      service: json['service'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      status: json['status'] ?? 'در انتظار',
      note: json['note'],
      phoneNumber: json['phoneNumber'],
      price: json['price'],
      fullName: json['fullName'],
    );
  }
}
