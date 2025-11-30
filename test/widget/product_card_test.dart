import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget Test 2: Test Product Card UI
class TestProductCard extends StatelessWidget {
  final String name;
  final double price;

  const TestProductCard({super.key, required this.name, required this.price});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Card(
          child: Column(
            children: [
              Text(name, key: const Key('product_name')),
              Text('Rp ${price.toInt()}', key: const Key('product_price')),
              ElevatedButton(
                key: const Key('buy_button'),
                onPressed: () {},
                child: const Text('Buy Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Product card should display product name and price', (tester) async {
    await tester.pumpWidget(const TestProductCard(
      name: 'iPhone 14 Pro',
      price: 15000000,
    ));

    expect(find.text('iPhone 14 Pro'), findsOneWidget);
    expect(find.text('Rp 15000000'), findsOneWidget);
    expect(find.byKey(const Key('buy_button')), findsOneWidget);
  });
}
