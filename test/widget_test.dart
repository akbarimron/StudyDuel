import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyduel/app.dart';

void main() {
  testWidgets('StudyDuel smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StudyDuelApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
