import 'package:cloudrelaef/ui/startup_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keyring errors get an actionable hint', (tester) async {
    await tester.pumpWidget(
      StartupErrorApp(
        error: Exception('Failed to unlock libsecret: org.freedesktop.secrets'),
      ),
    );
    expect(find.text("CloudRelaef can't start"), findsOneWidget);
    expect(find.textContaining('gnome-keyring'), findsOneWidget);
  });

  testWidgets('other errors get a generic message', (tester) async {
    await tester.pumpWidget(StartupErrorApp(error: Exception('disk full')));
    expect(
      find.textContaining('could not open its local storage'),
      findsOneWidget,
    );
  });
}
