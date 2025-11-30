import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget Test 1: Test Login Page UI
class TestLoginPage extends StatelessWidget {
  const TestLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Login')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const TextField(
                key: Key('email_field'),
                decoration: InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              const TextField(
                key: Key('password_field'),
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('login_button'),
                onPressed: () {},
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Login page should display email, password fields and login button', (tester) async {
    await tester.pumpWidget(const TestLoginPage());

    expect(find.byKey(const Key('email_field')), findsOneWidget);
    expect(find.byKey(const Key('password_field')), findsOneWidget);
    expect(find.byKey(const Key('login_button')), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });
}
