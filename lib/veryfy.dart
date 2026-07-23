import 'package:flutter/material.dart';
import '../../SignIn.dart';
import 'package:lottie/lottie.dart';

class veryfy extends StatefulWidget {
  const veryfy({super.key});

  @override
  State<veryfy> createState() => _veryfyState();
}

class _veryfyState extends State<veryfy> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.38,
                ),
                child: Lottie.asset("assets/Data/dataSignin2.json"),
              ),
            ),
            Container(
              height: 60,
              width: 400,
              margin: const EdgeInsets.only(left: 35, right: 15),
              child: const Text(
                'OTP',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              height: 40,
              width: 340,
              margin: const EdgeInsets.only(left: 15, right: 15),
              child: TextField(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(0),
                  prefixIcon: const Icon(Icons.password_outlined),
                  hintText: "Enter your OTP",
                  hintStyle: const TextStyle(),
                  focusColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(width: 2)),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: const BorderSide(
                        style: BorderStyle.solid,
                        width: 90,
                        color: Colors.black),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            Container(
              height: 15,
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(left: 35, right: 35),
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SignIn()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Verify OTP",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
