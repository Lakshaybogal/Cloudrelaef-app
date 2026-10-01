import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/services.dart';
import 'ui/app_scope.dart';
import 'ui/startup_error.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final services = await AppServices.open();
    final controller = AppController(services);
    // Reads the OS keystore: fails when no keyring service is available.
    await controller.reloadKeyState();
    runApp(CloudRelaefApp(controller: controller));
  } catch (e) {
    runApp(StartupErrorApp(error: e));
  }
}
