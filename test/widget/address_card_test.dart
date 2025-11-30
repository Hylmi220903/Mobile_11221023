import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget Test 5: Test Address Card UI
class TestAddressCard extends StatelessWidget {
  final String recipientName;
  final String phoneNumber;
  final String address;
  final bool isMainAddress;

  const TestAddressCard({
    super.key,
    required this.recipientName,
    required this.phoneNumber,
    required this.address,
    this.isMainAddress = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      recipientName,
                      key: const Key('recipient_name'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(' | '),
                    Text(phoneNumber, key: const Key('phone_number')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(address, key: const Key('address')),
                if (isMainAddress)
                  Container(
                    key: const Key('main_label'),
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Utama', style: TextStyle(color: Colors.blue)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Address card should display recipient info and address', (tester) async {
    await tester.pumpWidget(const TestAddressCard(
      recipientName: 'John Doe',
      phoneNumber: '08123456789',
      address: 'Jalan Contoh No. 123, Jakarta',
      isMainAddress: true,
    ));

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('08123456789'), findsOneWidget);
    expect(find.text('Jalan Contoh No. 123, Jakarta'), findsOneWidget);
    expect(find.byKey(const Key('main_label')), findsOneWidget);
    expect(find.text('Utama'), findsOneWidget);
  });
}
