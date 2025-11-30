import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget Test 4: Test Register Page UI
class TestRegisterPage extends StatelessWidget {
  const TestRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Register')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const TextField(
                key: Key('name_field'),
                decoration: InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 16),
              const TextField(
                key: Key('email_field'),
                decoration: InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              const TextField(
                key: Key('phone_field'),
                decoration: InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 16),
              const TextField(
                key: Key('password_field'),
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('register_button'),
                onPressed: () {},
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Register page should display all form fields', (tester) async {
    await tester.pumpWidget(const TestRegisterPage());

    expect(find.byKey(const Key('name_field')), findsOneWidget);
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('phone_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
    expect(find.byKey(const Key('register_button')), findsOneWidget);
  });
}
