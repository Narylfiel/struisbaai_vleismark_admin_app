# admin_app

Struisbaai Vleismark — Admin & Back-Office (Blueprint §1–14). Owner/Manager only; manages inventory, production, HR, bookkeeping, analytics.

## Architecture & offline

- **Supabase:** Single backend; use `SupabaseService.client` only (see `lib/core/services/supabase_service.dart`). Multi-app ecosystem: Admin, POS, and future apps share the same project (see `docs/CORE_ARCHITECTURE.md`).
- **Isar (L1):** In pubspec for production workflows that need offline. Current app is online-preferred; Isar cache for yield templates, carcass intake, breakdown is documented as a **future phase** when offline-capable flows are in scope.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
