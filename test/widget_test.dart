import 'package:cloudrelaef/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts and shows its name', (tester) async {
    await tester.pumpWidget(const CloudRelaefApp());
    expect(find.text('CloudRelaef'), findsWidgets);
  });
}
