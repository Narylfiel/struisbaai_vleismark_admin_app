# Product Form Audit — Blueprint Sections A–H

**Blueprint (single source of truth):** `AdminAppBluePrintTruth.md` §4.2 Add / Edit Product Form  
**Implementation:** `admin_app/lib/features/inventory/screens/product_list_screen.dart` — **_ProductFormDialog** (inline dialog, 4 tabs). No other product form UI found. No code changes.

---

## 1. WHAT EXISTS (with file references)

### 1.1 Form structure

| Location | Implementation |
|----------|----------------|
| **product_list_screen.dart** | **_ProductFormDialog** (lines 484–1131): StatefulWidget, 720×620 Dialog. **4 tabs only:** A — Identity, B — Pricing, C — Stock, D — Scale (lines 696–701). TabController(length: 4). Footer: Active toggle + Cancel/Save. No tabs or UI for Sections E, F, G, H. |
| **Open trigger** | product_list_screen.dart lines 89–97: `_openProduct(product)` shows dialog with `_ProductFormDialog(product, categories, onSaved: _loadData)`. |
| **Save** | Lines 571–627: builds `data` map from form controllers; `inventory_items.insert(data)` or `.update(data).eq('id', product['id'])`. PLU enabled only when product == null (line 777). |

### 1.2 Section A: Identity — implemented fields

| Blueprint field | In app? | File / notes |
|-----------------|----------|---------------|
| PLU Code (integer, locked after creation) | ✅ | Tab A. _pluController, enabled: widget.product == null (777). Validator required. Saved as plu_code. |
| Name (Full) | ✅ | Tab A. _nameController, label "Full Name *". Saved as name. |
| POS Display Name (max 20 chars) | ✅ | Tab A. _posNameController, maxLength: 20. Saved as pos_display_name; fallback to name if empty (577–578). |
| Scale Label Name (max 16 chars) | ✅ | Tab A. _scaleLabelController, maxLength: 16. Saved as scale_label_name. |
| **SKU / Barcode** | ⚠️ | Blueprint §A: listed under Identity. In app: **barcode** is in **Tab D** (Section D), not Tab A. Single field _barcodeController (1173), saved as barcode. |
| Item Type (dropdown) | ✅ | Tab A. _itemType dropdown: own_cut, own_processed, third_party_resale, service, packaging, internal. Saved as item_type. |
| Category (dropdown) | ✅ | Tab A. _selectedCategory from widget.categories (by name). Saved as category. |
| Active (toggle) | ✅ | Footer (not in tab). _isActive Switch. Saved as is_active. |
| Scale Item (toggle) | ✅ | Tab D. _scaleItem Switch. Saved as scale_item. Blueprint §A lists under Identity; app places in Scale tab. |

### 1.3 Section A: Identity — missing fields

| Blueprint field | In app? |
|-----------------|----------|
| **Sub-Category** (dropdown, dynamic from Category) | ❌ Not present. No sub_category in form or save payload. |
| **Supplier Link** (multi-select dropdown) | ❌ Not present. No supplier link in form or save payload. |

### 1.4 Section B: Pricing — implemented fields

| Blueprint field | In app? | File / notes |
|-----------------|----------|---------------|
| Current Sell Price | ✅ | Tab B. _sellPriceController, label "Sell Price (R) *". Saved as sell_price. |
| Current Cost Price | ✅ | Tab B. _costPriceController. Saved as cost_price. |
| GP % (auto-calculated) | ✅ | Tab B. _calcStat('GP %', ...) from sell/cost; red if below target (961). |
| Markup % (auto-calculated) | ✅ | Tab B. _calcStat('Markup %', ...). |
| Target Margin % (owner sets) | ✅ | Tab B. _targetMarginController. Saved as target_margin_pct. |
| Recommended Price (auto-calculated) | ✅ | Tab B. _calcStat('Recommended Price', cost/(1−target/100)). |
| VAT / Tax Group | ✅ | Tab B. _vatGroup dropdown: standard, zero_rated, exempt. Saved as vat_group. |
| Freezer Markdown % (per product) | ✅ | Tab B. _freezerMarkdownController, note "Owner sets per product — NOT a system default". Saved as freezer_markdown_pct. |
| Price Last Changed (timestamp auto) | ⚠️ | **Written on save only:** data['price_last_changed'] = DateTime.now() (605). **Not displayed** on form. Blueprint: "Auto-recorded on every price edit" and implied visible. |

### 1.5 Section B: Pricing — missing fields

| Blueprint field | In app? |
|-----------------|----------|
| **Average Cost Price** (read-only, rolling avg last 5 purchases) | ❌ Not present. No read-only field or source. |
| **Price History** (button: View History) | ❌ Not present. No button or link to price change log. |

### 1.6 Section C: Stock Control — implemented fields

| Blueprint field | In app? | File / notes |
|-----------------|----------|---------------|
| Stock Control Type (dropdown) | ✅ | Tab C. _stockControlType: use_stock_control, no_stock_control, recipe_based, carcass_linked, hanger_count. Saved as stock_control_type. |
| Unit Type (kg / units / packs) | ✅ | Tab C. _unitType dropdown: kg, units, packs. Blueprint says "Toggle"; app uses **dropdown** — same options. Saved as unit_type. |
| Allow Sell by Fraction | ✅ | Tab C. _allowFraction Switch. Saved as allow_sell_by_fraction. |
| Reorder Threshold | ✅ | Tab C. _reorderController. Saved as reorder_level. |
| Slow-Moving Trigger Days | ✅ | Tab C. _slowMovingController, note "Days without sale = slow-moving alert (per product)". Saved as slow_moving_trigger_days (default 3). |
| Shelf Life (Fresh) (days) | ✅ | Tab C. _shelfLifeFreshController. Saved as shelf_life_fresh. |
| Shelf Life (Frozen) (days) | ✅ | Tab C. _shelfLifeFrozenController. Saved as shelf_life_frozen. |

### 1.7 Section C: Stock Control — missing fields

| Blueprint field | In app? |
|-----------------|----------|
| **Pack Size** (units per pack for ordering) | ❌ Not present. No pack_size in form or save. |
| **Stock on Hand (Fresh)** (read-only) | ❌ Not present. No display of stock_on_hand_fresh. |
| **Stock on Hand (Frozen)** (read-only) | ❌ Not present. No display of stock_on_hand_frozen. |
| **Stock on Hand (Total)** (read-only) | ❌ Not present. No display of total. |
| **Storage Location(s)** (multi-select) | ❌ Not present. No storage locations in form or save. |
| **Carcass Link** (dropdown, yield template for Own-Cut) | ❌ Not present. No carcass_link / yield template in form. ("Carcass Linked" exists only as **Stock Control Type** option, not as Carcass Link dropdown.) |
| **Dryer/Biltong Product** (toggle) | ❌ Not present. No dryer/biltong toggle in form or save. |

### 1.8 Section D: Barcode & Scale — implemented fields

| Blueprint field | In app? | File / notes |
|-----------------|----------|---------------|
| Standard Barcode (EAN-13) | ✅ | Tab D. _barcodeController, label "Barcode (EAN-13)". Saved as barcode. |
| Ishida Scale Sync (toggle) | ✅ | Tab D. _ishidaSync Switch. Saved as ishida_sync. |
| Text Lookup Code | ✅ | **Tab A** in app (line 886–889). Blueprint §D lists under Barcode & Scale. Same field, different tab. Saved as text_lookup_code. |

### 1.9 Section D: Barcode & Scale — missing fields

| Blueprint field | In app? |
|-----------------|----------|
| **Barcode Prefix** (dropdown: 20 weight / 21 price / None) | ❌ Not present. No barcode_prefix in form or save. |
| **Auto-generate** button for barcode | ❌ Not present. No button next to barcode field. |

### 1.10 Sections E, F, G, H — not implemented

| Section | Blueprint | In app? |
|---------|-----------|----------|
| **E: Modifier Group Linking** | Below product form: "Modifier Groups" section; [+ Add Modifier Group]; link product to modifier groups for POS pop-ups. | ❌ No tab, no section, no UI, no modifier link in save payload. |
| **F: Production Links** | Recipe Link (dropdown), Dryer/Biltong Batch Link (dropdown), Manufactured Item (toggle). | ❌ No tab, no section, no UI, no recipe_link, dryer_batch_link, manufactured_item in form or save. |
| **G: Media & Notes** | Image (photo upload), Dietary Tags (multi-select), Allergen Info (multi-select), Internal Notes (text area). | ❌ No tab, no section, no UI, no image, dietary_tags, allergen_info, internal_notes in form or save. |
| **H: Item Activity Log** | Last edited by + date; price change history; stock adjustment history linked to stock_movements; "View Item Activity" button → filtered audit log for this PLU. | ❌ No tab, no section, no UI. No "Last edited by", no price history, no stock adjustment history, no View Item Activity button. |

---

## 2. WHAT IS MISSING (explicitly from blueprint)

### 2.1 Field-level — Sections A–D

- **A:** Sub-Category (dynamic dropdown from Category); Supplier Link (multi-select).
- **A placement:** SKU/Barcode is in blueprint Identity; in app barcode is only in Tab D (acceptable if one field; Section D still requires Barcode Prefix + Auto-generate).
- **B:** Average Cost Price (read-only); Price History (View History button); Price Last Changed **display** (value is saved but not shown on form).
- **C:** Pack Size; Stock on Hand (Fresh / Frozen / Total) read-only; Storage Location(s) multi-select; Carcass Link dropdown; Dryer/Biltong Product toggle.
- **D:** Barcode Prefix dropdown (20 / 21 / None); Auto-generate button for barcode.

### 2.2 Entire sections

- **Section E:** Modifier Group Linking — no UI, no data.
- **Section F:** Production Links — Recipe Link, Dryer/Biltong Batch Link, Manufactured Item — no UI, no data.
- **Section G:** Media & Notes — Image, Dietary Tags, Allergen Info, Internal Notes — no UI, no data.
- **Section H:** Item Activity Log — last edited by, price history, stock adjustment history, View Item Activity — no UI.

---

## 3. WHAT IS INCORRECT (deviations)

### 3.1 Placement / structure

| Item | Blueprint | App | Deviation |
|------|-----------|-----|-----------|
| **Text Lookup Code** | Section D (Barcode & Scale) | Tab A (Identity) | Placed in Identity tab instead of Barcode & Scale tab. |
| **Scale Item** | Section A (Identity) | Tab D (Scale) | Placed in Scale tab instead of Identity. |
| **SKU / Barcode** | Section A (Identity) | Tab D only | Barcode field only in Tab D; Section A does not show SKU/Barcode in Identity tab. |
| **Unit Type** | "Toggle" kg/units/packs | Dropdown (kg, units, packs) | Same options, different control type (dropdown vs toggle). |

### 3.2 Logic / behaviour

| Item | Blueprint | App | Deviation |
|------|-----------|-----|-----------|
| **Price Last Changed** | Auto-recorded on every price edit; implied visible | Set on every save (605); **not displayed** on form | User cannot see when price was last changed. |
| **Category** | "Links to categories table — syncs to POS grid" | Stored as category (string from category name); no category_id or FK verified in payload | Save uses category name; schema may expect id — not verified; behaviour may be correct if table uses name. |
| **Carcass Link** | "If Own-Cut: which yield template produces this item" | Not present | Own-Cut items cannot be linked to yield template; production and inventory link missing. |

### 3.3 Save payload vs blueprint

- **Saved fields** (from _save() data map): plu_code, name, pos_display_name, scale_label_name, barcode, text_lookup_code, category, item_type, scale_item, ishida_sync, is_active, sell_price, cost_price, target_margin_pct, freezer_markdown_pct, vat_group, stock_control_type, unit_type, allow_sell_by_fraction, reorder_level, shelf_life_fresh, shelf_life_frozen, slow_moving_trigger_days, price_last_changed, updated_at.
- **Not in payload (blueprint fields):** sub_category, supplier_link (or supplier_ids), pack_size, storage_locations, carcass_link (yield_template_id), dryer_biltong_product, barcode_prefix, image, dietary_tags, allergen_info, internal_notes, recipe_link, dryer_batch_link, manufactured_item. Modifier group links are not saved (Section E).

---

## 4. SYSTEM IMPACT (what breaks because of this)

### 4.1 POS

- **Modifier Groups (E missing):** POS cannot show "modifier pop-ups" for products (e.g. Sauce Options for T-Bone); no way to link product to modifier groups in admin.
- **Sub-Category / Category:** If POS expects sub_category for filtering or display, it is never set.
- **Barcode Prefix (D missing):** Ishida scale labels may require correct prefix (20/21); wrong or missing prefix can break scale label format.
- **Image, POS Display Name (G partial):** Image missing — POS grid button cannot show product photo; POS display name is present.

### 4.2 Production

- **Carcass Link (C missing):** Own-Cut items cannot be linked to a yield template; carcass breakdown cannot map cuts to products correctly for stock.
- **Recipe Link / Dryer/Biltong Batch Link / Manufactured Item (F missing):** Own-Processed and dryer/biltong items cannot be linked to recipes or dryer batches; production and cost tracking per blueprint cannot work.
- **Dryer/Biltong Product (C missing):** No way to mark product as dryer/biltong for production module.

### 4.3 Reporting and analytics

- **Storage Location(s) (C missing):** Stock levels and movement by location cannot be driven from product-level locations.
- **Supplier Link (A missing):** Supplier spend and reorder by supplier cannot be tied to products.
- **Price History / Item Activity (H missing):** No audit of price changes or stock adjustments for a product; compliance and investigation weaker.
- **Average Cost Price (B missing):** Margin and reporting cannot show rolling average cost from purchases.

### 4.4 Data integrity

- **Pack Size (C missing):** Ordering and pack-based reporting incomplete.
- **Stock on Hand not shown (C):** User cannot see current fresh/frozen/total in the form when editing; may rely on list view only.

---

## 5. COMPLETION % FOR THIS MODULE (product form Sections A–H)

**Module:** Add/Edit Product Form as specified in blueprint §4.2 Sections A–H.

| Section | Blueprint fields / elements | Implemented | Missing | Score |
|---------|-----------------------------|-------------|---------|-------|
| **A: Identity** | 11 (PLU, Name, POS Name, Scale Label, SKU/Barcode, Item Type, Category, Sub-Category, Supplier Link, Active, Scale Item) | 8 (PLU, Name, POS Name, Scale Label, Item Type, Category, Active, Scale Item; barcode in D) | Sub-Category, Supplier Link; SKU/Barcode not in A tab | ~70% |
| **B: Pricing** | 11 (Sell, Cost, Avg Cost, GP%, Markup%, Target%, Recommended, VAT, Freezer%, Price Last Changed, Price History) | 8 (Sell, Cost, GP%, Markup%, Target%, Recommended, VAT, Freezer%; price_last_changed saved not shown) | Average Cost read-only, Price History button, Price Last Changed display | ~65% |
| **C: Stock** | 14 (Stock Control Type, Unit, Allow Fraction, Pack Size, SOH Fresh/Frozen/Total, Reorder, Slow-Moving Days, Shelf Life Fresh/Frozen, Storage Locations, Carcass Link, Dryer/Biltong) | 7 (Stock Control Type, Unit, Allow Fraction, Reorder, Slow-Moving Days, Shelf Life Fresh/Frozen) | Pack Size, SOH Fresh/Frozen/Total, Storage Locations, Carcass Link, Dryer/Biltong Product | ~50% |
| **D: Barcode & Scale** | 4 (Standard Barcode + Auto-generate, Barcode Prefix, Ishida Sync, Text Lookup) | 3 (Barcode, Ishida Sync, Text Lookup in Tab A) | Barcode Prefix dropdown, Auto-generate button | ~70% |
| **E: Modifier Groups** | 1 (Modifier Groups section + Add Modifier Group) | 0 | Entire section | 0% |
| **F: Production Links** | 3 (Recipe Link, Dryer/Biltong Batch Link, Manufactured Item) | 0 | Entire section | 0% |
| **G: Media & Notes** | 4 (Image, Dietary Tags, Allergen Info, Internal Notes) | 0 | Entire section | 0% |
| **H: Activity Log** | 4 (Last edited by, price history, stock adjustment history, View Item Activity) | 0 | Entire section | 0% |

**Overall product form completion (Sections A–H):** **(8+8+7+3) / (11+11+14+4+1+3+4+4) ≈ 26/52 ≈ 50%** by field count, but Sections E–H are 0% each, so weighted: **(A ~70% + B ~65% + C ~50% + D ~70% + E 0% + F 0% + G 0% + H 0%) / 8 ≈ 32%**.

Strict count: **Sections A–D partially implemented; E–H not implemented.**  
**Completion % for product form (Sections A–H): ~32%.**

---

## 6. GAP SUMMARY

- **Exists:** Single product form as inline dialog in product_list_screen.dart with 4 tabs (A–D). Most of Section A (except Sub-Category, Supplier Link), most of B (except Average Cost, Price History, Price Last Changed display), about half of C (no Pack Size, SOH read-only, Storage Locations, Carcass Link, Dryer/Biltong), most of D (no Barcode Prefix, no Auto-generate). Text Lookup in Tab A; Scale Item and Barcode in Tab D.
- **Missing:** Sub-Category, Supplier Link; Average Cost Price, Price History button, Price Last Changed display; Pack Size, Stock on Hand read-only, Storage Locations, Carcass Link, Dryer/Biltong Product; Barcode Prefix, Auto-generate barcode; **entire Sections E, F, G, H** (Modifier Groups, Production Links, Media & Notes, Item Activity Log).
- **Incorrect:** Text Lookup Code in Identity instead of Barcode & Scale; Scale Item in Scale instead of Identity; Unit Type as dropdown not toggle; Price Last Changed not shown.
- **Impact:** POS modifier pop-ups and some reporting incomplete; production links (carcass, recipe, dryer) missing; no media/compliance fields; no product-level activity/price history.
- **Completion:** ~32% for product form Sections A–H (A–D partial, E–H 0%).

---

*Audit only. No code was modified. No fixes suggested.*
