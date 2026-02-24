# admin_app

Struisbaai Vleismark — Admin & Back-Office (Blueprint §1–14). Owner/Manager only; manages inventory, production, HR, bookkeeping, analytics.

## Architecture & offline

- **Supabase:** Single backend; use `SupabaseService.client` only (see `lib/core/services/supabase_service.dart`). Multi-app ecosystem: Admin, POS, and future apps share the same project (see `docs/CORE_ARCHITECTURE.md`).
- **Isar (L1):** In pubspec for production workflows that need offline. Current app is online-preferred; Isar cache for yield templates, carcass intake, breakdown is documented as a **future phase** when offline-capable flows are in scope.

## Getting Started

### Android: isar_flutter_libs namespace

If the Android build fails with **"Namespace not specified"** for `:isar_flutter_libs`, run once (and after `flutter pub get` if you see the error again):

```powershell
.\scripts\patch_isar_android_namespace.ps1
```

This patches the cached package to add the `namespace` required by Android Gradle Plugin 8+.

---

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
