import 'package:flutter/widgets.dart';

/// Global app lifecycle observer.
/// Pages can check [AppLifecycle.isActive] before polling,
/// or listen to [AppLifecycle.stream] for state changes.
class AppLifecycle extends WidgetsBindingObserver {
  static final AppLifecycle _instance = AppLifecycle._();
  static AppLifecycle get instance => _instance;
  AppLifecycle._();

  bool _active = true;
  bool get isActive => _active;

  final List<VoidCallback> _listeners = [];

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasActive = _active;
    _active = state == AppLifecycleState.resumed;
    if (wasActive != _active) {
      for (final l in _listeners) {
        l();
      }
    }
  }
}
