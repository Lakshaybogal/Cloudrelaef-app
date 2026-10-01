import 'package:flutter/widgets.dart';

import '../app/services.dart';

/// Holds the current service graph. Screens read services from here and call
/// [refresh] after changing data; [replaceServices] is used after a restore.
class AppController extends ChangeNotifier {
  AppController(this._services);
  AppServices _services;
  int _revision = 0;

  AppServices get services => _services;

  /// Whether the backup key exists. null until [reloadKeyState] ran once.
  /// Kept here (not in a FutureBuilder) so data refreshes never rebuild the
  /// whole navigation and reset the selected tab.
  bool? hasKey;

  Future<void> reloadKeyState() async {
    hasKey = await _services.keys.load() != null;
    notifyListeners();
  }

  /// Bumps whenever data changed, so screens re-query.
  int get revision => _revision;

  void refresh() {
    _revision++;
    notifyListeners();
  }

  void replaceServices(AppServices next) {
    _services = next;
    refresh();
    reloadKeyState();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this context');
    return scope!.notifier!;
  }

  static AppServices servicesOf(BuildContext context) => of(context).services;
}
