# Core Architecture — Multi-App Ecosystem

**Phase 5 (L5):** The system is designed as a **multi-app ecosystem** sharing one Supabase backend.

## Principle

- **Admin App** — Back-office: inventory, production, HR, bookkeeping, analytics. Owner/Manager only.
- **POS App** — Till: sales, transactions, loyalty. Cashier/Blockman. Offline-first (Isar).
- **Customer Loyalty** (future) — Customer-facing offers, points, announcements.
- **Shared backend** — Single Supabase project; one source of truth for products, transactions, ledger, staff.

## Requirements

1. **Single Supabase project** — All apps use the same project URL and anon key (per app config). No duplicate or alternate projects for the same business.
2. **Real-time sync** — Changes in Admin (e.g. product, price) must be visible to POS; POS transactions must appear in Admin. Use Supabase Realtime where needed.
3. **Data consistency** — RLS, triggers, and migrations apply to all apps. Ledger entries, stock deduction, and audit logs are written once and read by all.
4. **Auth** — Staff (profiles, PINs) managed in Admin; POS and Admin share the same `staff_profiles` / auth where applicable.

## Implementation Notes

- **Supabase client:** Use `SupabaseService.client` only (initialized once in `SupabaseService.initialize()`).
- **RLS:** Policies must allow Admin and POS roles to read/write their respective tables; avoid cross-app write conflicts.
- **Triggers:** e.g. `post_pos_sale_to_ledger`, `deduct_stock_on_sale` run in the database and keep ledger and stock correct for all clients.

---

*See Master Implementation Plan Phase 5 and Blueprint §1.2 (Data Flow Between Apps).*
