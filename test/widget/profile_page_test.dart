import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget Test 3: Test Profile Page UI
class TestProfilePage extends StatelessWidget {
  final String userName;
  final String userEmail;

  const TestProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Column(
          children: [
            CircleAvatar(
              child: Text(userName[0].toUpperCase()),
            ),
            Text(userName, key: const Key('user_name')),
            Text(userEmail, key: const Key('user_email')),
            const ListTile(
              key: Key('edit_profile'),
              leading: Icon(Icons.person),
              title: Text('Edit Profile'),
            ),
            const ListTile(
              key: Key('my_orders'),
              leading: Icon(Icons.shopping_bag),
              title: Text('My Orders'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Profile page should display user info and menu items', (tester) async {
    await tester.pumpWidget(const TestProfilePage(
      userName: 'John Doe',
      userEmail: 'john@example.com',
    ));

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('john@example.com'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('My Orders'), findsOneWidget);
  });
}
