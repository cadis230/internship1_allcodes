import 'package:flutter_test/flutter_test.dart';

import 'package:patentability_prediction/main.dart';

void main() {
  testWidgets('Main screen shows upload button', (WidgetTester tester) async {
    await tester.pumpWidget(const PatentabilityApp());

    expect(find.text('Welcome to Patentability Prediction'), findsOneWidget);
    expect(find.text('Choose PDF'), findsOneWidget);
  });
}