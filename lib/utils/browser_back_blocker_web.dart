// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

class BrowserBackBlocker {
  StreamSubscription<html.PopStateEvent>? _subscription;
  bool _isAttached = false;

  void attach() {
    if (_isAttached) return;

    _isAttached = true;
    html.window.history.pushState(
        {'screen': 'game'}, html.document.title, html.window.location.href);
    _subscription = html.window.onPopState.listen((_) {
      html.window.history.pushState(
        {'screen': 'game'},
        html.document.title,
        html.window.location.href,
      );
    });
  }

  void detach() {
    _subscription?.cancel();
    _subscription = null;
    _isAttached = false;
  }
}
