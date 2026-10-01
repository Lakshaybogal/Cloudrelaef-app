import 'package:cloudrelaef/ui/accounts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_harness.dart';

Stream<List<int>> data(int n) => Stream.value(List.filled(n, 1));

void main() {
  testWidgets('first run asks to save the recovery key before continuing', (
    tester,
  ) async {
    final env = await UiEnv.create(tester, withKey: false, withAccounts: false);
    await env.pumpApp(tester);

    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pump();
    expect(find.text('Your recovery key'), findsOneWidget);

    final continueBtn = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(continueBtn).onPressed, isNull);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(tester.widget<FilledButton>(continueBtn).onPressed, isNotNull);
    await tester.tap(continueBtn);
    await env.settle(tester);

    // Now on the home shell, and the key is stored.
    expect(find.text('Storage pool'), findsOneWidget);
    final key = await tester.runAsync(() => env.services.keys.load());
    expect(key, isNotNull);
    await env.dispose(tester);
  });

  testWidgets('pool dashboard shows accounts and combined space', (
    tester,
  ) async {
    final env = await UiEnv.create(tester);
    await env.pumpApp(tester);
    expect(find.text('Storage pool'), findsOneWidget);
    expect(find.text('Fake a'), findsOneWidget);
    expect(find.text('Fake b'), findsOneWidget);
    expect(find.textContaining('100 GB free'), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('files: list, search, trash and restore', (tester) async {
    final env = await UiEnv.create(tester);
    await tester.runAsync(() async {
      await env.services.files.upload(
        name: 'report.txt',
        size: 3,
        mime: 'text/plain',
        data: data(3),
      );
      await env.services.files.upload(
        name: 'photo.jpg',
        size: 5,
        mime: 'image/jpeg',
        data: data(5),
      );
    });
    await env.pumpApp(tester);
    await tester.tap(find.text('Files'));
    await env.settle(tester);
    expect(find.text('report.txt'), findsOneWidget);
    expect(find.text('photo.jpg'), findsOneWidget);

    // search
    await tester.tap(find.byTooltip('Search'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'photo');
    await env.settle(tester);
    expect(find.text('report.txt'), findsNothing);
    expect(find.text('photo.jpg'), findsOneWidget);
    await tester.tap(find.byTooltip('Search'));
    await env.settle(tester);

    // delete -> trash
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await env.settle(tester);
    expect(find.byType(ListTile), findsOneWidget);

    await tester.tap(find.byTooltip('Trash'));
    await env.settle(tester);
    expect(find.text('Trash'), findsWidgets);
    expect(find.byIcon(Icons.restore_from_trash), findsOneWidget);
    await tester.tap(find.byIcon(Icons.restore_from_trash));
    await env.settle(tester);
    expect(find.text('Trash is empty'), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('files: create a folder and enter it', (tester) async {
    final env = await UiEnv.create(tester);
    await env.pumpApp(tester);
    await tester.tap(find.text('Files'));
    await env.settle(tester);
    await tester.tap(find.byTooltip('New folder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Holiday');
    await tester.tap(find.text('Create'));
    await env.settle(tester);
    expect(find.text('Holiday'), findsOneWidget);
    await tester.tap(find.text('Holiday'));
    await env.settle(tester);
    expect(find.text('No files here yet'), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets('accounts: lists accounts and offers every provider', (
    tester,
  ) async {
    final env = await UiEnv.create(tester);
    await env.pumpApp(tester);
    await tester.tap(find.text('Accounts'));
    await env.settle(tester);
    expect(find.byType(AccountsScreen), findsOneWidget);
    expect(find.text('Fake a'), findsOneWidget);
    expect(find.text('Add an account'), findsOneWidget);
    expect(find.text('Google Drive'), findsWidgets);
    expect(find.text('OneDrive (personal)'), findsOneWidget);
    expect(find.text('Dropbox'), findsOneWidget);
    await env.dispose(tester);
  });

  testWidgets(
    'accounts: remove asks for confirmation and keeps the cloud files',
    (tester) async {
      final env = await UiEnv.create(tester);
      await env.pumpApp(tester);
      await tester.tap(find.text('Accounts'));
      await env.settle(tester);
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your files stay in that cloud'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await env.settle(tester);
      expect(find.text('Fake a'), findsNothing);
      expect(find.text('Fake b'), findsOneWidget);
      await env.dispose(tester);
    },
  );

  testWidgets('backup: back up now writes to every cloud and shows results', (
    tester,
  ) async {
    final env = await UiEnv.create(tester);
    await env.pumpApp(tester);
    await tester.tap(find.text('Backup'));
    await env.settle(tester);
    expect(find.textContaining('Last backup'), findsOneWidget);
    await tester.tap(find.text('Back up now'));
    await env.settle(tester);
    await env.settle(tester);
    // The app also backs up once on start (interval due), so there can be more.
    expect(find.byIcon(Icons.check_circle_outline), findsAtLeastNWidgets(2));
    await env.dispose(tester);
  });

  testWidgets('backup: recovery key can be shown', (tester) async {
    final env = await UiEnv.create(tester);
    await env.pumpApp(tester);
    await tester.tap(find.text('Backup'));
    await env.settle(tester);
    await tester.tap(find.text('Show recovery key'));
    await env.settle(tester);
    expect(find.text('Recovery key'), findsOneWidget);
    expect(find.textContaining('Keep it private'), findsOneWidget);
    await env.dispose(tester);
  });
}
