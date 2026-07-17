import 'package:flutter/material.dart';

class SubjectIcon extends StatelessWidget {
  final double Width;
  final double Height;
  final double IconSize;
  final String MyText;

  const SubjectIcon(
      {super.key,
      this.Width = 20.0,
      this.Height = 20.0,
      this.IconSize = 18.0,
      this.MyText = "Partha Gorai"});

  @override
  Widget build(BuildContext context) {
    String inputString = MyText;
    String firstLetter = inputString.isNotEmpty ? inputString[0] : '';
    return SizedBox(
      width: Width,
      height: Height,
      child: Text(
        firstLetter.toString(),
        style: TextStyle(fontSize: IconSize),
      ),
    );
  }
}
