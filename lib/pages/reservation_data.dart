import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReservationData {
  static Future<List<Map<String, dynamic>>> getReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final reservationsJson = prefs.getStringList('reservations') ?? [];
    
    return reservationsJson
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> addReservation(Map<String, dynamic> reservation) async {
    final prefs = await SharedPreferences.getInstance();
    final reservationsJson = prefs.getStringList('reservations') ?? [];
    
    reservationsJson.add(jsonEncode(reservation));
    await prefs.setStringList('reservations', reservationsJson);
  }

  static Future<void> updateReservation(int index, Map<String, dynamic> reservation) async {
    final prefs = await SharedPreferences.getInstance();
    final reservationsJson = prefs.getStringList('reservations') ?? [];
    
    reservationsJson[index] = jsonEncode(reservation);
    await prefs.setStringList('reservations', reservationsJson);
  }

  static Future<void> deleteReservation(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final reservationsJson = prefs.getStringList('reservations') ?? [];
    
    reservationsJson.removeAt(index);
    await prefs.setStringList('reservations', reservationsJson);
  }

  static Future<List<Map<String, dynamic>>> getUserReservations(String phone) async {
    final reservations = await getReservations();
    return reservations.where((r) => r['phone'] == phone).toList();
  }
}
