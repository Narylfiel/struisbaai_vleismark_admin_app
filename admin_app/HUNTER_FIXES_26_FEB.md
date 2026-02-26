# Hunter Module Fixes - February 26, 2026

## Summary
Implemented three major enhancements to the hunter module: materials unit selector with cost calculation, edit/delete functionality for hunter jobs, and professional PDF job cards.

---

## FIX 1 — Materials Unit Selector + Cost Calculation ✅

### Changes Made:

**A) Unit Selector:**
- Added static unit options: `kg`, `g`, `units`, `packs`, `litres`, `ml`
- Replaced hardcoded `'kg'` TextFormField with DropdownButtonFormField
- Unit auto-fills from `inventory_items.unit_type` when product is selected
- User can override unit selection per material row

**B) Cost Calculation:**
- Added `cost_price` to inventory_items query in `_loadData()`
- Material rows now include:
  - `unit_cost` field (auto-filled from `inventory_items.cost_price`)
  - `line_total` field (calculated as `qty × unit_cost`)
- Unit cost is editable (user can override auto-filled value)
- Line total updates automatically when quantity or unit cost changes
- Added helper text: "Auto-filled from inventory"

**C) Charge Integration:**
- Updated `_estimatedCharge` getter to include materials costs
- Total charge now = services charges + materials line totals
- Charge preview at bottom of form shows combined total

**D) Data Persistence:**
- Updated `materials_list` JSONB structure to include:
  ```json
  {
    "item_id": "uuid",
    "name": "Product Name",
    "quantity": 2,
    "unit": "kg",
    "unit_cost": 45.00,
    "line_total": 90.00
  }
  ```

**Files Modified:**
- `lib/features/hunter/screens/job_intake_screen.dart`

**UI Changes:**
- Material row layout changed from single row to two-row layout:
  - Row 1: [Product dropdown] [Qty] [Unit dropdown] [Remove button]
  - Row 2: [Unit Cost field] [Line Total display (read-only)]
- Line total displayed in grey box with bold text
- Unit cost field shows helper text below

---

## FIX 2 — Edit and Delete Hunter Jobs ✅

### Changes Made:

**A) JobIntakeScreen - Edit Mode Support:**
- Added optional `existingJob` parameter to constructor
- Added `_prefillFromExistingJob()` method that loads:
  - Basic fields (hunter name, phone, job date, processing notes)
  - Species list (with species_id, name, estimated_weight, count)
  - Services list (with service_id, name, quantity, notes)
  - Materials list (with all cost fields)
  - Processing options (all checkboxes and selected cuts)
- Modified `initState()` to call prefill when editing vs. empty rows when new
- AppBar title shows:
  - `"Edit Hunter Job — HJ-XXXXXXXX"` when editing
  - `"New Hunter Job Intake"` when creating new

**B) Save Method - UPDATE vs INSERT:**
- Modified `_save()` to check for `existingJob`
- When editing:
  - Uses `.update(payload).eq('id', existingJob!['id'])`
  - Preserves existing `status` and `paid` fields
- When creating new:
  - Uses `.insert(payload)` as before
  - Sets `status: 'intake'` and `paid: false`

**C) Job List Screen - Edit/Delete UI:**
- Added `_editJob()` method:
  - Checks status is `'intake'` or `'processing'` before allowing edit
  - Shows warning if status is `'ready'`, `'completed'`, or `'cancelled'`
  - Navigates to `JobIntakeScreen(existingJob: job)`
- Added `_confirmDeleteJob()` method:
  - Shows confirmation dialog: "Delete job HJ-XXXXXXXX? This cannot be undone."
  - Hard deletes from `hunter_jobs` table (`.delete().eq('id', job['id'])`)
  - Allows delete on any status
  - Refreshes list after successful delete
- Updated job card actions row to show three icon buttons:
  - Edit (pencil icon)
  - Delete (trash icon in red)
  - Details (arrow icon)
- Widened actions column from 80 to 120 pixels

**Files Modified:**
- `lib/features/hunter/screens/job_intake_screen.dart`
- `lib/features/hunter/screens/job_list_screen.dart`

**Validation Rules:**
- Edit: Only `intake` or `processing` status jobs
- Delete: All statuses (with owner permission check can be added later)

---

## FIX 3 — Professional Job Card PDF ✅

### Changes Made:

**PDF Layout:**
Completely redesigned the `_printPdfInvoice()` method to generate a professional job card with the following sections:

**1. Page Header:**
- Business logo placeholder (80×80 grey box with "LOGO" text)
- Business name (right-aligned, 20pt bold)
- Address, phone, email (right-aligned, 10pt)
- "HUNTER JOB CARD" title (center, 22pt bold)
- Job number and date (center, 12pt): `"Job Number: HJ-XXXXXXXX  |  Date: DD/MM/YYYY"`
- Horizontal divider line

**2. Customer Section:**
- Grey box with border containing:
  - Hunter Name (bold)
  - Contact phone
  - Job Date
  - Status (using `HunterJobStatusExt.fromDb()` for display label)

**3. Species & Animals Table:**
- Headers: Species | Est. Weight (kg) | Count | Notes
- Data from `species_list` JSONB
- Full table border with grey header row

**4. Services Table:**
- Headers: Service | Qty | Unit Price | Total
- Data from `services_list` JSONB
- Full table border

**5. Materials Table:**
- Only shown if `materials_list` is not empty
- Headers: Material/Ingredient | Qty | Unit | Unit Cost | Total
- Shows cost data with currency formatting
- Full table border

**6. Processing Instructions Box:**
- Free-text instructions from `processing_instructions` field
- Checkboxes in 2 columns (8 total):
  - Left: Skin, Remove Head, Remove Feet, Halaal
  - Right: Split Carcass, Quarter, Whole, Kosher
- Checkboxes rendered with actual X marks when checked
- Grey background box with border

**7. Totals Box (Right-aligned):**
- Services Total: R XXX.XX
- Materials Total: R XXX.XX
- Divider line
- TOTAL CHARGE: R XXX.XX (bold)

**8. Footer:**
- Signature lines: "Authorized by: _____ Date: _____"  |  "Customer signature: _____ Date: _____"
- VAT number (if available) centered at bottom

**Data Loading:**
- Loads business settings from `business_settings` table
- Fetches: `business_name`, `address`, `phone`, `email`, `vat_number`
- Falls back to generic "Business" if settings not available

**File Saving:**
- Saves to Downloads folder using ExportService pattern
- Filename format: `job_card_HJ_XXXXXXXX_YYYY-MM-DD.pdf`
- Shows SnackBar with full file path for 5 seconds
- Falls back to `Printing.layoutPdf()` if Downloads folder unavailable

**Helper Methods:**
- Added `_pdfCheckbox()` widget builder for rendering checkboxes with labels

**Files Modified:**
- `lib/features/hunter/screens/job_summary_screen.dart`

**New Imports Added:**
- `dart:io` (for File operations)
- `path_provider` (for getDownloadsDirectory)

---

## Testing Recommendations

### FIX 1 - Materials Cost:
1. Create new hunter job
2. Add material row, select product
3. Verify unit dropdown shows all 6 options
4. Verify unit cost auto-fills from inventory
5. Change quantity and verify line total updates
6. Override unit cost manually
7. Verify charge preview at bottom includes material cost
8. Save and check `materials_list` JSONB in database

### FIX 2 - Edit/Delete:
1. **Edit Test:**
   - Click edit icon on intake job
   - Verify title shows "Edit Hunter Job — HJ-XXXXXXXX"
   - Verify all fields are pre-filled
   - Modify species, services, materials
   - Save and verify UPDATE (not INSERT)
   - Check database for single updated record
2. **Edit Restriction:**
   - Try editing ready/completed job
   - Verify warning message appears
3. **Delete Test:**
   - Click delete icon on any job
   - Verify confirmation dialog shows job number
   - Confirm delete and verify job removed from database
   - Verify list refreshes automatically

### FIX 3 - Professional PDF:
1. Navigate to completed hunter job summary
2. Click "Print PDF Invoice"
3. Verify PDF opens with all sections:
   - Header with business info
   - Customer box
   - Species table
   - Services table
   - Materials table (if materials exist)
   - Processing instructions with checkboxes
   - Totals box
   - Footer with signature lines
4. Check Downloads folder for saved PDF file
5. Verify filename format: `job_card_HJ_XXXXXXXX_2026-02-26.pdf`

---

## Database Schema Notes

**Confirmed hunter_jobs columns used:**
- `id`, `job_date`, `hunter_name`, `contact_phone`, `species`, `weight_in`
- `estimated_weight`, `processing_instructions`, `status`, `charge_total`
- `total_amount`, `paid`, `animal_count`, `animal_type`, `customer_name`
- `customer_phone`, `species_list`, `services_list`, `materials_list`
- `processing_options`, `created_at`, `updated_at`

**materials_list JSONB structure updated:**
```json
[
  {
    "item_id": "uuid-string",
    "name": "Salt",
    "quantity": 2.5,
    "unit": "kg",
    "unit_cost": 15.00,
    "line_total": 37.50
  }
]
```

---

## Files Modified

1. ✅ `lib/features/hunter/screens/job_intake_screen.dart`
   - Added unit options constant
   - Updated material row UI (two-row layout)
   - Added cost_price to inventory query
   - Updated charge calculation
   - Added existingJob parameter
   - Added prefill logic for editing
   - Modified save to handle UPDATE vs INSERT

2. ✅ `lib/features/hunter/screens/job_list_screen.dart`
   - Added `_editJob()` method
   - Added `_confirmDeleteJob()` method
   - Updated job card UI with 3 action buttons
   - Widened actions column

3. ✅ `lib/features/hunter/screens/job_summary_screen.dart`
   - Completely rewrote `_printPdfInvoice()` method
   - Added `_pdfCheckbox()` helper
   - Added business settings loading
   - Implemented professional PDF layout
   - Added Downloads folder saving

---

## Status: ✅ ALL FIXES COMPLETE

- FIX 1 (Materials unit + cost): ✅ Complete
- FIX 2 (Edit/Delete jobs): ✅ Complete
- FIX 3 (Professional PDF): ✅ Complete

All changes compiled successfully with no linter errors.
