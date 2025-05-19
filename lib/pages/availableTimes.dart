// ignore_for_file: file_names, unused_import

import "package:flutter/material.dart";
import 'package:flutter_application_1/theme.dart';

List<String> availableTimes = [
  '10:00',
  '11:00',
  '12:00',
  '13:00',
  '14:00',
  '15:00',
  '16:00',
  '17:00',
];

List<String> reservedTimes = [
  '10:00',
  '13:00',
  '15:30',
];

class AvailableTimes extends StatelessWidget {
  final List<String> times;
  final String selectedTime;
  final Function(String) onTimeSelected;

  const AvailableTimes({
    super.key,
    required this.times,
    required this.selectedTime,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: times.length,
        itemBuilder: (context, index) {
          final time = times[index];
          final isSelected = time == selectedTime;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(time),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onTimeSelected(time);
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

