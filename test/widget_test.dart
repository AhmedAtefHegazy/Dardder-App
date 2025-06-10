// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pharmacy_app/main.dart';
import 'package:pharmacy_app/screens/auth/login_screen.dart';

void main() {
  testWidgets('App should start with login screen',
      (WidgetTester tester) async {
    // Create a FlutterSecureStorage instance for testing
    const storage = FlutterSecureStorage();

    // Build our app and trigger a frame
    await tester.pumpWidget(MyApp(storage: storage));

    // Verify that the login screen is shown initially
    expect(find.byType(LoginScreen), findsOneWidget);

    // Verify that the app title is shown
    expect(find.text('Pharmacy App'), findsOneWidget);

    // Verify that login form elements are present
    expect(find.byType(TextFormField),
        findsNWidgets(2)); // Email and password fields
    expect(find.byType(ElevatedButton), findsOneWidget); // Login button
  });
}
