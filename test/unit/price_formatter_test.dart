import 'package:flutter_test/flutter_test.dart';

/// Unit Test 2: Test format harga
String formatPrice(double price) {
  return 'Rp ${price.toInt().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'), 
    (Match m) => '${m[1]},'
  )}';
}

void main() {
  test('formatPrice should format number with thousand separator', () {
    expect(formatPrice(1000), 'Rp 1,000');
    expect(formatPrice(1500000), 'Rp 1,500,000');
    expect(formatPrice(500), 'Rp 500');
  });
}
