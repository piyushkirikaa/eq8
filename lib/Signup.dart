import 'package:flutter/material.dart';
import '../../Parent/BuySubscription.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'Library/RestClient.dart';
import 'Library/StyleConfig.dart';
import 'Service/Analytics.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final bool _checkbox = false;
  String? _value;

  String _email = "";
  String _password = "";
  String _mobile = "";
  String _firstName = "";
  String _lastName = "";
  String _address = "";
  String _city = "";
  String _zipCode = "";

  final outlineInputBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: const BorderSide(width: 1));

  final borderStyle = OutlineInputBorder(
    borderRadius: BorderRadius.circular(50),
    borderSide: const BorderSide(width: 1, style: BorderStyle.solid),
  );

  late String selectedCountry = "Select your country";
  late String selectedState = "Select your state";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/Images/BG/bg_signup.png",
              fit: BoxFit.fill,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: Text(
                  'Create New Account'.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 25,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
            Container(
              height: 10,
            ),
            Container(
              height: 40,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _firstName = value;
                  });
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(0),
                  prefixIcon: const Icon(Icons.people_alt_rounded),
                  hintText: "Enter your first name",
                  hintStyle: const TextStyle(),
                  filled: true,
                  focusColor: Colors.blueAccent,
                  enabledBorder: outlineInputBorderStyle,
                  fillColor: Colors.white,
                  border: borderStyle,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            Container(
              height: 10,
            ),
            Container(
              height: 40,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _lastName = value;
                  });
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(0),
                  prefixIcon: const Icon(Icons.people_alt_rounded),
                  hintText: "Enter last Name",
                  hintStyle: const TextStyle(),
                  filled: true,
                  focusColor: Colors.blueAccent,
                  enabledBorder: outlineInputBorderStyle,
                  fillColor: Colors.white,
                  border: borderStyle,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            Container(
              height: 10,
            ),
            Container(
              height: 40,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _email = value;
                  });
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(0),
                  prefixIcon: const Icon(Icons.email),
                  hintText: "Enter your email",
                  hintStyle: const TextStyle(),
                  filled: true,
                  focusColor: Colors.blueAccent,
                  enabledBorder: outlineInputBorderStyle,
                  fillColor: Colors.white,
                  border: borderStyle,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            Container(
              height: 10,
            ),
            Container(
              height: 40,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: TextField(
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    _password = value;
                  });
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(0),
                  prefixIcon: const Icon(Icons.password_outlined),
                  hintText: "Password",
                  hintStyle: const TextStyle(),
                  focusColor: Colors.blueAccent,
                  enabledBorder: outlineInputBorderStyle,
                  fillColor: Colors.white,
                  border: borderStyle,
                ),
                keyboardType: TextInputType.visiblePassword,
              ),
            ),
            Container(
              height: 10,
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: Text(
                  'Contact Information'.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Container(
              height: 40,
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _mobile = value;
                  });
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(0),
                  prefixIcon: const Icon(Icons.mobile_friendly),
                  hintText: "Enter your mobile number",
                  hintStyle: const TextStyle(),
                  filled: true,
                  focusColor: Colors.blueAccent,
                  enabledBorder: outlineInputBorderStyle,
                  fillColor: Colors.white,
                  border: borderStyle,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            Container(
              height: 10,
            ),
            Container(
              height: 40,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _address = value;
                  });
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(0),
                  prefixIcon: const Icon(Icons.home),
                  hintText: "Enter your Address",
                  hintStyle: const TextStyle(),
                  filled: true,
                  focusColor: Colors.blueAccent,
                  enabledBorder: outlineInputBorderStyle,
                  fillColor: Colors.white,
                  border: borderStyle,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            Container(
              height: 10,
            ),
            Container(
              height: 40,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _city = value;
                  });
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(0),
                  prefixIcon: const Icon(Icons.location_city),
                  hintText: "Enter your City Name",
                  hintStyle: const TextStyle(),
                  filled: true,
                  focusColor: Colors.blueAccent,
                  enabledBorder: outlineInputBorderStyle,
                  fillColor: Colors.white,
                  border: borderStyle,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            Container(
              height: 10,
            ),
            Container(
              height: 40,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _zipCode = value;
                  });
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(0),
                  prefixIcon: const Icon(Icons.location_city),
                  hintText: "Enter your Zip Code",
                  hintStyle: const TextStyle(),
                  filled: true,
                  focusColor: Colors.blueAccent,
                  enabledBorder: outlineInputBorderStyle,
                  fillColor: Colors.white,
                  border: borderStyle,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            Container(
              height: 10,
            ),
            Container(
              height: 40,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: listOfCountry(),
            ),
            Container(
              height: 10,
            ),
            Container(
              height: 40,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: listOfState(),
            ),
            Container(
              height: 10,
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: OutlinedButton(
                onPressed: registerAccount,
                style: StyleConfig.actionButtonStyle,
                child: Text("Sign Up".toUpperCase(),
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
            Container(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget listOfCountry() {
    return FutureBuilder(
        future: getCountryList(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            return DropdownButtonFormField(
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(0),
                prefixIcon: const Icon(Icons.language),
                hintText: "Select your country",
                hintStyle: const TextStyle(),
                filled: true,
                focusColor: Colors.blueAccent,
                enabledBorder: outlineInputBorderStyle,
                fillColor: Colors.white,
                border: borderStyle,
              ),
              initialValue: selectedCountry,
              items: snapshot.data
                  .map<DropdownMenuItem<String>>(
                      (value) => DropdownMenuItem<String>(
                            value: value["name"].toString(),
                            child: Text(value["name"].toString()),
                          ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCountry = value!;
                });
              },
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }

  Widget listOfState() {
    if (selectedCountry == "Select your country") {
      return const SizedBox();
    } else {
      return FutureBuilder(
          future: getStateList(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              return DropdownButtonFormField(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(0),
                  prefixIcon: const Icon(Icons.language),
                  hintText: "Select your state",
                  hintStyle: const TextStyle(),
                  filled: true,
                  focusColor: Colors.blueAccent,
                  enabledBorder: outlineInputBorderStyle,
                  fillColor: Colors.white,
                  border: borderStyle,
                ),
                initialValue: selectedState,
                items: snapshot.data
                    .map<DropdownMenuItem<String>>(
                        (value) => DropdownMenuItem<String>(
                              value: value["name"].toString(),
                              child: Text(value["name"].toString()),
                            ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedState = value!;
                  });
                },
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          });
    }
  }

  Future registerAccount() async {
    showLoadingIndicator();
    if (_email.isEmpty) {
      RestClient().error("Please enter your email");
      hideLoadingIndicator();
    } else if (_password.isEmpty) {
      RestClient().error("Please enter your password");
      hideLoadingIndicator();
    } else if (_mobile.isEmpty) {
      RestClient().error("Please enter your mobile number");
      hideLoadingIndicator();
    } else if (_firstName.isEmpty) {
      RestClient().error("Please enter your first name");
      hideLoadingIndicator();
    } else if (_lastName.isEmpty) {
      RestClient().error("Please enter your last name");
      hideLoadingIndicator();
    } else if (_address.isEmpty) {
      RestClient().error("Please enter your address");
      hideLoadingIndicator();
    } else if (_city.isEmpty) {
      RestClient().error("Please enter your city");
      hideLoadingIndicator();
    } else if (_zipCode.isEmpty) {
      RestClient().error("Please enter your zip code");
      hideLoadingIndicator();
    } else if (selectedCountry == "Select your country") {
      RestClient().error("Please select your country");
      hideLoadingIndicator();
    } else if (selectedState == "Select your state") {
      RestClient().error("Please select your state");
      hideLoadingIndicator();
    } else {
      final data = {
        "email": _email,
        "password": _password,
        "mobile": _mobile,
        "first_name": _firstName,
        "last_name": _lastName,
        "address": _address,
        "city": _city,
        "zip": _zipCode,
        "country": selectedCountry,
        "state": selectedState,
      };
      final result = await RestClient().guestPost("/sign-up", data);
      if (result['status'] == "success") {
        final role = result["data"]["role"].toString();
        final token = result["data"]["api_token"].toString();
        final email = result["data"]["email"].toString();
        final userId = result["data"]["user_id"].toString();
        await RestClient().storeUser(email, userId, token, role);
        Analytics().logEvent('register',
            {"user_role": "student", "email": email, "user_id": userId});
        hideLoadingIndicator();
        navigateToBuySubscription();
      } else {
        RestClient().error(result['data'].toString());
        hideLoadingIndicator();
      }
    }
  }

  void navigateToBuySubscription() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const BuySubscription()),
    );
  }

  void showLoadingIndicator() {
    context.loaderOverlay.show();
  }

  void hideLoadingIndicator() {
    context.loaderOverlay.hide();
  }

  Future getCountryList() async {
    final response = await RestClient().guestGet("/get-country", {});
    if (response['status'] == "success") {
      var data = response['data'];
      data.add({"name": "Select your country"});
      return data;
    } else {
      RestClient().error(response["data"].toString());
      return <Map<String, dynamic>>[];
    }
  }

  Future getStateList() async {
    final response =
        await RestClient().guestGet("/get-state/$selectedCountry", {});
    if (response['status'] == "success") {
      var data = response['data'];
      data.add({"name": "Select your state"});
      return data;
    } else {
      RestClient().error(response["data"].toString());
      return <Map<String, dynamic>>[];
    }
  }
}
