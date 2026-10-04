import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_carplay_example/main.dart';

void main() {
  testWidgets(
    'default demo keeps its template controls and connection status',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      expect(find.text('Flutter Carplay'), findsOneWidget);
      expect(find.text('Set initial rootTemplate'), findsOneWidget);
      expect(find.text('Connection Status: unknown'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    },
  );
}
