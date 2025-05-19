// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_application_1/theme.dart';

final List<Map<String, dynamic>> defaultServices = [
  {'icon': Icons.content_cut, 'label': 'کوتاهی مو'},
  {'icon': Icons.brush, 'label': 'رنگ مو'},
  {'icon': Icons.spa, 'label': 'پاکسازی پوست'},
  {'icon': Icons.abc, 'label': 'ناخن'},
  {'icon': Icons.face_retouching_natural, 'label': 'میکاپ'},
  {'icon': Icons.handshake, 'label': 'براشینگ'},
  {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
  // {'icon': Icons.wash, 'label': 'شستشوی مو'},
];

Future<List<Map<String, dynamic>>> getServices() async {
  final prefs = await SharedPreferences.getInstance();
  final servicesJson = prefs.getString('services');
  
  if (servicesJson != null) {
    final List<dynamic> decodedServices = jsonDecode(servicesJson);
    return decodedServices.map((service) => {
      'icon': IconData(service['icon'], fontFamily: 'MaterialIcons'),
      'label': service['label'],
    }).toList();
  } else {
    // اگر لیست خدمات در SharedPreferences وجود نداشت، لیست پیش‌فرض را ذخیره می‌کنیم
    final defaultServicesJson = defaultServices.map((service) => {
      'icon': service['icon'].codePoint,
      'label': service['label'],
    }).toList();
    await prefs.setString('services', jsonEncode(defaultServicesJson));
    return defaultServices;
  }
}

class ServicesList extends StatelessWidget {
  final List<String> services;
  final String selectedService;
  final Function(String) onServiceSelected;

  const ServicesList({
    super.key,
    required this.services,
    required this.selectedService,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          final isSelected = service == selectedService;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(service),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onServiceSelected(service);
                }
              },
              backgroundColor: AppTheme.primaryLightColor2,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.primaryDarkColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
