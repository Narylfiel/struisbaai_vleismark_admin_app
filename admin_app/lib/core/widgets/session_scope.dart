import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Lightweight global session provider. Exposes [AuthService] so all modules
/// can access current user identity consistently. No app rewrite — wrap at root
/// and use [SessionScope.of](context).authService or [AuthService]() directly.
class SessionScope extends InheritedWidget {
  const SessionScope({
    super.key,
    required this.authService,
    required super.child,
  });

  final AuthService authService;

  static AuthService? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SessionScope>()?.authService;
  }

  /// Current session auth; use when context is available. Falls back to singleton.
  static AuthService auth(BuildContext context) {
    return of(context) ?? AuthService();
  }

  @override
  bool updateShouldNotify(SessionScope oldWidget) =>
      oldWidget.authService != authService;
}
