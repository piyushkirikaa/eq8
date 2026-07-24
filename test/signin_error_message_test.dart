import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SignIn error message exact text match', () {
    const expectedErrorMessage =
        "Oops, we couldn't sign you in. Please check the Username and Password";
    expect(expectedErrorMessage,
        "Oops, we couldn't sign you in. Please check the Username and Password");
  });
}
