import 'package:flutter_test/flutter_test.dart';

// Phone number validator function
bool isValidPhoneNumber(String phone) {
  final phoneRegex = RegExp(r'^[0-9]{10,14}$');
  return phoneRegex.hasMatch(phone);
}

void main() {
  test('isValidPhoneNumber should validate phone number format correctly', () {
    expect(isValidPhoneNumber('08123456789'), true);
    expect(isValidPhoneNumber('081234567890123'), false); // too long
    expect(isValidPhoneNumber('08123'), false); // too short
    expect(isValidPhoneNumber('08123abc456'), false); // contains letters
  });
}
