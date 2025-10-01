// message.dart
import 'package:flutter/material.dart';
import 'package:project6/utils/constant.dart';

class Message {
  static void success(BuildContext context, String text, {int duration = 2}) {
    _showSnackBar(context, text, color_success, duration);
  }

  static void error(BuildContext context, String text, {int duration = 3}) {
    _showSnackBar(context, text, color_error, duration);
  }

  static void warning(BuildContext context, String text, {int duration = 3}) {
    _showSnackBar(context, text, color_warning, duration);
  }

  static void info(BuildContext context, String text, {int duration = 2}) {
    _showSnackBar(context, text, Colors.blue, duration);
  }

  static void _showSnackBar(BuildContext context, String text, Color backgroundColor, int duration) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: duration),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}