# Production System Audit — Admin App vs Blueprint

**Blueprint (single source of truth):** `AdminAppBluePrintTruth.md` §5 Production Management  
**Scope:** Yield templates, Carcass intake, Carcass breakdown, Recipes, Production batches, Dryer (biltong/droewors). No code changes.

---

## 1. WHAT EXISTS (with file references)

### 1.1 Production module entry and structure

| Location | What exists |
|----------|-------------|
| **admin_app/lib/features/production/** | **Single file:** `screens/carcass_intake_screen.dart`. No `recipe_screen.dart`, `production_batch_screen.dart`, or `dryer_batch_screen.dart`. |
| **main_shell.dart** (line 7) | Production nav item opens **CarcassIntakeScreen** (import carcass_intake_screen.dart). No separate routes to Recipes, Batches, or Dryer. |

### 1.2 Yield Templates (§5.1)

| Blueprint | Implementation | File / notes |
|-----------|----------------|---------------|
| Sidebar → Production → Yield Templates | **Tab 1** "Yield Templates" in carcass_intake_screen.dart (lines 41, 52) | Same screen, first tab. |
| List templates | **_YieldTemplatesTab** (69–178): loads from `yield_templates` (lines 89–95), order by carcass_type, template_name. ListView of _TemplateCard; empty state. | ✅ Implemented. |
| Create / Edit template | **_TemplateFormDialog** (opens from _openTemplate): Template Name, Carcass Type dropdown, **cuts** (cut_name, yield_pct, sellable, plu_code per cut). Saves to `yield_templates` with `data` containing template_name, carcass_type, **cuts**, updated_at (lines 869–894). Insert or update yield_templates. | ✅ Implemented. |
| Cuts: Yield %, PLU, sellable | Form has cut_name, yield_pct, sellable, plu_code per cut (869–878). | ✅ Implemented. |
| **Price Multiplier** per cut | Blueprint: "Price Multiplier: If carcass cost = R75/kg, T-Bone sell price = R75 × 1.6". | ❌ **Not in form or save.** No price_multiplier in carcass_intake_screen.dart (grep: no matches). |
| Phase 2–5: Rolling average, Suggested Template Update, flag when actual differs >5% | Blueprint: Phase 2–5 (actuals from breakdowns → rolling average → suggested update → flag >5%). | ❌ **Not implemented.** No UI or logic for rolling average, suggested template update, or >5% flag. |

**Tables used:** `yield_templates` (select, insert, update). Cuts stored in template row (e.g. `cuts` column); no separate `yield_template_cuts` reference in code (schema may be JSON or relation).

### 1.3 Carcass Intake (§5.2)

| Blueprint | Implementation | File / notes |
|-----------|----------------|---------------|
| Sidebar → Production → Carcass Intake → New Intake | **Tab 2** "Carcass Intake" (lines 42, 53); **_CarcassIntakeTab** (306–527): list of intakes; "New Intake" opens **_IntakeFormDialog** (339–342). | ✅ Implemented. |
| Step 1: Delivery — Supplier, Invoice #, Invoice Weight, Carcass Type, Delivery Date | **_IntakeFormDialog** (1185+): Step 1 — Supplier dropdown (from `suppliers`), Invoice Number, Carcass Type dropdown (Beef Side, Beef Quarter, Whole Lamb Premium/AB/B3, Pork Side, etc.), Delivery Date picker (1314–1409). | ✅ Implemented. |
| Step 2: Actual Weighing — Actual Weight | Step 2 — Invoice Weight (kg), Actual Weight (kg) (1412–1432). | ✅ Implemented. |
| Step 3: Variance Check (auto); within 2% / >2% with ACCEPT ANYWAY + LOG NOTE, REJECT, CALL SUPPLIER | Step 3 — Variance displayed (invoice weight, actual weight, variance kg and %). Colours: varianceOk (≤2%), varianceBad (>5%), else warning. Text: "Within tolerance (≤2%)", "Minor discrepancy", "Significant shortfall — contact supplier" (1436–1510). **No explicit buttons** [ACCEPT ANYWAY + LOG NOTE] [REJECT DELIVERY] [CALL SUPPLIER]. Save is **not blocked** by variance; single "Save Intake" (1550–1558). | ⚠️ **Partial.** Variance shown; no ACCEPT/REJECT/CALL SUPPLIER actions; save always allowed. |
| Step 4: Select Yield Template (matching carcass type) | Step 4 — "Select Template (optional — can assign later)" dropdown; templates loaded by carcass type via _loadTemplates(_carcassType) (1213–1227, 1520–1533). | ✅ Implemented. |
| Step 5: Save — carcass_intakes created, Status 'Received' | _save() (1238–1279): insert into `carcass_intakes` with reference_number, supplier_id, invoice_number, invoice_weight, actual_weight, remaining_weight, carcass_type, yield_template_id, delivery_date, **status: 'received'**, variance_pct, notes. | ✅ Implemented. |
| Linked to invoice (if OCR'd) | Notes field; no OCR link in intake form. | ⚠️ Optional; not in scope of intake form. |
| Stock of whole carcass added to system | Blueprint Step 5: "Stock of whole carcass added to system". | ❌ **No code** in intake flow that inserts stock or stock_movements for whole carcass. |

**Tables used:** `carcass_intakes` (insert), `suppliers` (select), `yield_templates` (select by carcass_type).

### 1.4 Carcass Breakdown (§5.3)

| Blueprint | Implementation | File / notes |
|-----------|----------------|---------------|
| Sidebar → Production → Pending Breakdowns | **Tab 3** "Pending Breakdowns" (lines 43, 54); **_PendingBreakdownsTab** (533+): loads carcass_intakes where status in ['received', 'in_progress'] (554–558). List of pending with ref, supplier, carcass type, weight, remaining, status. | ✅ Implemented. |
| Select carcass → Start Breakdown | _startBreakdown(intake) opens **_BreakdownDialog** (567–573). | ✅ Implemented. |
| Full / Partial Breakdown mode | **_BreakdownDialog**: Switch "Partial Breakdown" _isPartial (1830–1835). On save: status = _isPartial ? 'in_progress' : 'completed'; remaining_weight = _remaining (1757–1762). | ✅ Implemented. |
| Template cuts → Expected (kg) vs Actual (kg) | _loadTemplate() loads yield_templates.cuts, computes expected_kg = actualWeight * yield_pct/100 per cut (1686–1725). UI: table with Cut, Expected, Actual (controllers), Variance (1901–1956). | ✅ Implemented. |
| Remaining on hook | _remainingController; _remaining used in update (1760). Display "Remaining on hook" in card (1716–1718). | ✅ Implemented. |
| Complete: validate sum vs intake weight; if gap >2% warn | _totalActual, _unaccounted (1727–1736). Display of variance; no explicit "gap > 2%: investigate or log as waste" **block** on save. | ⚠️ **Partial.** Variance shown; save not blocked by balance. |
| **stock_movements created for each cut** | Blueprint §5.3 Complete Breakdown: "stock_movements records created for each cut". | ❌ **Not implemented.** _save() (1740–1787) only: carcass_intakes.update(status, remaining_weight), carcass_cuts.insert(...). No insert into stock_movements. |
| **inventory_items.stock_on_hand updated for each cut** | Blueprint: "inventory_items.stock_on_hand updated for each cut". | ❌ **Not implemented.** No update to inventory_items in breakdown save. |
| Blockman performance rating (stars, cut-by-cut) | Blueprint §5.4: Overall yield %, rating stars, cut-by-cut performance, monthly average. | ❌ **Not implemented.** No Blockman selection in breakdown; no performance UI or calculation after save. |

**Tables used:** `carcass_intakes` (select, update), `carcass_cuts` (insert), `yield_templates` (select). **Not used:** stock_movements, inventory_items.

### 1.5 Recipes (§5.5)

| Blueprint | Implementation |
|-----------|----------------|
| Sidebar → 🔪 Production → **Recipes** | **Not implemented.** No Recipes tab or screen in production. No recipe_screen.dart. |
| Create Recipe — Output Product, Expected Yield %, Ingredients (per batch, unit) | No UI. No `recipes` or `recipe_ingredients` usage in production module. |
| recipes / recipe_ingredients (Blueprint §15) | No .from('recipes') or .from('recipe_ingredients') in production. **Customer** feature uses .from('recipes') for **Recipe Library** (customer-facing content in customer_repository.dart, customer_list_screen.dart _RecipesTab) — different purpose (customer app feeds), not production recipes for boerewors etc. |

**Conclusion:** Production **Recipes** (output product, ingredients per batch for production batches) are **missing**. Customer "Recipe Library" is not the same as Production → Recipes.

### 1.6 Production Batches (§5.5)

| Blueprint | Implementation |
|-----------|----------------|
| Sidebar → Production → (Recipe →) **Start Batch** | **Not implemented.** No production batch screen or workflow. |
| Production Batch Workflow: Select recipe → Start Batch → actual ingredients → actual output → yield % and cost → production_batches + production_batch_ingredients → ingredient stock REDUCED → output stock INCREASED → cost per kg | No UI. No `production_batches` or `production_batch_ingredients` usage anywhere in admin_app/lib. |
| production_batches / production_batch_ingredients (Blueprint §15) | No .from('production_batches') or .from('production_batch_ingredients') in codebase. |

**Conclusion:** Production batches are **not implemented**.

### 1.7 Dryer / Biltong & Droewors (§5.6)

| Blueprint | Implementation |
|-----------|----------------|
| Sidebar → Production → **Dryer Batches** | **Not implemented.** No Dryer tab or screen in production. No dryer_batch_screen.dart. |
| Dryer Batch Workflow: New Batch → Product Type (Biltong/Droewors/Chilli Bites/Other) → recipe → raw material + weight → spices/vinegar/casings → Load Dryer → status Drying → drying period → weigh out → output weight → yield % → finished product stock added, raw deducted | No UI. No dryer batch logic. |
| dryer_batches / dryer_batch_ingredients (Blueprint §15) | No .from('dryer_batches') or .from('dryer_batch_ingredients') in codebase. |
| admin_config defaultStorageLocations | 'Biltong Dryer' listed (line 93) — config only; no dryer module. |

**Conclusion:** Dryer (biltong/droewors) module is **not implemented**.

---

## 2. WHAT IS MISSING (explicitly from blueprint)

### 2.1 Yield templates

- **Price Multiplier** per cut (e.g. 1.6× for T-Bone).
- **Phase 2–5:** Rolling actual average from breakdowns (last 10 per carcass type); "Suggested Template Update"; flag when actual differs from template by >5%.

### 2.2 Carcass intake

- **Step 3 actions:** [ACCEPT ANYWAY + LOG NOTE] [REJECT DELIVERY] [CALL SUPPLIER] when variance > 2% (currently only message; save always allowed).
- **Stock of whole carcass** added to system on save (no stock write in intake flow).

### 2.3 Carcass breakdown

- **stock_movements** records created for each cut.
- **inventory_items.stock_on_hand** updated for each cut (increase by actual_kg for sellable cuts).
- **Blockman** selection and **Blockman performance rating** (stars, cut-by-cut, monthly average) after breakdown.
- Explicit **validation** that sum of actuals is within tolerance of intake weight before allowing Complete (and optional "investigate or log as waste" when gap > 2%).

### 2.4 Recipes (entire module)

- Production → Recipes screen.
- Create Recipe (output product, expected yield %, ingredients per batch with units).
- recipes / recipe_ingredients tables used for **production** recipes (not customer recipe library).

### 2.5 Production batches (entire module)

- Production batch workflow (select recipe → Start Batch → enter actuals → complete).
- production_batches + production_batch_ingredients.
- Ingredient stock reduced, output product stock increased.
- Cost per kg calculated.

### 2.6 Dryer (entire module)

- Production → Dryer Batches screen.
- Dryer batch workflow (product type, recipe, raw material, spices/casings, Load Dryer, drying period, weigh out, yield %, stock).
- dryer_batches + dryer_batch_ingredients.

---

## 3. WHAT IS INCORRECT (deviations)

### 3.1 Breakdown does not update stock

- **Blueprint §5.3:** "stock_movements records created for each cut" and "inventory_items.stock_on_hand updated for each cut."
- **Implementation:** Breakdown save only updates carcass_intakes and inserts carcass_cuts. No stock_movements insert, no inventory_items update. **Cuts are logged but sellable product stock is not increased** — intake → breakdown → product flow is incomplete for inventory.

### 3.2 Yield template — no price multiplier

- Blueprint: Each cut has Yield % and **Price Multiplier** (e.g. 1.6× for T-Bone) for pricing from carcass cost.
- Implementation: Template form has cut_name, yield_pct, sellable, plu_code; no price_multiplier field or logic.

### 3.3 Intake — variance does not gate save

- Blueprint: If variance > 2%, explicit choices (ACCEPT ANYWAY + LOG NOTE, REJECT, CALL SUPPLIER).
- Implementation: Variance is displayed and messaged; user can always click "Save Intake" regardless of variance. No REJECT path (e.g. no intake record) or ACCEPT ANYWAY + note.

### 3.4 Single production screen

- Blueprint §16: production/ screens include yield_template_screen, carcass_intake_screen, carcass_breakdown_screen, **recipe_screen**, **production_batch_screen**, **dryer_batch_screen**.
- Implementation: One file (carcass_intake_screen.dart) with three tabs (Yield Templates, Carcass Intake, Pending Breakdowns). No separate breakdown screen (breakdown is dialog); no recipe, batch, or dryer screens.

---

## 4. SYSTEM IMPACT (what breaks because of this)

### 4.1 Workflow completeness: intake → breakdown → product

- **Blueprint:** Carcass intake → breakdown → **stock_movements created, inventory_items.stock_on_hand updated** → product available for sale.
- **Reality:** Intake and breakdown (and cut logging) exist; **no stock_movements or inventory update** on breakdown. So:
  - Carcass and cut data are recorded for yield/blockman analysis, but **sellable stock (e.g. T-Bone, Rump) is not increased** in the system.
  - POS/inventory will not show new product from breakdowns; reorder and stock levels will be wrong; production and inventory are **disconnected**.

### 4.2 Stock accuracy and costing

- **Own-cut products:** Cannot get stock from carcass breakdown (no inventory update). Stock accuracy for cuts (T-Bone, Mince, etc.) is wrong unless maintained elsewhere.
- **Own-processed products (boerewors, etc.):** No recipes or production batches → no ingredient deduction or output stock increase → no cost-per-kg from batches. Costing and margin for processed items cannot be driven from production.
- **Dryer products (biltong, droewors):** No dryer module → no raw deduction, no finished product stock, no drying yield or cost per kg. Full biltong/droewors production and costing is missing.

### 4.3 Missing transformation stages

| Stage | Blueprint | In app | Impact |
|-------|-----------|--------|--------|
| Carcass → Cuts | Breakdown updates stock per cut | Only carcass_cuts logged | Cuts never increase inventory. |
| Ingredients → Finished (recipe/batch) | Recipe → Start Batch → stock in/out, cost per kg | Not implemented | Processed products (boerewors, etc.) not produced in system. |
| Raw → Dried (dryer) | Dryer batch → drying → weigh out → stock | Not implemented | Biltong/droewors not produced in system. |

### 4.4 Blockman performance

- No Blockman selection on breakdown and no performance rating (stars, cut-by-cut) → no in-app blockman performance or yield tracking as specified.

---

## 5. COMPLETION % FOR THIS MODULE (full production system)

**Module:** Production system as defined in blueprint §5.1–§5.6 (Yield templates, Carcass intake, Carcass breakdown, Recipes, Production batches, Dryer).

| Component | Blueprint | Status | Score |
|-----------|-----------|--------|-------|
| **Yield Templates** — list, create, edit, cuts (name, yield %, PLU, sellable) | Required | Implemented; missing Price Multiplier and Phase 2–5 (rolling avg, suggested update, >5% flag) | ~70% |
| **Carcass Intake** — Steps 1–5, variance display, template select, save | Required | Implemented; missing variance actions (ACCEPT/REJECT/CALL SUPPLIER), stock of whole carcass | ~75% |
| **Carcass Breakdown** — pending list, dialog, full/partial, cuts expected vs actual, remaining, save to carcass_cuts | Required | Implemented; **missing stock_movements and inventory_items update**; missing Blockman, performance rating; balance check not blocking | ~55% |
| **Recipes** — Production → Recipes, create recipe, ingredients per batch | Required | Not implemented | 0% |
| **Production Batches** — Start Batch, actuals, stock in/out, cost per kg | Required | Not implemented | 0% |
| **Dryer** — Dryer Batches, workflow (load, dry, weigh out, stock) | Required | Not implemented | 0% |
| **Workflow: intake → breakdown → product (stock)** | Required | Breakdown does not update stock | Fails at final step |

**Overall production system completion:** **(70 + 75 + 55 + 0 + 0 + 0) / 6 ≈ 33%.**

If weighted by business impact: yield + intake + breakdown (with critical gap: no stock update) ≈ 3/6 of scope implemented, and the implemented breakdown does not complete the flow to stock. **Strict completion for “full production system” including recipes, batches, dryer and stock-accurate breakdown: ~33%.**

---

## 6. GAP SUMMARY

- **Exists:** Single production screen (carcass_intake_screen.dart) with three tabs: Yield Templates (list + create/edit template with cuts), Carcass Intake (list + New Intake dialog with Steps 1–4, variance display, save), Pending Breakdowns (list + Breakdown dialog with full/partial, expected vs actual, remaining, save to carcass_intakes + carcass_cuts). Tables used: yield_templates, carcass_intakes, carcass_cuts, suppliers.
- **Missing:** Price Multiplier on yield template cuts; Phase 2–5 (rolling average, suggested update, >5% flag); variance actions (ACCEPT/REJECT/CALL SUPPLIER) and stock of whole carcass on intake; **stock_movements and inventory_items update on breakdown**; Blockman and performance rating; Recipes screen and production recipes; Production batch screen and workflow; Dryer screen and workflow. No use of recipes/recipe_ingredients, production_batches, dryer_batches in production.
- **Incorrect:** Breakdown does not create stock_movements or update inventory; intake does not add “stock of whole carcass”; variance does not gate or offer explicit actions.
- **Impact:** Intake → breakdown → product (stock) is incomplete; stock accuracy and costing for cuts, processed items, and dryer products cannot be driven from production; Blockman performance not in app.
- **Completion:** ~33% for the full production system (yield + intake + breakdown partially done; recipes, batches, dryer 0%; critical stock update missing).

---

*Audit only. No code was modified. No fixes suggested.*
