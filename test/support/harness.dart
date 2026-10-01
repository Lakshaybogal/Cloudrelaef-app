import 'package:cloudrelaef/data/db/database.dart';
import 'package:cloudrelaef/data/secure/secret_store.dart';
import 'package:cloudrelaef/providers/registry.dart';
import 'package:cloudrelaef/services/accounts.dart';
import 'package:cloudrelaef/services/files.dart';
import 'package:cloudrelaef/services/folders.dart';
import 'package:cloudrelaef/services/placement.dart';
import 'package:cloudrelaef/services/sync.dart';

import 'fake_provider.dart';

/// Wires every service against in-memory fakes.
class Harness {
  /// Pass existing providers to simulate a second device looking at the same
  /// clouds; [database] to use a file-backed database.
  Harness({
    int totalA = 1000,
    int totalB = 1000,
    this.margin = 0,
    FakeProvider? providerA,
    FakeProvider? providerB,
    AppDatabase? database,
  }) : a = providerA ?? FakeProvider(id: 'fakeA', total: totalA),
       b = providerB ?? FakeProvider(id: 'fakeB', total: totalB) {
    db = database ?? AppDatabase.memory();
    secrets = InMemorySecretStore();
    registry = ProviderRegistry([a, b]);
    accounts = AccountService(db, secrets, registry, now: () => now);
    sync = SyncService(db, accounts, registry, now: () => now);
    files = FileService(
      db,
      accounts,
      registry,
      sync,
      PlacementEngine(MostFreeSpace(), safetyMarginBytes: margin),
      now: () => now,
    );
    folders = FolderService(db);
  }

  final FakeProvider a;
  final FakeProvider b;
  final int margin;
  late final AppDatabase db;
  late final InMemorySecretStore secrets;
  late final ProviderRegistry registry;
  late final AccountService accounts;
  late final SyncService sync;
  late final FileService files;
  late final FolderService folders;
  DateTime now = DateTime.utc(2026, 1, 1);

  Future<int> connect(FakeProvider p, String code) async => accounts.add(
    p.id,
    await p.exchangeCode(code: code, redirectUri: 'r', verifier: 'v'),
  );

  Future<void> close() => db.close();
}

Stream<List<int>> bytes(List<int> b) => Stream.value(b);

Future<List<int>> collect(Stream<List<int>> s) async => [
  for (final c in await s.toList()) ...c,
];
