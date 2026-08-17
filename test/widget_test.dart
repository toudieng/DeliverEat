import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:delivereat/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('rejects an invalid email', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });

    test('accepts a valid email', () {
      expect(Validators.email('demo@delivereat.app'), isNull);
    });

    test('rejects a password shorter than 6 characters', () {
      expect(Validators.password('abc'), isNotNull);
    });

    test('accepts a 6+ character password', () {
      expect(Validators.password('password123'), isNull);
    });
  });

  testWidgets('MaterialApp smoke test renders without crashing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: Text('DeliverEat')))),
    );
    expect(find.text('DeliverEat'), findsOneWidget);
  });
}
