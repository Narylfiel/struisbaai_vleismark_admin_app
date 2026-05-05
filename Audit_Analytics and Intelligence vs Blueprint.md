# Audit: Analytics and Intelligence vs Blueprint

**Blueprint:** `AdminAppBluePrintTruth.md` (§10 Smart Analytics & Compliance)  
**Scope:** Shrinkage alerts, Dynamic pricing, Predictive reorder, Event forecasting.

---

## 1. What exists (with file references)

| Item | Evidence |
|------|----------|
| **Analytics screen and tabs** | `shrinkage_screen.dart`: Scaffold with 4 tabs — Shrinkage Alerts, Dynamic Pricing, Predictive Reorder, Event Forecasting (lines 36–60). Sidebar → Analytics opens this screen (main_shell). |
| **Shrinkage Alerts tab** | `_ShrinkageTab`: Loads `_repo.getShrinkageAlerts()` from `shrinkage_alerts` table (AnalyticsRepository lines 20–26). Displays product_name, theoretical_stock, actual_stock, gap_amount, gap_percentage, possible_reasons, staff_involved, status. Actions: Investigate, Trigger Stock Take, Acknowledge Alert (lines 86–100, 163–167). “Refresh Mass-Balance” calls `_repo.triggerMassBalance()` → RPC `calculate_nightly_mass_balance` (lines 114–117, repo 36–40). Empty state: “No shrinkage alerts automatically logged today.” |
| **Dynamic Pricing tab** | `_PricingTab`: Loads `_repo.getPricingSuggestions()` from `supplier_price_changes` where status = 'Pending' (repo 46–57). Displays supplier_name, product_name, percentage_increase, current_sell_price, suggested_sell_price, margin_impact. Actions: Accept Recommendations (Applied), Ignore (Ignored) (lines 204–215, 265–269). Empty state: “No supplier price hikes detected needing markdown corrections.” **Trigger 2 (slow-moving / expiry markdown)** from blueprint §10.2 is not present — no UI for “Items approaching expiry / slow-moving” or per-product slow-mover markdown. |
| **Predictive Reorder tab** | `_ReorderTab`: Loads `_repo.getReorderRecommendations()` from `reorder_recommendations` table (repo 68–77). Displays product_name, days_remaining, recommendation_text, status (OK/WARNING/URGENT) (lines 293–299, 348–356). “Create Purchase Order” button has `onPressed: () {}` — no behaviour (lines 319–322). Empty state: “Stock levels OK based on transaction velocities. No reorders needed.” Blurb: “Recommendations based on real transaction velocity, seasonality tables, and historical event correlations” — **display only**; calculation is not in app; data comes from table (assumed populated by backend/trigger). |
| **Event Forecasting tab** | `_EventTab`: Loads `_repo.getRecentEvents()` (event_sales_history where event_tag_id is null), `_repo.getHistoricalEventTags()` (event_tags) (repo 84–109). UI: “Unusual Event Detected” from first spike (date, variance_percentage), tag type + description fields, “Save Event Tag” calls `_repo.saveEventTag(type, desc)` (lines 381–396, 390). “Demand Prediction for Upcoming Events” dropdown of event types from _tags; when selected shows **hardcoded** text: “Based on X forecasts, generate a 35kg target for Mince…”, “Based on X forecasts, generate a 60kg target for Boerewors…” — **does not call** `_repo.getForecastForEvent(eventType)` or display RPC result (lines 358–378, 344–378). |
| **AnalyticsRepository** | `analytics_repository.dart`: getShrinkageAlerts (shrinkage_alerts), updateShrinkageStatus, triggerMassBalance (RPC calculate_nightly_mass_balance); getPricingSuggestions (supplier_price_changes), updatePricingSuggestion; getReorderRecommendations (reorder_recommendations); getRecentEvents (event_sales_history, event_tag_id null), getHistoricalEventTags (event_tags), saveEventTag (insert event_type, description, date), getForecastForEvent (RPC get_event_forecast). **getForecastForEvent is never called by the UI.** |
| **DB / migrations** | **shrinkage_alerts, reorder_recommendations, supplier_price_changes:** No `CREATE TABLE` in 001/002; 003 has triggers that INSERT into shrinkage_alerts (batch_id, expected_weight, actual_weight, shrinkage_percentage, alert_type) and reorder_recommendations (item_id, current_stock, reorder_point, days_of_stock, recommended_quantity). So tables are assumed to exist; schema in triggers does not match UI (e.g. UI expects product_name, theoretical_stock, actual_stock, gap_amount, gap_percentage; trigger inserts batch_id, expected_weight, actual_weight, shrinkage_percentage, alert_type). **event_tags** (002): event_name NOT NULL, event_date, event_type (enum), expected_impact, notes. **event_sales_history** (002): event_id NOT NULL → event_tags(id), date, sales_amount, transaction_count, top_products. **event_tag_id** does not exist on event_sales_history — repo uses .isFilter('event_tag_id', null); schema has event_id (required). **saveEventTag** inserts event_type, description, date — table has event_name (required), event_date, notes (no “description” column). |

So: **All four tabs exist and call the repository.** **Shrinkage and reorder read from tables that may not exist or have different schema; dynamic pricing reads supplier_price_changes (table not created in migrations); event tab has schema/column mismatches and hardcoded forecast text; Create Purchase Order and real event forecast are placeholders.**

---

## 2. What is missing (explicitly from blueprint)

**Shrinkage (§10.1)**  
- **Mass-balance calculation in app or guaranteed nightly run:** “Theoretical = Opening + Purchases + Production − Sales − Logged Waste − Moisture Loss”; “Actual = Last stock-take count (or system running total)”; “If Gap > threshold → Alert created.” Trigger in 003 is **production-batch only** (expected vs actual quantity on production_batches), not full inventory mass-balance. RPC `calculate_nightly_mass_balance` is optional (repo catches and ignores errors). No stock-take flow exists (per prior audit), so “Actual = Last stock-take count” is never updated.  
- **Alert actions:** Blueprint has [ACCEPT & NOTE]; UI has Investigate, Trigger Stock Take, Acknowledge — no “Accept & Note” as distinct action.  
- **Severity levels (🔴/🟡/✅):** Blueprint shows severity by gap; UI shows one style (red dot) and status text only.

**Dynamic pricing (§10.2)**  
- **Trigger 2 — Slow-moving / expiry markdown:** “Items approaching expiry / slow-moving” with per-product slow-mover trigger days; “MARKDOWN SUGGESTION” with sell-by date, suggestion %; [APPLY] [DIFFERENT %] [IGNORE]. Not implemented — only Trigger 1 (supplier price change) is in the UI.  
- **Accept ALL / ADJUST INDIVIDUALLY:** Blueprint has both; UI has “Accept Recommendations” (Applied) and “Ignore” only.  
- **Source of supplier_price_changes:** Blueprint “Supplier price change detected (via OCR or manual entry)” — OCR/manual invoice flow is not implemented (per invoice audit), so this table may never be populated.

**Predictive reorder (§10.3)**  
- **“Based on sales velocity + current stock + lead time”** — calculation is not in the app; repo only reads `reorder_recommendations`. Trigger in 003 uses inventory_items.reorder_point and inventory_items.average_daily_sales — those columns may not exist on inventory_items (not in 001 migration for inventory_items).  
- **CREATE PURCHASE ORDER** — Blueprint: button creates purchase order. UI: “Create Purchase Order” has `onPressed: () {}`.  
- **Explicit “Order NOW” / “Order by Friday” / “days of stock left”** — UI shows days_remaining and recommendation_text from table; if table is empty or schema differs, no real recommendations.

**Event forecasting (§10.4)**  
- **Spike detection and tagging flow:** Blueprint: “When a day records sales significantly above the rolling average (threshold: owner-configurable)”, “system prompts: Unusual sales volume detected for [Date]. Was this a specific event or holiday?” Owner selects type (Public Holiday / Local Event / …) and description. **event_sales_history** in 002 has event_id NOT NULL — so every row is linked to an event; there is no “untagged spike” table. getRecentEvents uses event_tag_id (column does not exist).  
- **Pre-Event Forecast Report:** “System asks: Are you preparing for [Event Type]?”; “Shows: Sales data from last 3 occurrences”; “Recommends: Based on Easter 2024 and 2025, you will likely need: T-Bone 45kg, Boerewors 60kg…” “Owner can adjust and save as Order Plan”. UI: dropdown and **hardcoded** “35kg Mince”, “60kg Boerewors” — getForecastForEvent RPC is never called; no order plan save.  
- **What the system tracks per event:** Total sales, top 20 products, sales by hour, stock that ran out, stock leftover, production insufficient, same event vs prior year — no UI or repository methods for these.  
- **event_tags schema vs saveEventTag:** Table has event_name (required), event_date, event_type (enum), notes; repo insert uses event_type, description, date — missing event_name; “description” and “date” do not match column names (notes, event_date). Insert will fail or be wrong.

---

## 3. What is incorrect (deviations)

| Deviation | Blueprint | Current |
|-----------|-----------|---------|
| **Shrinkage data source** | Nightly mass-balance over full inventory (opening, purchases, production, sales, waste). | Trigger only on production_batches (expected vs actual); no CREATE TABLE in migrations for shrinkage_alerts; UI expects product_name, theoretical_stock, actual_stock, gap_*, possible_reasons, staff_involved — trigger inserts batch_id, expected_weight, actual_weight, shrinkage_percentage, alert_type. |
| **Dynamic pricing scope** | Trigger 1 (supplier price) + Trigger 2 (slow-moving/expiry markdown). | Only Trigger 1–style UI; no Trigger 2; supplier_price_changes table not created in migrations. |
| **Reorder data source** | “Sales velocity + current stock + lead time” in app or reliable backend. | Repo only reads reorder_recommendations; trigger assumes inventory_items.reorder_point and average_daily_sales (columns may be missing); reorder_recommendations not created in 001/002. |
| **Event “untagged spikes”** | Events awaiting tagging (e.g. optional link to event). | getRecentEvents filters event_sales_history by event_tag_id null; table has event_id NOT NULL (no event_tag_id column). |
| **Event tag save** | Store event type + description for calendar/forecasting. | saveEventTag inserts event_type, description, date; event_tags has event_name (required), event_date, event_type, notes — no “description”; “date” not a column name. |
| **Event forecast display** | “Based on Easter 2024 and 2025, you will likely need: T-Bone 45kg, Boerewors 60kg…” from forecast engine. | Hardcoded “35kg Mince”, “60kg Boerewors” when event selected; getForecastForEvent() is never called. |
| **Create Purchase Order** | Button creates purchase order. | onPressed: () {} — no behaviour. |

---

## 4. System impact (what breaks or is missing)

**Real vs placeholder analytics**  
- **Shrinkage:** UI is real (reads table, shows actions) but table/schema may be wrong and mass-balance is not the full blueprint calculation; without stock-take, “actual” is never from physical count.  
- **Dynamic pricing:** UI is real for Trigger 1 only; data depends on supplier_price_changes (table not in migrations) and invoice/OCR (not implemented) — so effectively placeholder. Trigger 2 (slow-moving/expiry) is missing.  
- **Reorder:** UI is real (reads table) but table may not exist or be populated; trigger depends on columns that may be missing; “Create Purchase Order” is placeholder.  
- **Event:** Spike list uses wrong column (event_tag_id); saveEventTag mismatches schema; forecast is hardcoded — event intelligence is largely placeholder.

**Data sources used**  
- shrinkage_alerts (table not created in migrations; trigger inserts different columns).  
- supplier_price_changes (table not in migrations).  
- reorder_recommendations (table not in migrations; trigger references inventory_items columns that may not exist).  
- event_tags, event_sales_history (tables exist but repo uses wrong column names and insert shape).

**Reliability of insights**  
- **Low:** Tables may be missing or empty; schema mismatches cause silent empty lists or failed inserts; no full mass-balance, no stock-take baseline, no purchase order creation, no real event forecast. Owner/manager cannot rely on Analytics for shrinkage, reorder, or event planning as specified in the blueprint.

---

## 5. Completion % for this module

| Sub-module | Completion % | Notes |
|------------|--------------|--------|
| **Shrinkage alerts** | **~40%** | Tab, repo, UI, actions, Refresh Mass-Balance exist; full mass-balance and stock-take baseline missing; table/schema uncertain; trigger is production-only. |
| **Dynamic pricing** | **~25%** | Tab, repo, UI for Trigger 1 only; Trigger 2 (slow-moving/expiry) missing; supplier_price_changes not in migrations; data source (invoice/OCR) not implemented. |
| **Predictive reorder** | **~30%** | Tab, repo, UI; table/trigger exist in 003 but table not created in 001/002; Create Purchase Order placeholder; depends on inventory_items columns that may be missing. |
| **Event forecasting** | **~20%** | Tab, repo, tag form, dropdown; getRecentEvents wrong column; saveEventTag schema mismatch; forecast is hardcoded; getForecastForEvent never used; no order plan. |

**Overall completion for “Analytics and intelligence” (shrinkage + dynamic pricing + predictive reorder + event forecasting): ~28%.**

Tabs and repository calls exist for all four areas, but data sources are missing or mismatched, Trigger 2 and full mass-balance are missing, Create Purchase Order and real event forecast are placeholders, and schema/column errors undermine event and reorder flows. Insights are not reliable for production use as specified in the blueprint.
