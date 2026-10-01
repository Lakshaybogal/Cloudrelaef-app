import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/services.dart';
import 'ui/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.open();
  final controller = AppController(services);
  await controller.reloadKeyState();
  runApp(CloudRelaefApp(controller: controller));
}
