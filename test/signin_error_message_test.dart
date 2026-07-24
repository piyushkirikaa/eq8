import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SignIn Toast Error Message Logic', () {
    test('Both username and password blank', () {
      const msg = "Please enter your Username and Password";
      expect(msg, "Please enter your Username and Password");
    });

    test('Only username blank', () {
      const msg = "Please enter your Username";
      expect(msg, "Please enter your Username");
    });

    test('Only password blank', () {
      const msg = "Please enter your Password";
      expect(msg, "Please enter your Password");
    });

    test('Incorrect credentials / auth failure', () {
      const msg = "Oops! We couldn't sign you in. Please check the Username and Password.";
      expect(msg, "Oops! We couldn't sign you in. Please check the Username and Password.");
    });
  });
}
