import 'package:flutter/material.dart';
import '../../veryfy.dart';
import 'package:lottie/lottie.dart';

class forgot extends StatefulWidget {
  const forgot({super.key});

  @override
  State<forgot> createState() => _forgotState();
}

class _forgotState extends State<forgot> {
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
              child: Lottie.asset("assets/Data/dataSignin2.json"),
            ),
            Container(
              height: 60,
              width: 400,
              margin: const EdgeInsets.only(left: 35,right: 15),
              child: const Text('VERIFY YOUR EMAIL',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 27,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              height: 40,
              width: 340,
              margin: const EdgeInsets.only(left: 15,right: 15),
              child: TextField(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(0),
                  prefixIcon:  const Icon(Icons.email_outlined),
                  hintText: "Enter your email",
                  hintStyle: const TextStyle(),
                  filled: true,
                  focusColor: Colors.black,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(width: 2)
                  ),
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide:  const BorderSide(style: BorderStyle.solid),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            Container(
              height: 20,
            ),
            // Container(
            //   height: 40,
            //   width: 340,
            //   margin: EdgeInsets.only(left: 15,right: 15),
            //   child: TextField(
            //     decoration: InputDecoration(
            //       contentPadding: EdgeInsets.all(0),
            //       prefixIcon:  Icon(Icons.password_outlined),
            //       hintText: "Password",
            //       focusColor: Colors.white,
            //       enabledBorder: OutlineInputBorder(
            //           borderRadius: BorderRadius.circular(7),
            //           borderSide: BorderSide(width: 2)
            //
            //       ),
            //       fillColor: Colors.white,
            //       filled: true,
            //       border: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(7),
            //         borderSide:  BorderSide(style: BorderStyle.solid,width: 90,color: Colors.black),
            //       ),
            //     ),
            //     keyboardType: TextInputType.number,
            //   ),
            // ),
            // Container(
            //   height: 60,
            //   width: 340,
            //   margin: EdgeInsets.only(left: 15,right: 15),
            //   child: Row(
            //     children: [
            //       Checkbox(
            //         value: _checkbox,
            //         onChanged: (value) {
            //           setState(() {
            //             _checkbox = value!;
            //
            //           });
            //         },
            //       ),
            //     ],
            //   ),
            // ),
            Container(

              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(left: 35, right: 35),
              child: OutlinedButton(
                onPressed:(){} ,
                style:  OutlinedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape:RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                ),
                child: GestureDetector(
                  onTap: (){
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const veryfy()),
                    );
                  },
                  child: const Text("verify ",
                      style: TextStyle(
                      color: Colors.white))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
