# Final Persistence Certification Check — Admin App

**Date:** 2026-02-22  
**Sources:** `admin_app/supabase/.temp/pulled_schema.sql`, migrations through 041, full codebase.  
**Scope:** Verification only. No refactors, no schema changes, no architecture changes.

---

## STEP 1 — Validate loyalty customer update

**Flow traced:** UI (customer_list_screen → updateCustomerStatus) → CustomerRepository.updateCustomerStatus → `_client.from('loyalty_customers').update({'active': isActive}).eq('id', id)` → table `loyalty_customers`.

**Schema (pulled_schema.sql):**
- Column: `active boolean DEFAULT true` (line 1389). **Exists.**
- Type: **boolean.** ✓
- Triggers: `update_loyalty_customers_updated_at` BEFORE UPDATE → `update_updated_at_column()`. Only sets `NEW.updated_at = NOW()`. Does **not** override `active`. ✓
- RLS: Table has RLS enabled. Policy: `"Allow all for anon" ON loyalty_customers TO anon USING (true) WITH CHECK (true)`. **Does not block update.** ✓

**Result: PASS** — `update({'active': isActive})` matches `loyalty_customers.active` (boolean); column exists, type correct, no trigger override, no RLS block.

---

## STEP 2 — Validate announcements insert

**Payload sent (customer_repository.dart createAnnouncement):**
- `title`
- `content` (from body)
- `target_audience` (from targetTier)
- `created_by` (from _client.auth.currentUser?.id)
- `created_at`

**Schema (announcements table):**
- `title` text NOT NULL ✓
- `content` text NOT NULL ✓ (body is String; non-null)
- `target_audience` text DEFAULT 'all', CHECK: `target_audience = ANY (ARRAY['all','customers','staff'])` ✓
- `created_by` uuid NOT NULL ✓ (see STEP 3 for null risk)
- `created_at` has default ✓

**target_audience allowed values:** `all`, `customers`, `staff` only.

**Flag:** Call site for `createAnnouncement` was not found in the codebase (no UI calls it; AnnouncementScreen writes to `customer_announcements`, not `announcements`). If any caller passes `targetTier` that is not one of `all`, `customers`, `staff` (e.g. loyalty tier `member`, `elite`, `vip`), the insert will violate the CHECK constraint. **Recommendation:** Ensure any caller passes only `all` / `customers` / `staff`, or normalize in the repository before insert.

**Result: PASS** for column and NOT NULL/CHECK alignment, with the above constraint caveat and STEP 3 auth caveat.

---

## STEP 3 — Confirm authentication safety

**Line in question:** `_client.auth.currentUser?.id` (customer_repository.dart, createAnnouncement).

**Findings:**
- The admin app uses **PIN login** via AuthService against **staff_profiles** (see auth_service.dart: “Do not use profiles for auth in this app”; “no Supabase Auth”).
- Supabase Auth session is **not** set when the user logs in with PIN; identity is held in AuthService (`_currentStaffId`) and optionally cache.
- Therefore **`_client.auth.currentUser` is typically null** when using the app after PIN login.
- `created_by` in `announcements` is **NOT NULL** and references `profiles(id)`. If `currentUserId` is null, the insert will **fail** at the database (NOT NULL or FK).

**Result: PERSISTENCE RISK** — `currentUser` can be null in this flow. If `createAnnouncement` is ever called after PIN login only, the insert will fail. To make it safe, either: (a) set Supabase Auth session when PIN login succeeds (so `currentUser` is non-null), or (b) pass the current staff id from AuthService (e.g. `SessionScope.of(context).authService.currentStaffId`) into the repository and use that for `created_by` (if profiles.id and staff_profiles.id align or FK allows).

---

## STEP 4 — Confirm no hidden failures remain

**Scan:** equipment_register_screen.dart, settings_repository.dart, analytics_repository.dart, customer_repository.dart.

**Pattern:** `catch (_) {}` or `catch (e) {}` that wrap **database writes** (insert/update/upsert/delete/rpc that mutates).

| File | Location | Wraps | Verdict |
|------|----------|--------|---------|
| equipment_register_screen.dart | ~201–203 | `_items.firstWhere(...)` (in-memory list) | Not a DB write. OK. |
| settings_repository.dart | — | (none; write catch replaced) | OK. |
| analytics_repository.dart | ~45–47 | `_client.rpc('calculate_nightly_mass_balance')` | **RPC is a DB write.** Silent `catch (_) {}` still present. **Remaining hidden failure.** |
| customer_repository.dart | ~99–102 | `_client.from('recipes').delete().eq('id', id)` | **Delete is a DB write.** Silent `catch (_) {}` still present. **Remaining hidden failure.** |

**Result:** Two remaining catch blocks that swallow database write errors:
1. **analytics_repository.dart** — `triggerMassBalance()` RPC.
2. **customer_repository.dart** — `deleteRecipe()` delete.

All insert/update/upsert write paths that were in scope for the earlier fix now propagate errors (debugPrint + rethrow). No other silent write swallowers found in the four files for **insert/update/upsert**.

---

## STEP 5 — End-to-end persistence simulation

| Operation | Insert/update alignment | Constraints | Await | Error propagation |
|-----------|-------------------------|-------------|-------|-------------------|
| 1. Toggle loyalty customer active/inactive | update `active` only; column exists, boolean | None on `active` | awaited | rethrow |
| 2. Create announcement | title, content, target_audience, created_by, created_at | content/created_by NOT NULL; target_audience CHECK | awaited | rethrow; **risk if created_by null** |
| 3. Save event tag | event_name, event_date, event_type (040) | — | awaited | rethrow |
| 4. Update equipment service log | service_log jsonb | — | awaited | rethrow |
| 5. Save business settings | update/upsert by id or setting_key | UNIQUE(setting_key) | awaited | rethrow |

**Conclusion:** Insert/update payloads and column alignment are correct for these five operations. All use `await`. Error visibility is correct for the write paths that were fixed. Remaining risks: (1) announcements `created_by` null when auth is PIN-only, (2) two remaining silent catches (RPC triggerMassBalance, deleteRecipe).

---

## STEP 6 — Final certification score

| Criterion | Rating | Notes |
|-----------|--------|--------|
| Database alignment | **9/10** | Loyalty `active`, announcements columns and CHECK match. One auth/source-of-truth gap for `created_by`. |
| Write safety | **8/10** | Upserts and updates aligned. Null `created_by` and two silent write catches reduce score. |
| Error visibility | **8/10** | All targeted insert/update/upsert paths now rethrow; two write paths still silent (RPC, delete). |
| Constraint compatibility | **9/10** | target_audience CHECK satisfied if callers send only all/customers/staff; created_by NOT NULL at risk when currentUser is null. |
| Authentication safety | **5/10** | createAnnouncement uses Supabase auth; app uses PIN (staff_profiles). currentUser can be null → persistence risk. |

---

## Final status: **AT RISK**

**Rationale:**
- Loyalty customer update and the fixed write paths (equipment log, business settings, event tags, loyalty/announcements error handling) are **correct and certified** for schema, constraints, and error propagation.
- **Risks that prevent CERTIFIED SAFE:**
  1. **Authentication:** `created_by` for announcements can be null when using PIN login only, causing insert failure or requiring a different source of user id.
  2. **Hidden failures:** Two write paths still swallow errors: `triggerMassBalance()` (RPC) and `deleteRecipe()` (delete).

**To reach CERTIFIED SAFE:**  
(1) Ensure `created_by` is always set for announcements (e.g. from AuthService.currentStaffId if it matches profiles.id, or by setting Supabase Auth when PIN login succeeds).  
(2) Replace the silent catch in `triggerMassBalance` and `deleteRecipe` with debugPrint + rethrow (or equivalent) so write failures are visible.
