// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_application_1/theme.dart';

// مدل‌های مربوط به کوتاهی مو
final hairCutModels = [
  {
    'name': 'کوتاه',
    'price': 150000,
    'duration': '30 دقیقه',
    'description': 'مدل کوتاه و مدرن',
    'service': 'کوتاهی مو',
  },
  {
    'name': 'متوسط',
    'price': 200000,
    'duration': '45 دقیقه',
    'description': 'مدل متوسط و کلاسیک',
    'service': 'کوتاهی مو',
  },
  {
    'name': 'بلند',
    'price': 250000,
    'duration': '60 دقیقه',
    'description': 'مدل بلند و مجلسی',
    'service': 'کوتاهی مو',
  },
];

// مدل‌های مربوط به رنگ مو
final hairColorModels = [
  {
    'name': 'رنگ موی طبیعی',
    'price': 300000,
    'duration': '90 دقیقه',
    'description': 'رنگ‌های طبیعی و ملایم',
    'service': 'رنگ مو',
  },
  {
    'name': 'هایلایت',
    'price': 350000,
    'duration': '120 دقیقه',
    'description': 'هایلایت حرفه‌ای',
    'service': 'رنگ مو',
  },
  {
    'name': 'کراتینه',
    'price': 400000,
    'duration': '150 دقیقه',
    'description': 'کراتینه حرفه‌ای',
    'service': 'رنگ مو',
  },
];

// مدل‌های مربوط به ناخن
final nailModels = [
  {
    'name': 'مانیکور ساده',
    'price': 100000,
    'duration': '30 دقیقه',
    'description': 'مانیکور ساده و تمیز',
    'service': 'ناخن',
  },
  {
    'name': 'مانیکور فرانسوی',
    'price': 150000,
    'duration': '45 دقیقه',
    'description': 'مانیکور فرانسوی با طراحی',
    'service': 'ناخن',
  },
  {
    'name': 'ناخن مصنوعی',
    'price': 200000,
    'duration': '60 دقیقه',
    'description': 'نصب ناخن مصنوعی با طراحی',
    'service': 'ناخن',
  },
];

// لیست کامل مدل‌ها
final List<Map<String, dynamic>> models = [
  ...hairCutModels,
  ...hairColorModels,
  ...nailModels,
];

final List<Map<String, dynamic>> initialModels = [
  ...hairCutModels,
  ...hairColorModels,
  ...nailModels,
];

Future<List<Map<String, dynamic>>> getModels() async {
  final prefs = await SharedPreferences.getInstance();
  final modelsJson = prefs.getString('models');
  
  if (modelsJson != null) {
    final List<dynamic> decodedModels = jsonDecode(modelsJson);
    return List<Map<String, dynamic>>.from(decodedModels);
  } else {
    // اگر لیست مدل‌ها در SharedPreferences وجود نداشت، مدل‌های اولیه را ذخیره کن
    await prefs.setString('models', jsonEncode(initialModels));
    return initialModels;
  }
}

class ModelsList extends StatelessWidget {
  final List<String> models;
  final String selectedModel;
  final Function(String) onModelSelected;

  const ModelsList({
    super.key,
    required this.models,
    required this.selectedModel,
    required this.onModelSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: models.length,
        itemBuilder: (context, index) {
          final model = models[index];
          final isSelected = model == selectedModel;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(model),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onModelSelected(model);
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