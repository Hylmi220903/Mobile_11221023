import 'package:flutter_test/flutter_test.dart';

// Email validator function
bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

void main() {
  test('isValidEmail should validate email format correctly', () {
    expect(isValidEmail('test@gmail.com'), true);
    expect(isValidEmail('user.name@domain.co.id'), true);
    expect(isValidEmail('invalid-email'), false);
    expect(isValidEmail('missing@domain'), false);
    expect(isValidEmail('@nodomain.com'), false);
  });
}
