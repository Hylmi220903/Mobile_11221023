import 'package:flutter_test/flutter_test.dart';

// Password validator function
bool isValidPassword(String password) {
  return password.length >= 8;
}

void main() {
  test('isValidPassword should validate password length correctly', () {
    expect(isValidPassword('password123'), true);
    expect(isValidPassword('12345678'), true);
    expect(isValidPassword('short'), false); // less than 8 chars
    expect(isValidPassword('1234567'), false); // exactly 7 chars
  });
}
