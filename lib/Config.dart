import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyCustomText extends StatelessWidget {
  final String text;

  const MyCustomText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.lato(
        fontSize: 25,
        color: Colors.black,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
