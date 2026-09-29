import 'package:flutter_test/flutter_test.dart';
import 'package:tunceli_ulasim/app.dart';

void main() {
  testWidgets('Uygulama açılış testi', (WidgetTester tester) async {
    await tester.pumpWidget(
      const TunceliUlasimApp(),
    );

    expect(find.byType(TunceliUlasimApp), findsOneWidget);
  });
}