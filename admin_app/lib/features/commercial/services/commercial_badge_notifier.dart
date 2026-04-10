import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifies listeners (e.g. product list) to resync pending commercial-action badges
/// after an approve/reject succeeds — no shared mutable ID set in the UI layer.
class CommercialBadgeNotifier extends ChangeNotifier {
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  CommercialBadgeNotifier._();
  static final CommercialBadgeNotifier instance = CommercialBadgeNotifier._();

  Timer? _debounce;
  bool _disposed = false;

  void notifyPendingActionsChanged() {
    if (_disposed) return;
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      _debounce = null;
      if (!_disposed && hasListeners) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _debounce = null;
    super.dispose();
  }
}
