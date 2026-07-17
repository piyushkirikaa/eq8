import 'package:flutter/material.dart';
import '../../Library/StyleConfig.dart';
import '../../Parent/ParentDashboard.dart';

class PaymentSuccessful extends StatefulWidget {
  final dynamic subcriptionInfo;
  const PaymentSuccessful({super.key, this.subcriptionInfo});

  @override
  State<PaymentSuccessful> createState() => _PaymentSuccessfulState();
}

class _PaymentSuccessfulState extends State<PaymentSuccessful> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Image.asset(
            "assets/Images/BG/bg_payment_success.png",
            fit: BoxFit.fill,
          ),
          const SizedBox(
            height: 10,
          ),
          const Text("Payment Successful!",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.w500)),
          const SizedBox(
            height: 10,
          ),
          const Center(
              child: Text(
            "The payment has been done successfully.",
            style: TextStyle(fontSize: 16),
          )),
          const SizedBox(
            height: 5,
          ),
          const Text("Thanks for beign there with us."),
          const SizedBox(
            height: 15,
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: OutlinedButton(
              onPressed: redirectToDashboard,
              style: StyleConfig.actionButtonStyle,
              child: Text("Go To Dashboard".toUpperCase(),
                  style: const TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  redirectToDashboard() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ParentDashboard()),
    );
  }
}
