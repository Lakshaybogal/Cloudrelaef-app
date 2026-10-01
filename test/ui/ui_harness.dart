import 'dart:io';

import 'package:cloudrelaef/app/app.dart';
import 'package:cloudrelaef/app/provider_catalog.dart';
import 'package:cloudrelaef/app/services.dart';
import 'package:cloudrelaef/auth/oauth_config_store.dart';
import 'package:cloudrelaef/data/db/database_host.dart';
import 'package:cloudrelaef/data/secure/secret_store.dart';
import 'package:cloudrelaef/providers/storage_provider.dart';
import 'package:cloudrelaef/ui/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_provider.dart';

class FakeCatalog extends ProviderCatalog {
  FakeCatalog(this.providers) : super(OAuthConfigStore(InMemorySecretStore()));
  final List<FakeProvider> providers;

  @override
  StorageProvider get(String id) => providers.firstWhere((p) => p.id == id);

  @override
  bool isConfigured(String id) => true;
}

class UiEnv {
  UiEnv._(this.dir, this.services, this.controller, this.a, this.b);
  final Directory dir;
  AppServices services;
  final AppController controller;
  final FakeProvider a;
  final FakeProvider b;

  /// Real async work (sqlite, files) must run outside the fake-async zone.
  static Future<UiEnv> create(
    WidgetTester tester, {
    bool withKey = true,
    bool withAccounts = true,
  }) async {
    return (await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('cr_ui_test');
      final a = FakeProvider(id: 'fakeA', total: 80 * 1024 * 1024 * 1024);
      final b = FakeProvider(id: 'fakeB', total: 20 * 1024 * 1024 * 1024);
      final host = await DatabaseHost.open(File('${dir.path}/db.sqlite'));
      final services = AppServices.custom(
        host: host,
        secrets: InMemorySecretStore(),
        catalog: FakeCatalog([a, b]),
        tempDir: Directory('${dir.path}/tmp'),
        downloadsDir: Directory('${dir.path}/dl')..createSync(),
      );
      if (withKey) await services.keys.ensure();
      if (withAccounts) {
        for (final (p, code) in [(a, 'a'), (b, 'b')]) {
          final id = await services.accounts.add(
            p.id,
            await p.exchangeCode(code: code, redirectUri: 'r', verifier: 'v'),
          );
          await services.sync.refreshQuota(id);
        }
      }
      final controller = AppController(services);
      await controller.reloadKeyState();
      return UiEnv._(dir, services, controller, a, b);
    }))!;
  }

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(CloudRelaefApp(controller: controller));
    await settle(tester);
  }

  /// Lets real futures (sqlite) complete, then rebuilds.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await services.host.close();
      await dir.delete(recursive: true);
    });
  }
}
