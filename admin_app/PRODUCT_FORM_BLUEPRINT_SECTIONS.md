# Product Form — Blueprint Sections A–H

Blueprint §4.2: Add/Edit Product form with full field specification. Implemented in `product_list_screen.dart` (_ProductFormDialog) and `inventory_item.dart` model.

---

## 1. Data model

**File:** `lib/features/inventory/models/inventory_item.dart`

**InventoryItem** extends BaseModel with all blueprint fields:

| Section | Fields |
|--------|--------|
| A: Identity | pluCode, name, posDisplayName, scaleLabelName, barcode, itemType, category, subCategory, supplierIds, isActive, scaleItem |
| B: Pricing | sellPrice, costPrice, averageCost, targetMarginPct, freezerMarkdownPct, vatGroup, priceLastChanged |
| C: Stock | stockControlType, unitType, allowSellByFraction, packSize, stockOnHandFresh/Frozen, reorderLevel, slowMovingTriggerDays, shelfLifeFresh/Frozen, storageLocationIds, carcassLinkId, dryerBiltongProduct |
| D: Barcode/Scale | barcodePrefix, ishidaSync, textLookupCode |
| E: Modifiers | modifierGroupIds |
| F: Production | recipeId, dryerProductType, manufacturedItem |
| G: Media/Notes | imageUrl, dietaryTags, allergenInfo, internalNotes |
| H: Activity | lastEditedBy, lastEditedAt (read-only) |

Computed: stockOnHandTotal, gpPct, recommendedPrice. fromJson/toJson, validate.

---

## 2. Supabase schema

**File:** `supabase/migrations/007_inventory_items_blueprint_sections.sql`

Adds columns to `inventory_items` only if the table exists (DO block):

- **A:** sub_category TEXT, supplier_ids JSONB  
- **B:** average_cost, price_last_changed  
- **C:** pack_size, storage_location_ids JSONB, carcass_link_id UUID, dryer_biltong_product BOOLEAN  
- **D:** barcode_prefix TEXT  
- **E:** modifier_group_ids JSONB  
- **F:** recipe_id UUID, dryer_product_type TEXT, manufactured_item BOOLEAN  
- **G:** image_url, dietary_tags JSONB, allergen_info JSONB, internal_notes TEXT  
- **H:** last_edited_by UUID, last_edited_at TIMESTAMPTZ  

Existing columns (from POS or prior migrations): plu_code, name, pos_display_name, scale_label_name, barcode, category, item_type, scale_item, ishida_sync, is_active, sell_price, cost_price, target_margin_pct, freezer_markdown_pct, vat_group, stock_control_type, unit_type, allow_sell_by_fraction, reorder_level, slow_moving_trigger_days, shelf_life_fresh, shelf_life_frozen, text_lookup_code.

---

## 3. UI — Form structure (8 tabs)

**File:** `lib/features/inventory/screens/product_list_screen.dart`

| Tab | Section | Content |
|-----|---------|--------|
| A — Identity | §4.2 A | PLU Code * (locked on edit), Full Name *, POS Display Name (max 20), Scale Label Name (max 16), Category, Sub-Category, Item Type (Own-Cut / Own-Processed / Third-Party Resale / Service / Packaging / Internal), Active, Scale Item |
| B — Pricing | §4.2 B | Sell Price *, Cost Price, Target Margin %, Freezer Markdown % (per product), VAT Group (Standard / Zero-Rated / Exempt). Read-only: GP %, Markup %, Recommended Price |
| C — Stock | §4.2 C | Stock Control Type, Unit Type (kg/units/packs), Allow Sell by Fraction, Pack Size, Reorder Level, Slow Moving Trigger (days), Shelf Life Fresh/Frozen (days), Dryer/Biltong Product toggle |
| D — Barcode/Scale | §4.2 D | Standard Barcode (EAN-13), Barcode Prefix (20 weight / 21 price / None), Scale Item, Ishida Scale Sync, Text Lookup Code. Note: PLU = Scale Code |
| E — Modifiers | §4.2 E | Modifier Group Linking: FilterChips for existing modifier groups; [+ Add] = select groups to show at POS for this product |
| F — Production | §4.2 F | Recipe Link (Own-Processed), Dryer/Biltong Product Type (Biltong / Droewors / Chilli Bites / Other), Manufactured Item toggle |
| G — Media/Notes | §4.2 G | Image URL, Dietary Tags (Halal, Grass-fed, Free-range, Organic, Game, Venison), Allergen Info (multi-select), Internal Notes (owner-only) |
| H — Activity | §4.2 H | Last edited by/at (read-only). Buttons: View Item Activity / Movement History (opens movement history dialog), View Price History (placeholder) |

Dialog: 760×680, TabBar isScrollable: true, 8 tabs.

---

## 4. Field mapping (UI → DB)

| UI field | DB column | Validation |
|----------|-----------|------------|
| PLU Code | plu_code | Required, integer, unique; disabled on edit |
| Full Name | name | Required |
| POS Display Name | pos_display_name | Max 20; default name if empty |
| Scale Label Name | scale_label_name | Max 16 (trimmed in save) |
| Barcode | barcode | Optional |
| Category | category | From categories |
| Sub-Category | sub_category | Optional |
| Item Type | item_type | own_cut \| own_processed \| third_party_resale \| service \| packaging \| internal |
| Active | is_active | Boolean |
| Scale Item | scale_item | Boolean |
| Sell Price | sell_price | Number |
| Cost Price | cost_price | Number |
| Target Margin % | target_margin_pct | Number |
| Freezer Markdown % | freezer_markdown_pct | Per product |
| VAT Group | vat_group | standard \| zero_rated \| exempt |
| Stock Control Type | stock_control_type | use_stock_control \| no_stock_control \| recipe_based \| carcass_linked \| hanger_count |
| Unit Type | unit_type | kg \| units \| packs |
| Allow Sell by Fraction | allow_sell_by_fraction | Boolean |
| Pack Size | pack_size | Number, default 1 |
| Reorder Level | reorder_level | Number |
| Slow Moving Trigger Days | slow_moving_trigger_days | Integer, default 3 |
| Shelf Life Fresh/Frozen | shelf_life_fresh, shelf_life_frozen | Integer |
| Storage Location(s) | storage_location_ids | JSONB array (state; load from stock_locations for chips) |
| Carcass Link | carcass_link_id | UUID (yield template) |
| Dryer/Biltong Product | dryer_biltong_product | Boolean |
| Barcode Prefix | barcode_prefix | 20 \| 21 \| null |
| Ishida Sync | ishida_sync | Boolean |
| Text Lookup Code | text_lookup_code | Optional |
| Modifier Group IDs | modifier_group_ids | JSONB array |
| Recipe ID | recipe_id | UUID |
| Dryer Product Type | dryer_product_type | biltong \| droewors \| chilli_bites \| other |
| Manufactured Item | manufactured_item | Boolean |
| Image URL | image_url | Optional |
| Dietary Tags | dietary_tags | JSONB array |
| Allergen Info | allergen_info | JSONB array |
| Internal Notes | internal_notes | Text |
| Last edited | last_edited_at, last_edited_by | Set on save (client can set last_edited_at) |

---

## 5. Validation rules

- **Required:** PLU Code (on create), Full Name.
- **PLU:** Disabled when editing (cannot change after creation).
- **POS Display Name:** If empty, saved as Full Name.
- **Scale Label Name:** Truncated to 16 chars on save.
- **Numeric:** sell_price, cost_price, reorder_level, pack_size, shelf_life_*, slow_moving_trigger_days — parsed; invalid treated as null or default where appropriate.

---

## 6. Persistence

- **Save:** Single `inventory_items.insert(data)` or `.update(data).eq('id', product.id)`. All fields in the map; null/empty optional fields omitted or set to null as above.
- **Load:** Product list loads `inventory_items` with `select('*')`; edit populates form from `widget.product` in `_populateForm`.
- **Modifier groups / recipes:** Loaded in `initState` from `modifier_groups` and `recipes` for dropdowns and chips.

---

## 7. Files updated/created

| File | Change |
|------|--------|
| `lib/features/inventory/models/inventory_item.dart` | **New.** InventoryItem model with Sections A–H, toJson/fromJson, validate. |
| `supabase/migrations/007_inventory_items_blueprint_sections.sql` | **New.** ADD COLUMN IF NOT EXISTS for blueprint fields on inventory_items. |
| `lib/features/inventory/screens/product_list_screen.dart` | **Updated.** _ProductFormDialog: 8 tabs (A–H), new state/controllers (sub_category, pack_size, storage_location_ids, carcass_link_id, dryer_biltong_product, barcode_prefix, modifier_group_ids, recipe_id, dryer_product_type, manufactured_item, image_url, dietary_tags, allergen_info, internal_notes). _buildTabE (Modifiers), _buildTabF (Production), _buildTabG (Media/Notes), _buildTabH (Activity). Save map extended; _loadModifierGroups, _loadRecipes; DropdownButtonFormField uses value (not initialValue). Dialog 760×680, isScrollable tabs. |
| `PRODUCT_FORM_BLUEPRINT_SECTIONS.md` | **New.** This file. |

---

## 8. Data flow (end-to-end)

1. **Open form:** Product list → Add Product or Edit (row tap) → _ProductFormDialog(product, categories, onSaved).
2. **Load:** If product != null, _populateForm sets all controllers and state from product map. initState loads modifier_groups and recipes.
3. **User edits:** Tabs A–H; required validators on PLU and Name.
4. **Save:** _save() builds data map (all fields), validate(); insert or update inventory_items; onSaved() → _loadData(); Navigator.pop.
5. **Activity (H):** View Item Activity opens showMovementHistoryDialog(context, product). Price History shows SnackBar placeholder (audit log by PLU can be wired later).

Product form is complete per blueprint Sections A–H with validation and full save/update.
