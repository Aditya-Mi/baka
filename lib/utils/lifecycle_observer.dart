import 'package:flutter/widgets.dart';

/// Calls [onPause] whenever the app is backgrounded or killed
/// (`paused` / `detached`). Used by the editors to flush drafts.
class LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onPause;
  LifecycleObserver(this.onPause);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      onPause();
    }
  }
}
