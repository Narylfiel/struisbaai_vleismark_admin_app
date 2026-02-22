# Audit: Architecture vs Blueprint and System Rules

**Blueprint:** `AdminAppBluePrintTruth.md` (§16 Flutter project structure, §17 Summary)  
**System rules:** User rules (Supabase init, single project, OAuth, context).  
**Scope:** Supabase initialization location, Supabase project URL, models vs Map, state management (Bloc vs setState), Isar usage.

---

## 1. What exists (with file references)

| Item | Evidence |
|------|----------|
| **main.dart entry** | `main.dart` lines 6–15: `WidgetsFlutterBinding.ensureInitialized()`; **`await Supabase.initialize(url: AdminConfig.supabaseUrl, anonKey: AdminConfig.supabaseAnonKey)`**; `runApp(const AdminApp())`. No call to `SupabaseService.initialize()`. |
| **SupabaseService** | `supabase_service.dart`: `static Future<void> initialize()` which calls `await Supabase.initialize(url: AdminConfig.supabaseUrl, anonKey: AdminConfig.supabaseAnonKey)` (lines 7–11). `static SupabaseClient get client => Supabase.instance.client` (line 5). **SupabaseService.initialize() is never invoked from main or anywhere in lib.** |
| **AdminConfig URL** | `admin_config.dart` line 8: `supabaseUrl = 'https://nasfakcqzmpfcpqttmti.supabase.co'`. Line 9–10: anon key for same project (nasfakcqzmpfcpqttmti). |
| **Other URLs** | `fetch_rpc.dart` line 5, `fetch_schema.dart` line 5: same base URL `nasfakcqzmpfcpqttmti.supabase.co` in REST URLs. |
| **Supabase.instance.client usage** | Used in: base_service.dart (line 7), pin_screen (98, 150), carcass_intake_screen (6 places), product_list_screen (2), job_list_screen (5), staff_list_screen (5), invoice_list_screen (3), account_list_screen (5), dashboard_screen (13), and all repositories via `client ?? Supabase.instance.client`. **CategoryBloc** uses `SupabaseService.client` (category_bloc.dart line 26); inventory_navigation_screen provides `CategoryBloc(SupabaseService())`. |
| **Models** | Only **2** model files: `lib/features/inventory/models/category.dart`, `lib/core/models/base_model.dart`. Category is used by CategoryBloc/category_list/category_form. No other blueprint-listed models (inventory_item, carcass_intake, yield_template, production_batch, dryer_batch, hunter_job, staff_profile, payroll_entry, staff_credit, awol_record, business_account, invoice, ledger_entry, equipment_asset, purchase_sale_agreement, event_tag, shrinkage_alert) exist in codebase. |
| **Map<String, dynamic> usage** | Widespread: 24+ files use `Map<String, dynamic>` or `List<Map<String, dynamic>>` for API/DB data (screens and repositories). All feature data except categories is raw maps. |
| **Bloc** | **Only CategoryBloc** (inventory): `category_bloc.dart`, `category_event.dart`, `category_state.dart`. Used in inventory_navigation_screen (BlocProvider), category_list_screen (BlocBuilder, context.read<CategoryBloc>()), category_form_screen (BlocListener, context.read<CategoryBloc>()). No other Blocs/Cubits in lib. |
| **setState** | All other screens use `setState` for local state (staff_list_screen, report_hub_screen, shrinkage_screen, carcass_intake_screen, job_list_screen, account_list_screen, invoice_list_screen, pin_screen, dashboard_screen, etc.). |
| **Isar** | In `pubspec.yaml`: isar ^3.1.0, isar_flutter_libs ^3.1.0, isar_generator ^3.1.0. In `windows/flutter/generated_plugin_registrant.cc` and `generated_plugins.cmake`: IsarFlutterLibsPlugin registered. **No usage in lib:** no `Isar.open`, no `IsarCollection`, no Isar reads/writes. Blueprint: “Isar for production workflows that need offline” — not implemented. |
| **BaseService** | `base_service.dart`: `final SupabaseClient _client = Supabase.instance.client`; subclasses (e.g. ReportService, ExportService, OcrService) extend it. Repositories do **not** extend BaseService; they take optional client and use `client ?? Supabase.instance.client`. |

So: **Supabase is initialized in main.dart directly; SupabaseService.initialize() exists but is never called. Project URL is nasfakcqzmpfcpqttmti (not the rule-allowed project). Only Category uses a model + Bloc; everything else uses Map + setState. Isar is in deps/plugins but unused in app code.**

---

## 2. What is missing (explicitly from blueprint / rules)

**System rule — Supabase initialization (Rule 1)**  
- **Required:** “Supabase is initialized ONCE … Only inside SupabaseService.initialize(). Never in main.dart directly.”  
- **Missing:** main does not call `SupabaseService.initialize()`; main calls `Supabase.initialize()` directly. So the single, canonical initialization path (SupabaseService) is not used.

**System rule — Supabase project (Rule 2)**  
- **Required:** “Only ONE Supabase project may exist. Allowed: https://nfhltrwjtahmcpbsjhtm.supabase.co. Forbidden: osgdtecmozslkkudblwc.”  
- **Missing:** Current config and scripts use **nasfakcqzmpfcpqttmti.supabase.co** — a different project. The allowed project (nfhltrwjtahmcpbsjhtm) is not used.

**Blueprint — core/models (§16)**  
- Listed: inventory_item, carcass_intake, yield_template, production_batch, dryer_batch, hunter_job, staff_profile, payroll_entry, staff_credit, awol_record, business_account, invoice, ledger_entry, equipment_asset, purchase_sale_agreement, event_tag, shrinkage_alert (and base).  
- **Missing:** All of these model files are absent; only category and base_model exist.

**Blueprint — state management (§16 Key Packages)**  
- “flutter_bloc ^8.1.3 State management.”  
- **Missing:** Bloc is used only for categories. No Blocs for dashboard, production, hunter, hr, accounts, bookkeeping, analytics, reports, customers, audit, settings. All those features rely on setState.

**Blueprint — Isar (§1.2, §17)**  
- “Local Cache: Isar (for production workflows that need offline)”; “Isar for production offline.”  
- **Missing:** No Isar usage in lib — no open, no collections, no offline read/write. Offline production workflows are not implemented.

**Blueprint — SupabaseService as single init**  
- Rule states init only in SupabaseService.initialize().  
- **Missing:** That contract is not enforced; main bypasses it.

---

## 3. What is incorrect (deviations / rule violations)

| Violation / deviation | Rule / blueprint | Current |
|-----------------------|------------------|--------|
| **Supabase init in main** | Rule 1: Only inside SupabaseService.initialize(); never in main.dart. | main.dart lines 9–12 call `await Supabase.initialize(...)` directly. SupabaseService.initialize() is never called. |
| **Duplicate init capability** | Rule 1: Single place; “if Cursor suggests adding another Supabase.initialize(), it is wrong.” | Two places can initialize: main.dart and SupabaseService.initialize(). Risk of double init or init in wrong place. |
| **Wrong Supabase project** | Rule 2: Allowed only nfhltrwjtahmcpbsjhtm.supabase.co. | admin_config.dart, fetch_rpc.dart, fetch_schema.dart use nasfakcqzmpfcpqttmti.supabase.co. |
| **Models vs maps** | Blueprint §16: core/models with typed entities. | Only category + base_model. All other features use Map<String, dynamic> / List<Map<String, dynamic>>. |
| **State management** | Blueprint: flutter_bloc for state management. | Only Category uses Bloc; all other modules use setState. |
| **Isar** | Blueprint: Isar for offline production workflows. | Isar in pubspec and native plugins only; zero usage in Dart code. |
| **Client access pattern** | Single init implies single client access path. | Mixed: CategoryBloc uses SupabaseService.client; BaseService uses Supabase.instance.client; repositories use `client ?? Supabase.instance.client`; many screens use `final _supabase = Supabase.instance.client` directly. No consistent use of SupabaseService after init. |

---

## 4. System impact (what breaks or is at risk)

**Rule violations**  
- **Rule 1:** Init in main means the “only in SupabaseService” contract is broken. Future code may assume init is done in SupabaseService and add logic there, leading to double init or ordering bugs.  
- **Rule 2:** Wrong project URL means the app talks to a different Supabase project than the one allowed by policy. Data, RLS, and auth are for the wrong tenant; switching to the allowed project later requires config and possibly schema/auth changes.

**Structural risks**  
- **No typed models:** Repositories and screens depend on string keys and dynamic types. Refactors and renames cause runtime errors; no compile-time safety; JSON/DB shape changes are easy to miss.  
- **No offline path:** Isar unused, so “production workflows that need offline” (blueprint) are not supported. Any offline requirement (e.g. carcass breakdown without network) cannot be met.  
- **Inconsistent client access:** Mix of SupabaseService.client, Supabase.instance.client, and injected client makes it unclear where “the” client comes from and complicates testing or swapping backends.  
- **setState everywhere except categories:** Large screens (e.g. staff_list_screen, account_list_screen, carcass_intake_screen) hold all state in widget state; no shared business logic, no easy reuse, no clear separation. Bloc is the blueprint’s chosen pattern but is applied only to one feature.

**Long-term scalability impact**  
- **Adding features:** New screens will likely keep using setState + Map, increasing duplication and key-based bugs unless models and a state layer are introduced.  
- **Refactoring:** Without models, changing API or DB shape forces manual updates across many files.  
- **Testing:** Repositories and screens are tied to Supabase.instance and raw maps; unit testing and mocking are harder.  
- **Offline:** Without Isar (or another local store), the app cannot meet blueprint’s offline production workflows.  
- **Multi-project / env handling:** Project URL is hardcoded; no clear single place (e.g. SupabaseService + allowed URL) to enforce “one project” or environment switching.

---

## 5. Completion % for this module

| Sub-module | Completion % | Notes |
|------------|--------------|--------|
| **Supabase init (Rule 1)** | **0%** | Init is in main.dart; SupabaseService.initialize() exists but is never used. Rule requires init only in SupabaseService. |
| **Supabase project (Rule 2)** | **0%** | URL is nasfakcqzmpfcpqttmti; rule allows only nfhltrwjtahmcpbsjhtm. |
| **Models vs Map** | **~10%** | Only Category + base_model; blueprint lists 15+ core models; rest of app is Map-based. |
| **State management (Bloc)** | **~5%** | Only CategoryBloc; blueprint expects flutter_bloc for state management across app. |
| **Isar usage** | **0%** | Dependency and plugin only; no open/read/write in lib. |
| **Single client path** | **~40%** | SupabaseService.client exists; most code uses Supabase.instance.client or injected client; CategoryBloc uses SupabaseService. |

**Overall completion for “Architecture vs blueprint and system rules”: ~15%.**

Critical rule violations: Supabase initialized in main instead of SupabaseService; wrong Supabase project URL. Architecture gaps: almost no typed models, Bloc only in one feature, no Isar usage, inconsistent client access. The codebase does not comply with the stated system rules and does not match the blueprint’s intended architecture for models, state management, and offline support.
