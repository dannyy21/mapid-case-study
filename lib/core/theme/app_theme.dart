import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const seedColor = Color(0xFF1565C0);

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    useMaterial3: true,
    bottomSheetTheme: const BottomSheetThemeData(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );
}
