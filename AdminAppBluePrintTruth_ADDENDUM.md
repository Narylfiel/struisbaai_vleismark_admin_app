# Admin App Blueprint — Addendum

**Parent document:** [AdminAppBluePrintTruth.md](AdminAppBluePrintTruth.md)  
**Purpose:** Requirements and operational needs identified from real-world use and audits that extend or supplement the blueprint. Use alongside the blueprint for future audits and implementation planning.  
**Date:** February 2026

---

## 1. RECIPE → PRODUCT LINKING

**Requirement:** When creating a recipe, the user MUST have the option to:
- [ ] Link to existing product
- [ ] Create new product

**Rationale:** Creating a recipe must not automatically create a duplicate inventory product. Validation rules must prevent duplication.

**Applies to:** Production module, Recipe form, Production Batch flow

---

## 2. STOCK MEASUREMENT PRECISION (SYSTEM-WIDE)

**Requirement:** The system must support:
- **Grams:** 1g precision
- **Kilograms:** 3 decimal places

**Applies to:** POS, Inventory, Production, Reports (all stock-related inputs and display)

**Rationale:** Butchery operations require precise weight tracking for costing, portioning, and compliance.

---

## 3. SUPPLIER PRODUCT MAPPING (PROCUREMENT)

**Requirement:** Products must support:
- Multiple suppliers per product
- Supplier-specific product codes (NOT same as internal SKU/PLU)
- Pricing per supplier

**Use cases:** Purchase orders, supplier comparison (price/availability)

**Implementation:** New relational table `product_suppliers`; UI in Product Form

---

## 4. PURCHASE ORDER FLOW

**Requirement:** Analytics → Create Purchase Order must:
1. Select supplier first
2. Load ONLY that supplier's products
3. Allow multiple products per PO
4. Enter quantities per product
5. Save, download, send

**Rationale:** Current flow is broken; procurement cannot create POs from reorder recommendations.

---

## 5. PRODUCTION SPLIT LOGIC (REAL-WORLD CASE)

**Requirement:** Same recipe must support split into multiple outputs.

**Example:** Traditional Boerewors batch split into:
- Boerewors (casing)
- Hamburger patties (moulded)

**Requirements:**
- Single batch → multiple outputs
- No duplication of ingredients
- Output allocation tracking

**Implementation:** Extend production_batches / production_batch_outputs; inventory update per output

---

## 6. PRODUCT TYPES (PROCESSING LOGIC)

**Requirement:** Add product types to drive processing behavior:
- **Raw:** No processing
- **Portioned:** Cutting/portioning only
- **Manufactured:** Recipe-based production

**Rationale:** Not all products are manufactured; Production and Inventory behavior must differ by type.

---

## 7. POS CUSTOMER TRACKING

**Requirement:** Every sale must store:
- Items purchased
- Linked customer

**Fallback:** If no loyalty account, assign to default "POS Customer"

**Rationale:** Required for analytics, reporting, and customer insights.

---

## 8. REPORT SYSTEM — TEMPLATES INDEPENDENT OF DATA

**Requirement:** Reports MUST:
- Render layout even with zero data
- Show professional document structure
- Produce output when export/print is triggered

**Rationale:** Current behavior: export/print reports success but no output. Report templates must exist independently of data.

---

## 9. KEYBOARD INPUT (WINDOWS)

**Requirement:** Full keyboard compatibility, especially for numeric inputs. Users must be able to type numbers using the keyboard, not only the mouse.

**Rationale:** Operational efficiency; Windows desktop users expect keyboard input.

---

## 10. BULK IMPORT / EXPORT

**Requirement:**
- **Suppliers:** CSV import/export
- **Stock Take:** Import/export functionality

**Rationale:** Data portability; migration; external system integration.

---

## 11. BARCODE SCANNING (ADMIN ONLY)

**Requirement:** Stock take must support:
- Barcode scanning
- Counting via scan

**Scope:** Admin app only. Must NOT work in POS app (different use case).

---

## 12. MULTI-APP ECOSYSTEM (CORE ARCHITECTURE)

**Requirement:** System must support multiple apps:
- Admin App
- POS App
- Customer Loyalty App
- Additional apps (future)

**Requirements:**
- Shared Supabase backend
- Real-time sync between apps
- Data consistency guaranteed

**Rationale:** Add as CORE ARCHITECTURE PRINCIPLE for all design decisions.

---

## 13. RESPONSIVE DESIGN

**Requirement:** Admin app must:
- Work on Windows (primary)
- Adapt to mobile screens where possible

**Rationale:** Owner/manager may need occasional mobile access for approvals or alerts.

---

## 14. SYSTEM OBJECTIVE ENHANCEMENT (BUSINESS GOALS)

**Requirement:** The system must actively help:
- Reduce waste
- Prevent over-ordering
- Optimize supplier selection (price vs availability)
- Increase profitability through analytics

**Influences:** Analytics module, Reorder recommendations, Supplier comparison logic, Event/holiday intelligence, Shrinkage alerts.

---

## 15. BUG FIXES (FROM USER TESTING)

| Bug | Description | Priority |
|-----|-------------|----------|
| Inventory Modifiers screen | Error when opening Modifiers tab | Critical |
| HR AWOL | Requires login incorrectly when Owner already logged in | Critical |
| Analytics → Create Purchase Order | Not working; flow broken | Critical |

---

## REVISION HISTORY

| Date | Change |
|------|--------|
| Feb 2026 | Initial addendum; requirements from Master Implementation Plan update |
