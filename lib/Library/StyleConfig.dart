import 'package:flutter/material.dart';

class StyleConfig {
  static ButtonStyle actionButtonStyle = OutlinedButton.styleFrom(
    side: const BorderSide(width: 1, color: Colors.purple),
    backgroundColor: Colors.purple,
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50),
    ),
  );

  static ButtonStyle feedbackButtonStyle = OutlinedButton.styleFrom(
    side: const BorderSide(width: 1, color: Colors.black),
    backgroundColor: Colors.black,
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );

  static InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      contentPadding: const EdgeInsets.all(0),
      prefixIcon: Icon(icon),
      hintText: label,
      hintStyle: const TextStyle(),
      filled: true,
      focusColor: Colors.blueAccent,
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(width: 1)),
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: const BorderSide(width: 1, style: BorderStyle.solid),
      ),
    );
  }
}
