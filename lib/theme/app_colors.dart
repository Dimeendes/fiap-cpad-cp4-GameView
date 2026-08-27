import 'package:flutter/material.dart';

class AppColors {
  static const Color blue = Color(0xFF227BF2);
  static const Color purple = Color(0xFF9857FC);
  static const Color darkBlue = Color(0xFF0073AB);

  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      purple,
      blue,
      darkBlue,
    ],
  );
}