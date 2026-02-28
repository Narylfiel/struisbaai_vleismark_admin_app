import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';

/// Lightweight global session provider. Exposes [AuthService] and [ConnectivityService]
/// so all modules can access current user and connection status. Wrap at root and use
/// [SessionScope.of](context).authService / .connectivityService or singletons directly.
class SessionScope extends InheritedWidget {
  const SessionScope({
    super.key,
    required this.authService,
    required this.connectivityService,
    required super.child,
  });

  final AuthService authService;
  final ConnectivityService connectivityService;

  static SessionScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SessionScope>();
  }

  /// Current session auth; use when context is available. Falls back to singleton.
  static AuthService auth(BuildContext context) {
    return of(context)?.authService ?? AuthService();
  }

  /// Connectivity service for offline banner and cache/sync. Falls back to singleton.
  static ConnectivityService connectivity(BuildContext context) {
    return of(context)?.connectivityService ?? ConnectivityService();
  }

  @override
  bool updateShouldNotify(SessionScope oldWidget) =>
      oldWidget.authService != authService ||
      oldWidget.connectivityService != connectivityService;
}
