import 'package:flutter/material.dart';
import '../base/constant.dart';

/// Wraps Material date/range pickers so they use the app orange palette.
class AppCalendarTheme {
  AppCalendarTheme._();

  static ThemeData pickerTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: Constant.primaryColor,
        onPrimary: Colors.white,
        surface: Constant.cardColor,
        onSurface: Constant.textPrimary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Constant.primaryColor),
      ),
    );
  }

  static Widget wrap(BuildContext context, Widget? child) {
    if (child == null) return const SizedBox.shrink();
    return Theme(data: pickerTheme(context), child: child);
  }
}
