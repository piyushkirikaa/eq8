import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../Library/StyleConfig.dart';
import '../../Parent/PaymentSuccessful.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../Library/RestClient.dart';
import 'ParentDashboard.dart';

class BuySubscription extends StatefulWidget {
  const BuySubscription({super.key});

  @override
  State<BuySubscription> createState() => _BuySubscriptionState();
}

class _BuySubscriptionState extends State<BuySubscription> {
  //final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<String> logQueue = [];

  String _firstName = "";
  String _lastName = "";
  String _gender = "Male";
  List snapshot = ['Male', 'Female'];

  String _usersId = '';
  String _password = '';
  String _voucher = '';
  String _selectedGrade = '';

  dynamic membershipInfo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              "assets/Images/BG/bg_subscription.png",
              fit: BoxFit.fill,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: Text(
                  'Buy New Subscription'.toUpperCase(),
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
                decoration: StyleConfig.inputStyle(
                    "Enter student first name", Icons.people_alt_rounded),
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
                decoration: StyleConfig.inputStyle(
                    "Enter student last name", Icons.people_alt_rounded),
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
              child: DropdownButtonFormField(
                decoration: StyleConfig.inputStyle(
                    "Select student gender", Icons.accessibility_new_outlined),
                initialValue: _gender,
                items: snapshot
                    .map<DropdownMenuItem<String>>(
                        (value) => DropdownMenuItem<String>(
                              value: value.toString(),
                              child: Text(value.toString()),
                            ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                },
              ),
            ),
            Container(
              height: 10,
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10, top: 10),
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: Text(
                  'Student Account Information'.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
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
                    _usersId = value;
                  });
                },
                decoration: StyleConfig.inputStyle(
                    "Enter student login id", Icons.account_circle_outlined),
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
                    _password = value;
                  });
                },
                decoration:
                    StyleConfig.inputStyle("Enter student password", Icons.key),
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
              child: listOfGrade(),
            ),
            Container(
              height: 10,
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 10, top: 10),
              width: MediaQuery.of(context).size.width,
              child: Center(
                child: Text(
                  'Subscription Voucher'.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Container(
              height: 10,
            ),
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 20),
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _voucher = value;
                  });
                },
                decoration: StyleConfig.inputStyle(
                    "Enter voucher code", Icons.discount_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: OutlinedButton(
                onPressed: purchaseSubscription,
                style: StyleConfig.actionButtonStyle,
                child: Text("purchase subscription".toUpperCase(),
                    style: const TextStyle(color: Colors.black)),
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

  purchaseSubscription() async {
    if (_firstName.isEmpty) {
      RestClient().error("Please enter your First Name.");
      return;
    } else if (_lastName.isEmpty) {
      RestClient().error("Please enter your Last Name.");
      return;
    } else if (_usersId.isEmpty) {
      RestClient().error("Please enter your User ID.");
      return;
    } else if (_password.isEmpty) {
      RestClient().error("Please enter your Password.");
      return;
    } else if (_selectedGrade.isEmpty) {
      RestClient().error("Please select a Grade.");
      return;
    } else {
      showLoadingIndicator();
      final data = {
        "first_name": _firstName,
        "last_name": _lastName,
        "gender": _gender,
        "user_id": _usersId,
        "password": _password,
        "garde": _selectedGrade,
        "coupon": _voucher,
      };
      final result =
          await RestClient().authPost("/parent/purchase-membership", data);
      if (result['status'] == "success") {
        hideLoadingIndicator();
        membershipInfo = result['data'];
        if (double.parse(result["data"]['total_amount'].toString()) > 0) {
          await paypalWeb(result['data']['total_amount'].toString());
        } else {
          await handelSuccess();
        }
      } else {
        hideLoadingIndicator();
        RestClient().error(result['message'].toString());
      }
    }
  }

  Widget listOfGrade() {
    return FutureBuilder(
        future: getGradeList(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            return DropdownButtonFormField(
              decoration: StyleConfig.inputStyle(
                  "Select student grade", Icons.people_alt_rounded),
              initialValue: _selectedGrade,
              items: snapshot.data
                  .map<DropdownMenuItem<String>>(
                      (value) => DropdownMenuItem<String>(
                            value: value["id"].toString(),
                            child: Text(value["name"].toString()),
                          ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGrade = value!;
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

  Future getGradeList() async {
    final response = await RestClient().guestGet("/get-grade", {});
    if (response['status'] == "success") {
      var data = response['data'];
      data.add({"name": "Select Grade", "id": ""});
      return data;
    } else {
      hideLoadingIndicator();
      RestClient().error(response["message"].toString());
      return <Map<String, dynamic>>[];
    }
  }

  handelPayment(data) async {
    final totalAmount = data['total_amount'].toString();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Column(
          children: <Widget>[
            Text("Alert"),
          ],
        ),
        content: Text(
            "Great news! Your subscription fee is USD $totalAmount. You're all set to continue with the payment using PayPal."),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await paypalWeb(totalAmount);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }

  reTryPayment(data) async {
    final totalAmount = data['total_amount'].toString();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Column(
          children: <Widget>[
            Text("Alert"),
          ],
        ),
        content: const Text(
            "Your payment is failed due to some reason. Please try again."),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await paypalWeb(totalAmount);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  handelSuccess() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const PaymentSuccessful(
                subcriptionInfo: [],
              )),
    );
  }

  void showLoadingIndicator() {
    context.loaderOverlay.show();
  }

  void hideLoadingIndicator() {
    context.loaderOverlay.hide();
  }

  paypalWeb(amount) async {}

  showResult(String text) {
    logQueue.add(text);
    setState(() {});
  }

  updateOrderStatus() async {
    debugPrint(membershipInfo.toString());
    final orderID = membershipInfo['id'];
    final data = {
      "payment_status": "Completed",
    };
    await RestClient()
        .authPost("/parent/subscription-status/update/$orderID", data);
  }

  redirectToDashboard() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ParentDashboard()),
    );
  }
}
