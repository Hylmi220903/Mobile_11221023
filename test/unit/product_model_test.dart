import 'package:flutter_test/flutter_test.dart';
import 'package:hylmiwahyudi_11221023/models/product.dart';

/// Unit Test 1: Test model Product
void main() {
  test('Product model should be created with correct properties', () {
    final product = Product(
      id: 'test-1',
      name: 'iPhone 14 Pro',
      model: '128GB Black',
      price: 1500.0,
      imageUrl: 'https://example.com/image.jpg',
    );

    expect(product.id, 'test-1');
    expect(product.name, 'iPhone 14 Pro');
    expect(product.price, 1500.0);
    expect(product.soldCount, 0); // default value
  });
}
  