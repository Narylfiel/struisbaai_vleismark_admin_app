APP 2: ADMIN & BACK-OFFICE APPLICATION
COMPLETE BLUEPRINT — VERSION 2.0 (UPDATED)
The Butchery OS — Management, Production, Inventory, HR, Reports


Platform
	Windows 10/11 Desktop
	Framework
	Flutter Desktop (Dart)
	Users
	Owner (full access), Manager (limited access)
	Database
	Supabase (PostgreSQL) — online required for most functions
	Local Cache
	Isar (for production workflows that need offline)
	Integration
	Reads POS transaction data; writes product/price data that POS consumes
	Version
	v2.0 — Updated February 2026 | PTY Ltd Effective: 1 March 2026
	

📌 NOTE: This app is SEPARATE from the POS. It manages everything BEHIND the counter: inventory, production, staff, finances, analytics. The POS only sells.


1. DESIGN PRINCIPLES
1.1 Separation from POS
POS App
	Admin App
	Sells meat
	Manages the business
	Cashier-focused
	Owner/Manager-focused
	Speed is #1 priority
	Completeness is #1 priority
	Offline-first (Isar)
	Online-preferred (Supabase direct)
	Full-screen checkout
	Multi-panel dashboard
	Minimal navigation
	Deep navigation (15+ modules)
	Reads product data
	Writes product data
	Writes transactions
	Reads transaction data for reports
	

1.2 Data Flow Between Apps
Direction
	Data
	Flow
	Admin → POS
	Products, prices, categories
	Writes to Supabase → POS reads via Isar sync
	Admin → POS
	Staff profiles, PINs
	Writes → POS reads for login/override
	Admin → POS
	Modifier groups
	Writes → POS reads for pop-ups
	Admin → POS
	Tax rates
	Writes → POS reads for calculation
	Admin → POS
	Business accounts
	Writes → POS reads for account sales
	Admin → POS
	Settings (Blockman verify)
	Writes → POS reads config flags
	POS → Admin
	Transaction data
	POS writes via Supabase → Admin reads
	POS → Admin
	Till sessions / Z-reports
	POS writes → Admin reads
	POS → Admin
	Audit logs
	POS writes → Admin reads
	

1.3 Who Sees What
Feature
	Owner
	Manager
	Dashboard (all widgets)
	✅ Full
	✅ Limited financial
	Inventory management
	✅
	✅
	Carcass intake / breakdown
	✅
	✅
	Production (recipes, batches)
	✅
	✅
	Yield templates
	✅ Create/Edit
	👁 View only
	HR / Staff profiles
	✅
	✅ (own team)
	Payroll
	✅
	❌
	Bookkeeping / Ledger
	✅
	❌
	P&L / Cash flow
	✅
	❌
	Reports
	✅ All
	✅ Operational only
	Settings / Business config
	✅
	❌
	Audit logs
	✅
	👁 View only
	Supplier management
	✅
	✅
	Hunter job management
	✅
	✅
	Business accounts
	✅ Create/Edit
	✅ View/Use
	Analytics / Shrinkage
	✅
	👁 View only
	Customer management
	✅
	✅
	

2. AUTHENTICATION
2.1 PIN Login (Same as POS)
Same PIN system — but only Owner and Manager PINs grant access. Cashier/Blockman PINs are rejected with "Access restricted to Admin staff."


2.2 Role Routing
Role
	Access
	Owner
	Full dashboard, all modules
	Manager
	Dashboard (limited), operational modules
	Cashier
	❌ Rejected
	Blockman
	❌ Rejected
	

3. MAIN DASHBOARD
3.1 Owner Dashboard Layout
The main screen after login — shows all key business metrics at a glance.


 ┌─────────────────────────────────────────────────────────────────────┐
 │  [👤 Owner: Johan]   BOTHA'S BUTCHERY — ADMIN        [🔔] [⚙️]    │
 ├──────────────┬──────────────────────────────────────────────────────┤
 │              │  TODAY'S OVERVIEW                                    │
 │  SIDEBAR     │  ┌──────────┬──────────┬──────────┬──────────┐      │
 │              │  │  SALES   │ TRANS-   │   AVG    │  MARGIN  │      │
 │ 📊 Dashboard │  │ R12,340  │ ACTIONS  │  BASKET  │  38.2%   │      │
 │ 🥩 Inventory │  │ +7.2%    │    47    │ R262.56  │  +1.3%   │      │
 │ 🔪 Production│  └──────────┴──────────┴──────────┴──────────┘      │
 │ 🦌 Hunter    │                                                      │
 │ 👥 HR/Staff  │  ALERTS                                              │
 │ 💳 Accounts  │  🔴 Shrinkage: T-Bone gap 2.4kg (27%)               │
 │ 📒 Bookkeep  │  🟡 Reorder: Mince stock below threshold             │
 │ 📈 Analytics │  🟡 Overdue: Giovanni's R2,450 — 3 days overdue      │
 │ 📋 Reports   │  🔵 HR: Sarah leave request (pending)                │
 │ 👥 Customers │                                                      │
 │ 📝 Audit Log │  SALES CHART (Last 7 Days)                           │
 │ ⚙️ Settings  │  ──────────────────────────────────                  │
 │              │  CLOCK-IN STATUS                                     │
 │              │  🟢 Johan (Owner) - 07:15                            │
 │              │  🟢 Mike (Manager) - 07:30                           │
 │              │  🟢 Sarah (Cashier) - 07:28                          │
 │              │  🔴 Pieter (Blockman) - Not clocked in               │
 └──────────────┴──────────────────────────────────────────────────────┘


3.2 Dashboard Widgets
Widget
	Data Source
	Refresh
	Today's Sales
	transactions (today)
	Real-time (Supabase subscription)
	Transaction Count
	transactions (today)
	Real-time
	Average Basket
	Sales ÷ Transactions
	Real-time
	Gross Margin
	(Revenue - COGS) ÷ Revenue
	Hourly
	Alerts
	shrinkage_alerts, reorder_recommendations
	Real-time
	Sales Chart
	7-day aggregate
	Hourly
	Staff Clock-In
	timecards (today)
	Real-time
	Top Products
	sales aggregate (today)
	Every 30 min
	

4. INVENTORY MANAGEMENT
📌 NOTE: The Admin App is the CREATION POINT for all stock, categories, PLUs, and ledger accounts. All new items, categories, prices, barcodes, or chart of accounts entries are created here.


4.1 Categories
Sidebar → 🥩 Inventory → Categories
Category
	Colour Code
	Notes
	Beef
	🔴 Red
	

	Pork
	🩷 Pink
	

	Lamb
	🟤 Brown
	Includes all grades: Premium, AB Skaap, B3 Skaap
	Chicken
	🟡 Yellow
	

	Processed (Boerewors, Patties, Biltong, Droewors)
	🟠 Orange
	Own-made and branded
	Drinks
	🔵 Blue
	

	Spices & Condiments
	🟢 Green
	

	Game & Venison
	🟤 Dark Brown
	Springbok, Kudu, Ostrich, etc.
	Other
	⚫ Grey
	

	Owner can add, edit, and reorder categories. Categories sync to POS for grid tabs.


4.2 Product Management (PLU Management)
Sidebar → 🥩 Inventory → Products
Product list with search, filter by category, sort by name/price/stock.


📌 NOTE: PLU Code = Scale Code. The PLU number is NEVER changed after creation — it is the Ishida scale code and cashier shortcut. Changing it breaks scale labels and existing workflows.


Add / Edit Product Form — Full Field Specification
SECTION A: Identity
Field
	Type
	Example
	Notes
	PLU Code
	Integer (locked after creation)
	1001
	Unique — cashier shortcut AND scale code. Cannot be changed.
	Name (Full)
	Text
	T-Bone Steak
	Back-office full description
	POS Display Name
	Text (max 20 chars)
	T-Bone Steak
	Shown on POS button and receipt
	Scale Label Name
	Text (max 16 chars)
	T-Bone Steak
	Prints on Ishida label
	SKU / Barcode
	Text
	6001234567890
	Standard barcode (non-scale items)
	Item Type
	Dropdown
	Own-Cut
	Own-Cut / Own-Processed / Third-Party Resale / Service / Packaging / Internal
	Category
	Dropdown
	Beef
	Links to categories table — syncs to POS grid
	Sub-Category
	Dropdown
	Steaks
	Dynamic — options based on Category selected
	Supplier Link
	Multi-select dropdown
	Karan Beef
	Which suppliers deliver this item
	Active
	Toggle
	Yes
	Inactive = hidden from POS automatically
	Scale Item
	Toggle
	Yes
	If yes: barcode prefix required; syncs to Ishida
	

SECTION B: Pricing
🔄 CHANGED: Single retail price only — no price levels. Freezer markdown % is set per product individually by the owner (NOT a fixed 25% system default).


Field
	Type
	Example
	Notes
	Current Sell Price
	Currency
	R120.00
	Per kg or per unit — retail price
	Current Cost Price
	Currency
	R72.00
	From last supplier invoice — for margin calc
	Average Cost Price
	Auto-calculated
	R71.40
	Rolling average of last 5 purchases — READ ONLY
	GP %
	Auto-calculated
	40%
	(Sell − Cost) ÷ Sell × 100
	Markup %
	Auto-calculated
	66.7%
	(Sell − Cost) ÷ Cost × 100
	Target Margin %
	Number (owner sets)
	40%
	System warns in red if GP% falls below this
	Recommended Price
	Auto-calculated
	R120.00
	Cost ÷ (1 − Target Margin%) — shown as a guide
	VAT / Tax Group
	Dropdown
	Standard (15%)
	Standard (15%) / Zero-Rated (0%) / Exempt (0%)
	Freezer Markdown %
	Number (owner sets per product)
	20%
	🔄 Owner sets individually per product. NOT a fixed 25% default.
	Price Last Changed
	Timestamp (auto)
	06 Feb 2026 14:23
	Auto-recorded on every price edit
	Price History
	Button: View History
	—
	Full log of all price changes with user, date, old/new price
	

SECTION C: Stock Control
Field
	Type
	Example
	Notes
	Stock Control Type
	Dropdown
	Use Stock Control
	Use Stock Control / No Stock Control / Recipe-Based / Carcass-Linked / Hanger Count
	Unit Type
	Toggle
	kg
	kg / units / packs
	Allow Sell by Fraction
	Toggle
	Yes
	For kg-sold items (scale items always Yes)
	Pack Size
	Number
	1
	Units per pack for ordering purposes
	Stock on Hand (Fresh)
	Read-only
	8.2 kg
	Counter / display fridge quantity
	Stock on Hand (Frozen)
	Read-only
	4.3 kg
	Deep freezer quantity
	Stock on Hand (Total)
	Auto-calculated
	12.5 kg
	Fresh + Frozen combined
	Reorder Threshold
	Number
	5.0 kg
	Triggers reorder alert on dashboard
	Slow-Moving Trigger Days
	Number (owner sets per product)
	3
	🆕 How many days without a sale = slow-moving alert. Set per product (e.g. T-Bone=3 days, Biltong=14 days, Spices=45 days).
	Shelf Life (Fresh)
	Days
	3
	Alert countdown from intake date
	Shelf Life (Frozen)
	Days
	90
	Separate frozen shelf life tracking
	Storage Location(s)
	Multi-select
	Display Fridge 1
	🆕 Display Fridge 1/2/3, Walk-In Fridge, Deep Freezer 1–7, Deli Counter, Dry Store
	Carcass Link
	Dropdown
	Beef Side — Standard
	If Own-Cut: which yield template produces this item
	Dryer/Biltong Product
	Toggle
	No
	🆕 If Yes: links to Dryer/Biltong production module
	

SECTION D: Barcode & Scale
Field
	Type
	Example
	Notes
	Standard Barcode (EAN-13)
	Text + Auto-generate button
	6001234567890
	For non-scale packaged items
	Barcode Prefix
	Dropdown
	20 (weight)
	20 (weight-embedded) / 21 (price-embedded) / None — for Ishida scale items
	Ishida Scale Sync
	Toggle
	Yes
	Send this PLU to scale? Syncs name + price
	Text Lookup Code
	Text
	tbone
	Alternative search keyword for POS
	

SECTION E: Modifier Group Linking
Below the product form — 'Modifier Groups' section:
* When this product is sold, show these modifier pop-ups at POS
* [+ Add Modifier Group] — select from existing groups
* Example: T-Bone — linked to 'Sauce Options' modifier group


SECTION F: Production Links
Field
	Type
	Notes
	Recipe Link
	Dropdown
	If Own-Processed: links to Recipe in Production module
	Dryer/Biltong Batch Link
	Dropdown
	🆕 If droewors/biltong: links to Dryer Production module
	Manufactured Item
	Toggle
	Triggers cost-of-production tracking for margin analysis
	

SECTION G: Media & Notes
Field
	Type
	Notes
	Image
	Photo upload
	Optional — shown on POS grid button
	Dietary Tags
	Multi-select
	Halal / Grass-fed / Free-range / Organic / Game / Venison
	Allergen Info
	Multi-select
	For compliance and customer queries
	Internal Notes
	Text area
	Owner/Manager only — not on receipts or POS
	

SECTION H: Item Activity Log
* Last edited by: [Staff Name] — [Date/Time]
* Full price change history with user, old price, new price, reason
* Stock adjustment history linked to stock_movements
* 'View Item Activity' button → opens filtered audit log for this PLU


4.2a Mobile Quick-Add (Owner Phone)
✅ NEW: Owner can add a new product from their mobile phone when a new supplier product arrives urgently.
* Open mobile app → tap '+' (Quick Add) from main screen
* Simplified mobile form: PLU Number (auto-next-available or manual), Full Name, Category, Sell Price, Cost Price, Supplier, VAT Type, Active toggle
* Photo capture: optional — uploads directly to Supabase Storage
* Save → syncs immediately if online / queued if offline for next sync
* Full edit (all sections A–H above) completed later on desktop Admin App


4.3 Product Modifier Groups
Sidebar → 🥩 Inventory → Modifiers
Create Modifier Group:
Field
	Example
	Group Name
	Sauce Options
	Required?
	No (optional)
	Allow Multiple?
	No (pick one)
	Max Selections
	1
	

Add Modifier Items to Group:
Name
	Price Adjustment
	Track Inventory?
	Linked Item
	Pepper Sauce
	+R15.00
	Yes
	Pepper Sauce (inventory)
	Mushroom Sauce
	+R15.00
	Yes
	Mushroom Sauce (inventory)
	Monkey Gland
	+R15.00
	Yes
	Monkey Gland (inventory)
	No Sauce
	R0.00
	No
	—
	

4.4 Stock Levels & Movements
Sidebar → 🥩 Inventory → Stock Levels
Table view of all products across all storage locations:
Product
	On Hand
	Fresh
	Frozen
	Reorder
	Status
	T-Bone Steak
	12.5 kg
	8.2 kg
	4.3 kg
	5.0 kg
	✅ OK
	Rump Steak
	3.2 kg
	3.2 kg
	0.0 kg
	5.0 kg
	🟡 LOW
	Mince (Lean)
	45.0 kg
	45.0 kg
	0.0 kg
	10.0 kg
	✅ OK
	Boerewors (Trad)
	2.1 kg
	2.1 kg
	0.0 kg
	5.0 kg
	🟡 LOW
	Biltong
	8.3 kg
	8.3 kg
	0.0 kg
	3.0 kg
	✅ OK
	

Stock Movement Log (per product): Click any product → 'Movement History' tab:
Date
	Type
	Qty (kg)
	Balance
	Reference
	06 Feb 15:42
	Sale
	-1.25
	12.5
	TXN-20260206-0042
	06 Feb 14:20
	Sale
	-0.80
	13.75
	TXN-20260206-0038
	06 Feb 08:00
	Carcass Breakdown
	+15.2
	14.55
	BREAKDOWN-001
	05 Feb 16:00
	Markdown (Frozen)
	-2.0
	-0.65
	MARKDOWN-012
	

4.5 Stock Lifecycle Actions
🔄 CHANGED: Freezer markdown % is NOT fixed at 25% — owner sets per product individually. Sponsorship and Donation are separate actions from Waste, with full recipient tracking.


Action
	Where
	Effect
	Sale
	POS (auto)
	Reduces stock_on_hand
	Carcass Breakdown
	Admin → Production
	Increases stock_on_hand per cut
	Production Batch
	Admin → Production
	Consumes ingredients, creates finished product
	Move to Freezer
	Admin → Inventory
	Moves fresh to frozen; applies owner-set markdown % (set per product — NOT fixed 25%)
	Markdown (Still Fresh)
	Admin → Inventory
	Reduces sell price; creates new barcode label
	Waste / Disposal
	Admin → Inventory
	Reduces stock; logged with reason + weight + staff ID
	Staff Meal
	Admin → Inventory
	Reduces stock; logged with staff ID (prevents showing as theft)
	Donation
	Admin → Inventory
	🔄 Reduces stock; logged for tax purposes (Recipient, Type, Value, Date). Appears in P&L as Donation Expense — NOT as waste.
	Sponsorship / Marketing
	Admin → Inventory
	🆕 Reduces stock; logged with Recipient Name, Event, Date, Description, Estimated Value. Appears in P&L as Marketing Expense — separate from waste. Tracks goodwill/community support.
	Stock-Take Adjustment
	Admin → Inventory
	Corrects stock to actual count; logs variance
	Transfer Between Locations
	Admin → Inventory
	🆕 Moves stock between physical locations (e.g. Display Fridge 1 to Deep Freezer 3). Total on-hand unchanged.
	

Move to Freezer Flow
* 1. Select product + quantity
* 2. Click 'Move to Freezer' button
* 3. System prompts: enter markdown % for this product (owner-set, stored per product)
* 4. System creates new product variant 'T-Bone (Previously Frozen)'
*    New price = Original × (1 − markdown%). New PLU assigned. Fresh stock reduced. Frozen stock increased.
* 5. Owner can print new Ishida-format barcode labels


Waste Logging Flow
* 1. Select product + quantity
* 2. Click 'Log Waste' button
* 3. Reason: Expired / Spoiled / Dropped / Trimming / Customer Return
* 4. Staff ID: auto-filled (logged-in user)
* 5. Photo: optional camera snap of wasted product
* 6. Save → stock_movements created, stock_on_hand reduced
* 7. Shows in shrinkage reports (expected waste vs excessive waste)


Sponsorship / Donation Flow (NEW)
✅ NEW: Separate action from Waste — carries full recipient and event tracking for business records and tax purposes.
* 1. Select product + quantity (or gift voucher value / service description)
* 2. Click 'Sponsorship' or 'Donation' button
* 3. Enter: Recipient Name, Event/Reason, Date, Description, Estimated Value (R)
* 4. Type: Meat / Gift Voucher / Processing Service
* 5. Save → stock reduced + ledger entry created (Marketing Expense / Donation Expense)
* 6. Appears in P&L under 6500 Marketing or 6510 Donations (new sub-account)
* 7. Full sponsorship history viewable in Reports — separate from waste log


4.6 Supplier Management
Sidebar → 🥩 Inventory → Suppliers
Field
	Example
	Name
	Karan Beef
	Contact Person
	Johan van Wyk
	Phone
	012 345 6789
	Email
	orders@karanbeef.co.za
	Address
	Industrial Park, Pretoria
	Payment Terms
	COD / 7 days / 14 days / 30 days
	BBBEE Level
	Level 2
	Active
	Yes
	

Supplier Scorecard (Auto-Generated):
Metric
	This Month
	Deliveries
	8
	On Time
	7/8 (87.5%)
	Weight Variance
	Avg −0.8%
	Invoice Accuracy
	100%
	Quality Issues
	1 (bruising on beef side)
	

4.7 Stock-Take
Sidebar → 🥩 Inventory → Stock-Take
✅ NEW: Multi-device concurrent counting fully supported. Multiple staff can count different fridges simultaneously using separate devices. The same product can be logged from different locations at the same time.


* 1. Owner/Manager clicks 'Start Stock-Take' in Admin — creates stock-take session
* 2. All active devices (tablets, phones running Stock-Take App) see the open session
* 3. Each counter selects their physical location (Display Fridge 1, Walk-In Fridge, Deep Freezer 4, etc.)
* 4. Multiple counters can log the same PLU from different locations simultaneously
* 5. Live progress visible to Manager/Owner: '38 of 120 items counted (3 devices active)'
* 6. Enter actual quantities — system shows expected vs actual with variance:


Product
	System Qty
	Actual Count
	Variance
	Location
	T-Bone Steak
	12.5 kg
	[12.3]
	−0.2 kg
	Display Fridge 1
	Rump Steak
	3.2 kg
	[3.0]
	−0.2 kg
	Display Fridge 2
	Mince (Lean)
	45.0 kg
	[44.5]
	−0.5 kg
	Walk-In Fridge
	

* 7. Conflicts (same item, same location, different counters) flagged for resolution
* 8. Manager/Owner reviews consolidated totals before approving
* 9. On approval: stock adjusted to physical counts; all variances logged to stock_movements + audit_logs
* 10. Triggers shrinkage analysis after approval


5. PRODUCTION MANAGEMENT
5.1 Yield Templates
Sidebar → 🔪 Production → Yield Templates
Owner defines how each carcass type should break down.


🔄 CHANGED: Yield templates are initially set by the owner based on experience and expected averages. Over time, as carcasses are broken down and cuts are sold, the system calculates the TRUE running average from real data. Block tests (full mid-breakdown audit weighing) are optional, not mandatory — the system builds its own intelligence from daily operations.


* Phase 1: Owner creates template with estimated yield percentages per cut
* Phase 2: Each carcass breakdown logs actual weights per cut
* Phase 3: System calculates rolling actual average (last 10 breakdowns per carcass type)
* Phase 4: Owner views 'Suggested Template Update' — can accept or keep manual settings
* Phase 5: System flags when actual consistently differs from template by >5%


Create Template — Example: 'Beef Side — Standard'
Carcass Type: Beef Side | Expected Input Weight: 100kg (percentage basis)
Cut
	Yield %
	Price Multiplier
	Notes
	T-Bone
	10%
	1.6×
	Maps to PLU 1001
	Rump
	12%
	1.5×
	Maps to PLU 1002
	Sirloin
	8%
	1.55×
	Maps to PLU 1003
	Fillet
	3%
	2.5×
	Maps to PLU 1004
	Mince
	20%
	1.1×
	Maps to PLU 1010
	Stewing Beef
	15%
	1.0×
	Maps to PLU 1011
	Brisket
	8%
	1.2×
	Maps to PLU 1012
	Short Rib
	5%
	1.3×
	Maps to PLU 1013
	Bone
	12%
	0.2×
	Non-sellable
	Fat / Trimming
	5%
	0.1×
	Non-sellable
	Moisture Loss
	2%
	0.0×
	Expected drip/loss
	TOTAL
	100%
	—
	

	

Price Multiplier: If carcass cost = R75/kg, T-Bone sell price = R75 × 1.6 = R120/kg.
Multiple templates per carcass type (Standard, Premium, Steak-Heavy, Budget). Owner selects which template to use for each breakdown.


📌 NOTE: TWO separate lamb templates are required: 'Whole Lamb — Premium' and 'Whole Lamb — AB/B3 Grade'. These are different quality grades bought at different cost prices, sold at different price points, requiring separate yield templates.


5.2 Carcass Intake (Digital Meat Hook)
Sidebar → 🔪 Production → Carcass Intake → 'New Intake'
Step 1: Delivery Details
Field
	Input
	Supplier
	Dropdown (from suppliers)
	Invoice Number
	Text (manual or from OCR)
	Invoice Weight
	Number (kg from supplier invoice)
	Carcass Type
	Dropdown: Beef Side, Beef Quarter, Whole Lamb (Premium), Whole Lamb (AB Grade), Whole Lamb (B3 Grade), Pork Side, etc.
	Delivery Date
	Date picker (defaults today)
	

Step 2: Actual Weighing
Field
	Input
	Actual Weight
	Number (weighed on arrival)
	

Step 3: Variance Check (Auto-Calculated)
  Invoice Weight:   200.0 kg
  Actual Weight:    198.5 kg
  Variance:          -1.5 kg  (-0.75%)
  ✅ Within tolerance (2%)
  [ACCEPT & PROCEED]


  ⚠️  If variance > 2%:
  'Significant weight difference detected.'
  Expected: 200.0kg | Actual: 195.0kg | Variance: -5.0kg (-2.5%)
  [ACCEPT ANYWAY + LOG NOTE]  [REJECT DELIVERY]  [CALL SUPPLIER]


Step 4: Select Yield Template
* Dropdown of templates matching carcass type
* Shows expected breakdown weights based on actual intake weight
* 'Beef Side — Standard' / 'Whole Lamb — Premium' / 'Whole Lamb — AB Grade' etc.


Step 5: Save
* carcass_intakes record created | Status: 'Received' (not yet broken down)
* Linked to invoice (if OCR'd)
* Stock of whole carcass added to system


5.3 Carcass Breakdown
Sidebar → 🔪 Production → Pending Breakdowns (shows received, unbroken carcasses)
Select carcass → 'Start Breakdown'


🔄 CHANGED: Carcasses are NOT always broken down completely in one session. A Blockman cuts what is needed for the day and leaves the rest hanging. Partial breakdowns are fully supported — this is the normal workflow, not an edge case.


 ┌─────────────────────────────────────────────────────────────────┐
 │  CARCASS BREAKDOWN — Beef Side #INT-20260206-001                │
 │  Supplier: Karan Beef | Invoice: KRN-2026-0412 | Weight: 198.5kg│
 │  Template: Beef Side — Standard | Blockman: Pieter              │
 │  Mode: [ Full Breakdown ] or [ Partial Breakdown ]              │
 ├──────────────────┬────────────────┬────────────────┬────────────┤
 │  Cut             │  Expected (kg) │  Actual (kg)   │  Variance  │
 ├──────────────────┼────────────────┼────────────────┼────────────┤
 │  T-Bone          │  19.85 kg      │  [ 20.1 ]      │  +0.25     │
 │  Rump            │  23.82 kg      │  [ 23.5 ]      │  −0.32     │
 │  Sirloin         │  15.88 kg      │  [ 16.0 ]      │  +0.12     │
 │  Fillet          │   5.96 kg      │  [  5.8 ]      │  −0.16     │
 │  Mince           │  39.70 kg      │  [ 40.2 ]      │  +0.50     │
 │  Stewing Beef    │  29.78 kg      │  [ 29.0 ]      │  −0.78     │
 │  Brisket         │  15.88 kg      │  [ 16.1 ]      │  +0.22     │
 │  Short Rib       │   9.93 kg      │  [ 10.0 ]      │  +0.07     │
 │  Bone            │  23.82 kg      │  [ 24.0 ]      │  +0.18     │
 │  Fat/Trimming    │   9.93 kg      │  [ 10.2 ]      │  +0.27     │
 │  Moisture Loss   │   3.97 kg      │  [  3.6 ]      │  −0.37     │
 ├──────────────────┼────────────────┼────────────────┼────────────┤
 │  TOTAL           │  198.50 kg     │  198.5 kg      │  Balanced  │
 ├──────────────────┴────────────────┴────────────────┴────────────┤
 │  Remaining on Hook: [  ] kg     Accounted: [  ] kg              │
 │  [ADD EXTRA CUT]  [MIDDLE WEIGH CHECK]  [COMPLETE BREAKDOWN]    │
 └─────────────────────────────────────────────────────────────────┘


Partial Breakdown (New Core Feature)
* Blockman selects 'Partial Breakdown' — enters only cuts processed today
* Carcass status remains 'In Progress' — remaining weight tracked on system
* System shows running balance: 'Remaining on Hook: 42.3 kg'
* Multiple partial sessions allowed until carcass fully broken down
* Full Breakdown: system validates sum of actuals vs intake weight


Middle Weigh Check
  Cuts completed so far:  102.3 kg
  Remaining on hook:       94.8 kg
  Total accounted:        197.1 kg
  Original weight:        198.5 kg
  Unaccounted:              1.4 kg  (moisture loss + trimming)


Complete Breakdown
* 1. All cuts entered with actual weights
* 2. System validates: sum of actuals within tolerance of intake weight
* 3. If balanced: 'Breakdown complete ✅'
* 4. If gap > 2%: '⚠️ Unaccounted weight: 4.2kg — investigate or log as waste'
* 5. stock_movements records created for each cut
* 6. inventory_items.stock_on_hand updated for each cut
* 7. Blockman performance rating updated (actual vs template)


5.4 Blockman Performance Rating
Auto-calculated after each breakdown:
  Blockman: Pieter
  Breakdown: Beef Side #INT-20260206-001
  Overall Yield: 96.8% (expected 98%)
  Rating: ⭐⭐⭐⭐ (4 stars)


  Cut-by-Cut Performance:
  T-Bone:  +0.25 kg above template  ✅
  Rump:    −0.32 kg below template  ⚠️
  Fillet:  −0.16 kg below template  (within tolerance)
  Mince:   +0.50 kg above template  ✅ (good trimming recovery)


  Monthly Average: ⭐⭐⭐⭐⭐ (94.2% yield)


Stars
	Yield %
	Interpretation
	⭐⭐⭐⭐⭐
	95–100%
	Expert — minimal waste
	⭐⭐⭐⭐
	90–95%
	Good — competent
	⭐⭐⭐
	85–90%
	Average — needs improvement
	⭐⭐
	80–85%
	Below average — training needed
	⭐
	< 80%
	Poor — possible theft or skill issue
	

5.5 Recipes & Production Batches
Sidebar → 🔪 Production → Recipes
Create Recipe — Example: Traditional Boerewors
Output Product: Boerewors (Traditional) | Expected Yield: 95% (5% loss during processing)


Ingredient
	Per 10kg Batch
	Unit
	Beef Mince
	5.0 kg
	kg
	Pork Mince
	3.5 kg
	kg
	Beef Fat
	1.5 kg
	kg
	Boerewors Spice
	0.25 kg
	kg
	Coriander
	0.10 kg
	kg
	Vinegar
	0.05 L
	L
	Casings
	1 pack
	pack
	

Production Batch Workflow
* 1. Select recipe → 'Start Batch'
* 2. Enter actual ingredient quantities used
* 3. Enter actual output weight
* 4. System calculates yield % and cost
* 5. production_batches + production_batch_ingredients records created
* 6. Ingredient stock REDUCED
* 7. Output product stock INCREASED
* 8. Cost per kg calculated: (Sum of ingredient costs) ÷ output weight


  BATCH COMPLETE: Traditional Boerewors — Batch #PB-20260206-001
  ─────────────────────────────────────────────────────────────────
  Ingredients Used:
    Beef Mince:       25.0 kg @ R85/kg  = R2,125.00
    Pork Mince:       17.5 kg @ R70/kg  = R1,225.00
    Beef Fat:          7.5 kg @ R25/kg  =   R187.50
    Boerewors Spice:   1.25 kg @ R90/kg =   R112.50
    Corander:         0.50 kg @ R65/kg =    R32.50
    Vinegar:           0.25 L  @ R18/L  =     R4.50
    Casings:           5 packs @ R35    =   R175.00
  ─────────────────────────────────────────────────────────────────
  Total Input Cost:   R3,862.00
  Total Input Weight:    52.0 kg
  Output:                49.4 kg Boerewors  (Yield: 95%)
  Cost per kg:           R78.18
  ⚠️  Sell price R68/kg — BELOW COST — review sell price!
  Recommended sell price: R113/kg (for 30% target margin)


5.6 Dryer / Biltong & Droewors Production (NEW MODULE)
✅ NEW: The dryer is used for multiple products: biltong, droewors, chilli bites, and other dried products. This module covers ALL dryer-based production — same workflow, different recipes.


Product Type
	Key PLUs
	Raw Input
	Approx Drying Yield %
	Beef Biltong (various cuts)
	P005304/308/310/312/314/315
	Beef topside / silverside / rump
	~55–60%
	Chilli Biltong / BBQ Biltong
	P005301/311
	Beef + chilli/BBQ spice
	~55%
	Wagyu Biltong
	P005303
	Wagyu beef
	~58%
	Springbok Biltong
	P005307
	Springbok (bought-in game stock)
	~55%
	Ostrich / Volstruis Biltong
	P005313
	Ostrich (bought-in)
	~58%
	Sandwich Biltong
	P005304
	Beef (wet-cured style)
	~60%
	Bees Droewors
	P005131 / P005151
	Beef mince + spice + casings
	~60%
	Springbok Droewors
	P001083 / P005117
	Springbok (bought-in game stock)
	~58%
	Ostrich / Volstruis Droewors
	P005133
	Ostrich (bought-in)
	~58%
	Wild Droewors
	P005118
	Mixed game (bought-in)
	~58%
	Chilli Bites
	P005301
	Beef + chilli
	~55%
	Droewors Wiele (sliced)
	P005132
	Sliced droewors (after drying)
	Sold after drying
	

Dryer Batch Workflow
* Owner/Manager: Production → Dryer Batches → 'New Batch'
* Select Product Type: Biltong / Droewors / Chilli Bites / Other
* Select recipe (pre-set by owner with spice ratios, curing method, expected drying time)
* Enter raw material: product + weight going into dryer
* Enter spices, vinegar, casings used (auto-suggested from recipe)
* 'Load Dryer' → batch status: Drying — records which day it went in
* Drying period tracked: alert when minimum drying time reached ('Batch ready to weigh out')
* Blockman weighs out: enters actual output weight
* System calculates yield % actual vs expected — logs to Blockman performance
* Finished product stock added to inventory
* Raw material stock deducted at batch start (or confirmed at completion)


📌 NOTE: Droewors uses the same dryer batch module as biltong. The difference is the recipe (mince + casings + spice mix vs whole muscle + salt + vinegar) and shorter drying time. Both track: input weight, spice/casing usage, drying days, output weight, yield efficiency, and cost per kg produced.


6. HUNTER JOB MANAGEMENT (FULL CUSTOM SYSTEM)
6.1 Service Configuration
Sidebar → 🦌 Hunter → Services
Owner/Manager creates and manages processing services. Nothing hardcoded — each butchery defines what they offer.


📌 NOTE: Hunter Job services (Cut & Pack, Vacuum Pack, Make Droewors, etc.) remain as POS line items for walk-in cutting service customers. Full Hunter Jobs (game carcass processing) go through this module. Both paths are supported.


Field
	Example 1
	Example 2
	Service Name
	Cut & Pack (Basic)
	Make Droewors
	Rate Type
	per_kg
	per_kg
	Rate
	R25.00
	R35.00
	Expected Yield
	85%
	40%
	Min Weight
	10 kg
	5 kg
	Active
	Yes
	Yes
	

Default Materials per Service: Each service can have default materials that auto-populate when Blockman starts:
Service
	Material
	Qty per kg Input
	Make Droewors
	Droewors Spice
	0.05 kg
	Make Droewors
	Casings
	0.01 pack
	Make Biltong
	Biltong Salt
	0.03 kg
	Make Biltong
	Vinegar
	0.02 L
	Make Boerewors
	Boerewors Spice
	0.08 kg
	Make Boerewors
	Casings
	0.015 pack
	

6.2 Job Workflow
Step 1: Intake — Create Job
Customer arrives with carcass. Staff → Hunter → 'New Job'
  Customer Name:     [ Jan van der Merwe        ]
  Phone:             [ 082 555 1234              ]
  Email:             [ optional                  ]
  Animal Type:       [ Springbok ▼               ]
  Estimated Weight:  [ 45 ] kg
  Notes:             [ Customer wants all droewors, no mince ]


  Select Services:
  ☑  Cut & Pack (Basic)      R25/kg — for meat portions
  ☑  Make Droewors           R35/kg — customer wants all extras as droewors
  ☐  Make Biltong            R40/kg
  ☐  Make Boerewors          R30/kg
  ☑  Vacuum Seal             R15/pack — for all final packs


  Estimated Total: (45kg × R25) + (est. 15kg × R35) + (20 packs × R15) = R2,150
  Deposit Required: R500 (configurable)
  [CREATE JOB]


Job created → Status: 'Intake'
Customer gets WhatsApp: "Job #HNT-20260206-001 created. Estimated total: R2,150. We'll notify you when ready."


Step 2: Processing (Sequential)
Each selected service runs in order. Blockman processes step by step:


Process 1: Cut & Pack
  Job: HNT-20260206-001 | Customer: Jan van der Merwe
  Service: Cut & Pack (Basic) @ R25/kg
  Input Weight: [ 43.5 ] kg (actual weighed)
  Output Products:
    Steaks (loin):    [  8.2 ] kg
    Leg portions:     [ 12.5 ] kg
    Shoulder:         [  6.8 ] kg
    Rib:              [  4.2 ] kg
    Trim (droewors):  [  9.5 ] kg
    Bone & waste:     [  2.3 ] kg
    Total:            43.5 kg ✅
  Materials Used: None for basic cut & pack
  Cost: 43.5 kg × R25/kg = R1,087.50
  [COMPLETE PROCESS 1]


Process 2: Make Droewors
  Job: HNT-20260206-001
  Service: Make Droewors @ R35/kg
  Input Weight: [ 9.5 ] kg (trim from Process 1)
  Materials Used:
    Droewors Spice: [ 0.48 ] kg  (auto-suggested: 9.5 × 0.05 = 0.475)
    Casings:        [ 0.10 ] pack (auto-suggested: 9.5 × 0.01 = 0.095)
  Output Weight: [ 3.8 ] kg  (yield: 40%)
  Cost: (9.5 × R35) + (0.48 × R90) + (0.10 × R35) = R379.70
  [COMPLETE PROCESS 2]


Process 3: Vacuum Seal
  Job: HNT-20260206-001
  Service: Vacuum Seal @ R15/pack
  Number of Packs: [ 18 ]
  Cost: 18 × R15 = R270.00
  Materials Used: Vacuum Bags: [ 18 ] bags
  [COMPLETE PROCESS 3]


Step 3: Job Summary & Invoice
  JOB COMPLETE: HNT-20260206-001
  Customer: Jan van der Merwe | Springbok 43.5 kg
  ─────────────────────────────────────────────────
  Services:
    Cut & Pack:       43.5 kg × R25    = R1,087.50
    Make Droewors:     9.5 kg × R35    =   R332.50
    Vacuum Seal:       18 packs × R15  =   R270.00
  Materials:
    Droewors Spice:   0.48 kg × R90   =    R43.20
    Casings:          0.10 pk × R35   =     R3.50
    Vacuum Bags:       18 × R2        =    R36.00
  ─────────────────────────────────────────────────
  SUBTOTAL:                              R1,772.70
  VAT (15%):                               R265.91
  TOTAL:                                 R2,038.61
  Deposit Paid:                           −R500.00
  BALANCE DUE:                           R1,538.61
  ─────────────────────────────────────────────────
  [PRINT INVOICE]  [SEND WHATSAPP]  [MARK READY FOR COLLECTION]


Step 4: Collection
* Status changes to 'Ready for Collection'
* WhatsApp: 'Your order is ready! Job #HNT-20260206-001. Balance: R1,538.61'
* Customer arrives — staff selects job — confirms collection
* Payment processed (Cash / Card / Account)
* Job status: 'Completed'


6.3 Hunter Job Database Tables
Table
	Purpose
	hunter_services
	Service definitions (rates, yields, materials)
	hunter_jobs
	Job header (customer, animal, status, dates)
	hunter_job_processes
	Each service step within a job
	hunter_process_materials
	Materials used per process step
	hunter_process_outputs
	Output products from each process
	

7. HR & STAFF MANAGEMENT
⚠️ IMPORTANT: Clock-in/out is in the separate Clock-In App (App 3). This section covers the management side: viewing hours, managing leave, running payroll, compliance, AWOL records.


7.1 Staff Profiles
Sidebar → 👥 HR → Staff
Field
	Example
	Notes
	Full Name
	Sarah Mokoena
	

	Role
	Cashier
	Cashier / Blockman / Manager / Owner
	PIN
	**** (hashed)
	4-digit PIN for POS and Clock-In App login
	Phone
	082 555 0001
	

	Email
	sarah@email.com
	For payslip delivery
	ID Number
	9501015012081
	Stored securely
	Start Date
	15 Jan 2024
	

	Employment Type
	Hourly / Weekly / Monthly Salary
	🆕 Per-staff payroll frequency
	Hourly Rate / Monthly Salary
	R45.00 / hour
	Depending on employment type
	Payroll Frequency
	Weekly / Monthly
	🔄 Set per staff member individually — can be changed by owner
	Max Discount %
	5%
	Maximum discount this staff member can apply at POS without override
	Bank Details
	(encrypted)
	For salary EFT payments
	Active
	Yes
	Inactive = cannot log in
	

Employee Documents Tab: Upload and store: ID copy, contract, tax forms, training certificates, disciplinary records.


7.2 Timecard Viewer (From Clock-In App Data)
Sidebar → 👥 HR → Timecards
🔄 CHANGED: Timecard viewer now shows full granular break detail — each break individually with exact in/out times, not just a summed total. Up to 3 breaks per shift tracked.


Date
	Staff
	Clock In
	Brk 1 Out
	Brk 1 In
	Brk 2 Out
	Brk 2 In
	Brk 3 Out
	Brk 3 In
	Clock Out
	Total Brk
	Reg Hrs
	OT Hrs
	06 Feb
	Sarah
	07:28
	10:15
	10:30
	13:00
	13:30
	15:45
	15:55
	17:32
	1h 27m
	8.57
	0.57
	06 Feb
	Mike
	07:30
	10:00
	10:20
	13:00
	13:45
	—
	—
	17:45
	1h 05m
	9.17
	0.67
	06 Feb
	Pieter
	08:15
	10:30
	10:45
	13:00
	13:30
	—
	—
	16:00
	1h 00m
	7.25
	0.00
	

Timecard view options:
* Daily View: Full break-by-break detail for all staff for a selected date
* Weekly View: Summary per day per staff member — daily totals per row
* Monthly View: Daily rows per staff member — monthly totals at bottom
* Full History: Date-range selector — all staff or specific staff — exportable PDF/CSV
* Per-Staff Drill-Down: Click any staff member — see full shift history


Calculated values per shift:
* Total break time (sum of all individual breaks)
* Total time clocked (Clock Out − Clock In)
* Net working time (Total time − Total break)
* Regular hours vs overtime hours
* Any BCEA violations flagged in red inline


Edit Timecards: Owner/Manager can correct entries (forgot to clock out, wrong time). All changes logged in audit trail.


7.3 Leave Management
Leave Balances (Auto-Calculated):
Staff
	Annual Leave
	Sick Leave
	Family Leave
	Sarah
	12.5 days
	24 days
	3 days
	Mike
	15.0 days
	30 days
	3 days
	Pieter
	8.3 days
	18 days
	3 days
	

Leave Requests: Staff submit via Clock-In App — appear in Admin for approval:
  PENDING LEAVE REQUESTS
  ────────────────────────────────────────────────
  Sarah Mokoena — Annual Leave
  10 Mar – 14 Mar 2026  (5 days)
  Balance after approval: 7.5 days
  [APPROVE]  [DECLINE]  [DISCUSS]


BCEA Compliance requirements tracked:
* Minimum 21 days annual leave per year (full-time) — system tracks accrual (1.75 days/month)
* 30 days sick leave per 36-month cycle
* 3 days family responsibility leave per year
* System alerts when balances run low or accrual falls behind legal minimum


7.3a AWOL / Absconding Records (NEW)
✅ NEW: Staff absconding (going AWOL without notice) is formally tracked in the system — separate from normal absent records, linked to BCEA compliance and disciplinary files.


Field
	Notes
	Date(s)
	When AWOL occurred
	Staff Member
	Linked to staff profile
	Expected Start Time
	When they should have clocked in
	Notified Owner/Manager
	Yes/No + who attempted contact
	Resolution
	Returned / Resigned / Dismissed / Warning Issued / Pending
	Written Warning Issued
	Yes/No + upload PDF of warning if applicable
	Notes
	Full record of circumstances
	Linked to Disciplinary Record
	Auto-links to staff disciplinary file in Documents Tab
	

📌 NOTE: Pattern detection: 3 or more AWOL incidents for the same staff member triggers a flag: 'Persistent AWOL — consider formal disciplinary process.'


7.4 Payroll
Sidebar → 👥 HR → Payroll (Owner only)
🔄 CHANGED: Each staff member can have their own payroll frequency (weekly or monthly). Only the correct group appears in each payroll run. All staff appear on the monthly summary slip showing all weekly payments made during the month.


Create Payroll Period
* 1. Select period and type: 'Weekly — Week ending 28 Feb 2026' or 'Monthly — February 2026'
* 2. Weekly run: only weekly-frequency staff appear
* 3. Monthly run: all staff appear — weekly staff show each weekly payment as separate line items
* 4. System auto-generates entries for all applicable staff:


Staff
	Freq
	Reg Hrs
	OT Hrs
	Gross
	Deductions
	Net Pay
	Sarah
	Weekly
	44.0
	2.5
	R2,137
	R214
	R1,923
	Mike
	Monthly
	176.0
	8.0
	R10,560
	R1,690
	R8,870
	Pieter
	Weekly
	42.0
	0.0
	R1,890
	R189
	R1,701
	

Calculations:
* Regular: Hours × Hourly Rate
* Overtime (weekday): Hours × Hourly Rate × 1.5
* Sunday: Hours × Hourly Rate × 2.0
* Public Holiday: Hours × Hourly Rate × 2.0
* UIF: 1% of gross (employee portion)
* PAYE: Tax bracket calculation (SARS tables)
* Staff Loans / Meat Purchases: auto-deducted (see 7.5)


Payslip Generation: PDF per employee — can email, WhatsApp, or print.
Monthly payslip for ALL payroll types: shows each weekly payment with date + deductions as separate line items — full visibility for all staff.


📌 NOTE: Payroll frequency can be changed per staff member by owner (e.g. from weekly casual to monthly salaried on promotion). Change is effective from next payroll period and logged in audit trail.


7.5 Staff Loans, Advances & Meat Purchases on Credit
🔄 CHANGED: All staff loans, salary advances, and meat/product purchases on credit are tracked in one Staff Credit ledger per employee. All deductions are automatic from the next payroll run.


Field
	Example
	Notes
	Staff Member
	Pieter
	Linked to staff profile
	Type
	Meat Purchase / Salary Advance / Loan
	

	Purchase Date / Loan Date
	15 Feb 2026
	When the purchase/advance was made
	Items Purchased
	500g Rump + 1kg Mince
	For meat purchases — product detail
	Amount
	R2,000
	Total value
	Repayment Plan
	R500/month × 4 months
	For loans — schedule set by owner
	Deduct From
	Next payroll / specific period
	Owner can defer or adjust individual deductions
	Status
	Pending / Deducted / Partial / Cleared
	

	

* All outstanding deductions auto-applied on payroll run — owner can defer or adjust individually
* Payslip shows each purchase/advance with date and amount as separate deduction lines
* Running outstanding balance shown on staff profile at all times
* Running loan balance shown on payslip — staff can see exactly what they owe
* Owner can view full credit history per staff member across all time


7.6 BCEA Compliance Dashboard
Sidebar → 👥 HR → Compliance
System auto-checks all BCEA rules and flags violations:
  COMPLIANCE STATUS — February 2026
  ──────────────────────────────────────────────────────────
  ✅  All staff within weekly working hour limits (max 45h)
  ✅  All breaks comply with BCEA (30+ min for 5+ hour shifts)
  ⚠️  Pieter: Only 8.3 days annual leave remaining (min 21 required per year)
  🔵  Sunday work: Sarah worked 2 Sundays this month — confirm double pay applied
  🔴  Mike: 3 AWOL incidents this month — Persistent AWOL flag


🔄 CHANGED: AWOL incidents now tracked and flagged in the BCEA Compliance dashboard. Persistent AWOL pattern detection (3+ incidents) alerts owner automatically.


8. BUSINESS ACCOUNTS (CREDIT TERMS)
8.1 Account Setup
Sidebar → 💳 Accounts → Business Accounts
🔄 CHANGED: Account profile now includes VAT number, WhatsApp/cell number, and email separately. Auto-suspend default changed — see 8.5.


Field
	Example
	Notes
	Business Name
	Giovanni's Restaurant
	

	Contact Person
	Giovanni Rossi
	Primary contact name
	Cell Phone / WhatsApp
	082 345 6789
	🆕 Primary — for WhatsApp statements and overdue notices
	Email
	giovanni@restaurant.co.za
	🆕 Separate field — for emailed statements
	VAT Number
	4712345678
	🆕 For VAT-compliant invoice generation
	Credit Terms
	7 days
	Days from invoice date to due date
	Credit Limit
	R10,000
	Owner sets per account
	Auto-Suspend
	No (default)
	🔄 Owner enables per account only — NOT a system default
	Auto-Suspend Trigger
	Set per account
	🔄 7 / 14 / 30 days overdue — owner chooses per client
	Active
	Yes
	

	

📌 NOTE: NO general customer credit. Only select businesses (restaurants, caterers) at owner's discretion.


8.2 Account Dashboard
Business
	Balance
	Limit
	Available
	Status
	Giovanni's Rest.
	R2,450
	R10,000
	R7,550
	⚠️ 3d overdue
	Café Nouveau
	R850
	R5,000
	R4,150
	✅ OK
	Event Catering Co
	R0
	R15,000
	R15,000
	✅ OK
	

8.3 Payment Recording
* 1. Select business + 'Record Payment'
* 2. Enter amount, date, payment method (EFT, Cash, Card)
* 3. Optional: attach proof of payment photo/scan
* 4. Balance reduced | Ledger entry auto-created


8.4 Statement Generation
Monthly statements (PDF) — printable, emailable, WhatsApp-shareable:
  STATEMENT: Giovanni's Restaurant
  VAT Number: 4712345678
  Period: 1 Feb – 28 Feb 2026
  ────────────────────────────────────────
  Opening Balance:          R 1,200.00
  + Purchases:              R 3,850.00
  – Payments:              −R 2,600.00
  = Closing Balance:        R 2,450.00
  Terms: 7 days  |  Status: OVERDUE (3 days)
  ────────────────────────────────────────
  TRANSACTIONS:
  03 Feb  TXN-20260203-0012         R   420.00
  05 Feb  Payment (EFT)            −R 1,000.00
  08 Feb  TXN-20260208-0028         R   850.00


8.5 Overdue Management
🔄 CHANGED: Auto-suspend is NOT the default. The system alerts on overdue but NEVER auto-suspends unless the owner has specifically enabled it for that individual account. Some clients can run overdue indefinitely — that is the owner's business relationship decision.


Overdue Period
	System Action
	Configurable?
	1 day overdue
	🟡 Yellow alert on dashboard only
	No — always on
	7 days overdue
	🔴 Red alert on dashboard + optional email/WhatsApp to Owner
	Notification is optional
	Auto-suspend
	❌ DOES NOT activate by default
	🔄 Owner enables per account individually. Off by default for all accounts.
	Manual suspend
	Owner clicks 'Suspend Account' in Admin panel
	Always available to owner at any time
	Re-enable
	Owner clicks 'Re-enable Account' in Admin panel
	Always available — immediate effect at POS
	

📌 NOTE: Auto-suspend can be set per individual account with a custom trigger (7 days / 14 days / 30 days). Some long-standing clients may never be suspended — the owner controls this completely per client relationship.


9. BOOKKEEPING & FINANCIAL
9.1 Invoice Management (OCR + Manual + Bulk Import)
Sidebar → 📒 Bookkeeping → Invoices
OCR Flow (Google Drive + Cloud Vision)
* 1. Owner photos supplier invoice OR drops PDF into designated Google Drive folder
* 2. Supabase Edge Function monitors folder (webhook or cron)
* 3. Cloud Vision OCR extracts text
* 4. AI parses: supplier name, invoice #, date, line items, totals
* 5. Invoice appears in Admin with status 'Pending Review'
* 6. Owner reviews, corrects any OCR errors, approves
* 7. Creates invoice + invoice_line_items records
* 8. Detects if supplier has changed prices since last invoice
* 9. Auto-creates Accounts Payable ledger entry


Manual Invoice Entry
* 'Add Invoice Manually' — for when OCR fails or invoice is verbal
* Enter supplier, date, line items, amounts
* Same approval flow as OCR


Bulk CSV Import / Export (NEW)
✅ NEW: Bulk CSV import and export for invoices — essential for accountant handover and month-end processing.
* Import: Upload CSV of multiple invoices — system maps columns and creates entries in bulk
* Export: Export all invoices or filtered selection to CSV for accountant
* Template download: Owner can download the correct CSV template for import
* Duplicate detection: System warns if invoice number already exists before importing
* Export formats: CSV, Excel (.xlsx), PDF


9.2 Chart of Accounts (Editable Ledger)
🔄 CHANGED: The chart of accounts is fully editable by the owner. New accounts can be added, existing ones renamed. Accounts cannot be deleted if they have transactions — they can only be deactivated.


Pre-configured for butchery — owner customises from here:
Account #
	Name
	Type
	Notes
	1000
	Cash on Hand
	Asset
	

	1100
	Bank Account
	Asset
	

	1200
	Accounts Receivable (Business Accounts)
	Asset
	

	1300
	Inventory (Meat)
	Asset
	

	1310
	Inventory (Spices & Supplies)
	Asset
	

	1400
	Equipment (at Transfer Value)
	Asset
	🆕 PTY Ltd conversion
	1410
	Accumulated Depreciation — Equipment
	Asset (contra)
	🆕 PTY Ltd conversion
	2000
	Accounts Payable (Suppliers)
	Liability
	

	2100
	VAT Payable
	Liability
	

	2200
	PAYE Payable
	Liability
	

	2300
	UIF Payable
	Liability
	

	2400
	Purchase Sale Agreement Loan
	Liability
	🆕 PTY Ltd conversion — monthly payments
	4000
	Meat Sales
	Revenue
	

	4100
	Hunter Processing Fees
	Revenue
	

	4200
	Other Income
	Revenue
	

	5000
	Meat Purchases
	COGS
	

	5100
	Spices & Casings
	COGS
	

	5200
	Packaging Materials
	COGS
	

	5300
	Shrinkage / Waste
	COGS
	

	6000
	Salaries & Wages
	Operating Expense
	

	6100
	Rent
	Operating Expense
	

	6200
	Electricity
	Operating Expense
	

	6300
	Equipment Maintenance
	Operating Expense
	

	6400
	Insurance
	Operating Expense
	

	6500
	Marketing & Sponsorship
	Operating Expense
	🆕 Sponsorship action posts here
	6510
	Donations
	Operating Expense
	🆕 Donation action posts here
	6600
	Transport & Fuel
	Operating Expense
	

	6700
	Purchase Sale Repayments
	Liability Repayment
	🆕 PTY Ltd conversion
	6900
	Sundry Expenses
	Operating Expense
	

	

9.3 Auto-Generated Ledger Entries
Event
	Amount
	Debit
	Credit
	Cash sale
	R295.90
	1000 Cash (+R295.90)
	4000 Revenue (+R257.30), 2100 VAT (+R38.60)
	Card sale
	R500.00
	1100 Bank (+R500.00)
	4000 Revenue (+R434.78), 2100 VAT (+R65.22)
	Account sale
	R850.00
	1200 AR (+R850.00)
	4000 Revenue (+R739.13), 2100 VAT (+R110.87)
	Supplier invoice
	R5,000
	5000 COGS (+R5,000)
	2000 AP (+R5,000)
	Account payment received
	R1,000
	1100 Bank (+R1,000)
	1200 AR (−R1,000)
	Payroll
	R28,450
	6000 Salaries (+R28,450)
	1100 Bank (−R28,450)
	Sponsorship — meat
	R350
	6500 Marketing (+R350)
	1300 Inventory (−R350 at cost)
	Donation — gift voucher
	R500
	6510 Donations (+R500)
	Revenue reduction
	Purchase Sale repayment
	R5,000
	2400 Loan Payable (−R5,000)
	1100 Bank (−R5,000)
	

9.4 P&L Statement (Auto-Generated)
Sidebar → 📒 Bookkeeping → P&L | Select period — auto-generates from ledger:
  PROFIT & LOSS STATEMENT
  Botha's Butchery (Pty) Ltd
  Period: February 2026
  ─────────────────────────────────────────────
  REVENUE:
    Meat Sales (POS)              R 145,230
    Hunter Processing Fees         R   8,500
    Total Revenue                 R 153,730


  COST OF GOODS SOLD:
    Meat Purchases                R  85,340
    Spices & Casings              R   3,210
    Packaging Materials           R   1,850
    Shrinkage / Waste             R   4,520
    Total COGS                    R  94,920


  GROSS PROFIT                    R  58,810  (38.2%)


  OPERATING EXPENSES:
    Salaries & Wages              R  28,450
    Rent                          R   6,500
    Electricity                   R   2,340
    Equipment Maintenance         R     850
    Insurance                     R   1,200
    Marketing & Sponsorship       R     500
    Donations                     R     200
    Transport                     R   1,800
    Purchase Sale Repayment       R   5,000
    Sundry                        R     420
    Total Operating Expenses      R  47,260


  NET PROFIT                      R  11,550  (7.5%)


9.5 VAT Report (for SARS)
Auto-generates VAT201 data:
  VAT REPORT — February 2026
  Output VAT (Sales):      R 20,052
  Input VAT (Purchases):   R 12,450
  VAT Payable to SARS:     R  7,602


9.6 Cash Flow View
  CASH FLOW — February 2026
  Opening Balance:              R  45,200
  + Cash Sales:                 R  98,340
  + Card Sales (banked):        R  42,230
  + Account Payments Received:  R   8,500
  – Supplier Payments:         −R  85,340
  – Salaries:                  −R  28,450
  – Rent:                      −R   6,500
  – Utilities:                 −R   2,340
  – Purchase Sale Repayment:   −R   5,000
  – Other:                     −R   3,570
  = Closing Balance:            R  63,070


9.7 Business Conversion — PTY Ltd Module (NEW)
✅ NEW: Dedicated module to log and track the transition from sole proprietor to Botha's Butchery (Pty) Ltd. Effective date: 1 March 2026.


Opening Balance Sheet — As at 1 March 2026
Category
	Item
	How Captured
	ASSETS — Stock
	All inventory at cost value
	System generates point-in-time stock valuation report (qty × avg cost). Locked on 1 Mar 2026 — becomes opening asset entry. Immutable after owner sign-off.
	ASSETS — Equipment
	Each equipment item listed individually
	Owner enters: Name, Serial No, Original Purchase Date, Original Cost, Agreed Transfer Value, Useful Life. System calculates annual depreciation.
	LIABILITIES — Supplier Debt
	Outstanding balance per supplier
	Pulled from bookkeeping supplier balances at transfer date
	LIABILITIES — Purchase Sale Agreement
	Total agreed purchase price
	Owner enters: seller name, total amount, terms. Creates loan/liability account #2400.
	

Equipment Register
Field
	Notes
	Equipment Name
	e.g. Mincer, Band Saw, Walk-In Fridge, Display Fridge 1, Display Fridge 2, Display Fridge 3, Deep Freezer 1–7, Biltong Dryer
	Serial Number
	Physical ID — from equipment plate
	Original Purchase Date
	When originally bought
	Original Purchase Cost
	What was paid originally
	Agreed Transfer Value (1 March 2026)
	Price agreed in the purchase sale agreement for this item
	Depreciation Method
	Straight-line (default for SA SME)
	Useful Life (years)
	Owner sets — e.g. 10 years for fridges, 15 years for freezers
	Annual Depreciation
	Auto-calculated: Transfer Value ÷ Remaining Useful Life
	Current Book Value
	Auto-calculated and updated monthly
	Notes
	Condition at transfer date, any warranties remaining
	

Purchase Sale Agreement Tracker
Field
	Example
	Seller Name
	Johan Botha (Sole Proprietor)
	Total Purchase Price
	R[Amount agreed]
	Effective Date
	1 March 2026
	Monthly Instalment Amount
	R[Monthly amount]
	Payment Day
	e.g. 25th of each month
	Outstanding Balance
	Auto-calculated — reduces with each payment
	Payment History
	Full log: date, amount, method (EFT/Cash), balance after payment
	

* Each monthly payment creates ledger entry: Debit 2400 Loan Payable / Credit 1100 Bank
* Shows in P&L under 6700 Purchase Sale Repayments
* Dashboard widget shows: 'Purchase Agreement — R[X] paid, R[Y] remaining'
* Opening balance entries are locked/immutable in audit log once owner signs off


10. SMART ANALYTICS & COMPLIANCE
10.1 Shrinkage Detection
Sidebar → 📈 Analytics → Shrinkage
Mass-balance calculation runs nightly:
  For each product:
  Theoretical Stock = Opening + Purchases + Production − Sales − Logged Waste − Moisture Loss
  Actual Stock      = Last stock-take count (or system running total)
  Gap               = Theoretical − Actual
  If Gap > threshold → Alert created


  SHRINKAGE ALERTS — This Week
  ────────────────────────────────────────────────────────────────
  🔴  T-Bone Steak — Gap: 2.4 kg (27%)
      Theoretical: 8.9 kg | On-hand: 6.5 kg
      Possible: Theft, unlogged waste, label error
      Staff involved: Mike (breakdown), Sarah (12 sales)
      [INVESTIGATE]  [CONDUCT STOCK-TAKE]  [ACCEPT & NOTE]


  🟡  Boerewors — Gap: 0.8 kg (6%)
      Possible: Moisture loss, tasting, scale variance
      [ACCEPT & NOTE]


  ✅  Mince — Gap: 0.3 kg (0.5%)
      Normal variance — auto-accepted


10.2 Dynamic Pricing Recommendations
Trigger 1: Supplier price change detected (via OCR or manual entry):
  PRICE ALERT: Beef Forequarter
  Supplier increased: R62/kg → R68/kg (+9.7%)
  Current sell prices affected:
    Mince:  R85/kg — Margin now 20% (was 27%)
    Stew:   R75/kg — Margin now 10% (was 17%)
  Recommended new prices (30% target margin):
    Mince:  R98/kg
    Stew:   R88/kg
  [ACCEPT ALL]  [ADJUST INDIVIDUALLY]  [IGNORE]


Trigger 2: Items approaching expiry / slow-moving:
🔄 CHANGED: Slow-moving trigger days are set per product individually (not system-wide), because shelf life varies enormously across the range. T-Bone may be slow after 3 days; biltong slow after 14 days; spice sachets slow after 45 days.


  MARKDOWN SUGGESTION:
  Lamb Chops — 3.2 kg in stock, only 0.5 kg sold in 3 days
  (Slow-mover trigger for this product: 3 days)
  Sell-by date: 09 Feb 2026 (3 days remaining)
  Suggestion: 20% markdown (R140 → R112) to move stock
  [APPLY]  [DIFFERENT %]  [IGNORE]


10.3 Predictive Reorder Recommendations
Based on sales velocity + current stock + lead time:
  REORDER RECOMMENDATIONS
  ──────────────────────────────────────────────────────────────
  🔴  T-Bone:    2.3 days of stock left → Order NOW (3-day lead time)
  🟡  Rump:      5.1 days of stock left → Order by Friday
  ✅  Mince:     8.4 days of stock left → OK for now
  🔴  Boerewors: 1.1 days of stock left → URGENT (below safety stock)
  [CREATE PURCHASE ORDER]


10.4 Event & Holiday Sales Intelligence (NEW)
✅ NEW: Struisbaai is a holiday and event town. Extreme seasonal peaks are tracked, tagged, and used to generate intelligent pre-event stock and production forecasts.


Event Tagging
* When a day records sales significantly above the rolling average (threshold: owner-configurable, e.g., 200% of normal), system prompts: 'Unusual sales volume detected for [Date]. Was this a specific event or holiday?'
* Owner selects: Public Holiday / Local Event / School Holidays / Easter / Year-End / New Year / Other
* Free-text field: 'Describe event' (e.g. 'Struisbaai Sardine Festival', 'Easter Weekend', 'December Festive Rush')
* Tagged day stored as named event in calendar — used for future forecasting


What the System Tracks Per Event
Data Point
	Purpose
	Total sales value for the event period
	Revenue planning
	Top 20 products by volume and value
	Stock preparation
	Sales by hour of day
	Staffing and production scheduling
	Stock that ran out (zero at end of day)
	Avoid under-buying next time
	Stock leftover at event end
	Avoid over-buying and excess waste
	Production insufficient (had to make more mid-day)
	Better production pre-planning
	Same event vs prior year comparison
	Year-on-year growth tracking
	

Pre-Event Forecast Report
* System asks: 'Are you preparing for [Event Type]?' — suggests based on calendar date
* Shows: Sales data from last 3 occurrences of the same event type
* Recommends: 'Based on Easter 2024 and 2025, you will likely need: T-Bone 45kg, Boerewors 60kg, Lamb Chops 35kg...'
* Owner can adjust recommendations and save as 'Order Plan' for the event
* After the event: system records actuals vs forecast — improves future predictions automatically


11. REPORTING & EXPORTS
11.1 Report Types
Report
	Frequency
	Access
	Daily Sales Summary
	Daily (auto)
	Owner, Manager
	Weekly Sales Report
	Weekly (auto)
	Owner, Manager
	Monthly P&L
	Monthly (auto)
	Owner
	VAT201 Report
	Monthly (auto)
	Owner
	Cash Flow
	Monthly (auto)
	Owner
	Staff Hours Report
	Weekly / Monthly
	Owner, Manager
	Payroll Report
	Monthly
	Owner
	Inventory Valuation
	On demand
	Owner, Manager
	Shrinkage Report
	Weekly (auto)
	Owner
	Supplier Spend Report
	Monthly
	Owner
	Purchases by Supplier
	On demand
	Owner
	Expense Report by Category
	On demand
	Owner
	Product Performance
	On demand
	Owner, Manager
	Customer (Loyalty) Report
	Monthly
	Owner, Manager
	Hunter Jobs Report
	Monthly
	Owner, Manager
	Audit Trail Report
	On demand
	Owner
	BCEA Compliance Report
	Monthly (auto)
	Owner
	Blockman Performance Report
	Monthly
	Owner, Manager
	Event / Holiday Forecast Report
	On demand
	Owner
	Sponsorship & Donations Log
	On demand
	Owner
	Staff Loan & Credit Report
	On demand
	Owner
	AWOL / Absconding Report
	On demand
	Owner
	Equipment Depreciation Schedule
	Annual / On demand
	Owner
	Purchase Sale Agreement History
	On demand
	Owner
	

11.2 Export Formats
* PDF — for printing, emailing, filing, SARS submission
* Excel (.xlsx) — for further analysis, accountant
* CSV — for accountant/bookkeeper import, bulk data


11.3 Auto-Report Schedule
Time
	Report
	Delivery
	Daily at 23:00
	Daily Sales Summary
	Dashboard + optional email
	Monday at 06:00
	Weekly Sales + Shrinkage
	Dashboard + email
	1st of month
	P&L, VAT, Cash Flow
	Dashboard + email + Google Drive
	

12. CUSTOMER MANAGEMENT
12.1 Customer List (From Loyalty App)
Sidebar → 👥 Customers
🔄 CHANGED: Customer profiles now include email address, cell phone/WhatsApp, birthday, and physical address — required for birthday promotions, WhatsApp announcements, and future delivery capability.


Field
	Example
	Notes
	Full Name
	Johan Botha
	

	Email Address
	johan@email.com
	🆕 For promotions and emailed statements
	Cell Phone / WhatsApp
	082 555 0001
	🆕 Primary — WhatsApp announcements
	Birthday
	15 March 1975
	🆕 For birthday voucher automation via Loyalty App
	Physical Address
	12 Strand St, Struisbaai
	🆕 For delivery orders (future) and direct mail
	Loyalty Tier
	VIP
	Member / Elite / VIP — auto-calculated from spend
	Points Balance
	1,245 pts
	Current points if points system active
	Total Spend (All Time)
	R48,500
	Auto from transactions
	Average Monthly Spend
	R2,450
	Rolling 3-month average
	Visit Frequency
	8/month
	Visits per month average
	Favourite Products
	T-Bone, Boerewors, Rump
	Top 5 most purchased — auto from transaction history
	Joined Date
	12 Jan 2025
	When they registered
	Active
	Yes
	

	Notes
	Prefers thick-cut chops, allergic to pork
	🆕 Owner/Manager only — not on receipts or POS
	

Name
	Tier
	Visits/mo
	Spend/mo
	Status
	Johan Botha
	⭐ VIP
	8
	R2,450
	Active
	Maria Santos
	Elite
	12
	R4,200
	Active
	David Nkosi
	Member
	2
	R350
	Active
	

12.2 Announcements
Sidebar → 👥 Customers → Announcements
Create announcements that appear in Customer App:
* Title, body, image (optional)
* Target: All / VIP only / Elite+ / Specific tier
* Schedule: Now or future date/time


12.3 Recipe Library Management
Upload recipes that appear in Customer App:
* Recipe name, photo, ingredients, step-by-step instructions
* Tag: 'Sunday Roast', 'Braai', 'Quick & Easy', 'Game Meat', 'Biltong'


13. SETTINGS
13.1 Business Settings
Setting
	Default
	Description
	Business Name
	Botha's Butchery (Pty) Ltd
	On receipts, reports, VAT invoices
	Address
	Struisbaai
	On receipts
	VAT Number
	4123456789
	On receipts, VAT reports
	Phone
	012 345 6789
	On receipts
	Logo
	upload.png
	On receipts, reports
	Working Hours Start
	07:00
	For overtime calculation
	Working Hours End
	17:00
	For overtime calculation
	Overtime After (daily)
	9 hours
	BCEA: daily threshold
	Weekly Overtime After
	45 hours
	BCEA: weekly threshold
	Sunday Pay Multiplier
	2.0
	BCEA requirement
	Blockman Verification
	Off
	Anti-theft at POS — Blockman must verify large cuts
	Default Markdown % (Freezer)
	Owner sets per product
	🔄 NOT a system-wide default — each product has its own markdown %
	Shrinkage Tolerance
	2%
	Before alert triggers
	Auto-Void Parked Sales
	4 hours
	POS setting
	Receipt Footer
	Thank you!
	Custom text
	Slow-Mover Threshold
	Set per product
	🔄 Days without sale before alert — configured per product, not globally
	

13.2 Scale Settings (Ishida Configuration)
Setting
	Default
	Description
	Scale Brand
	Ishida
	For reference
	Barcode Prefix (Price)
	21
	Price-embedded labels
	Barcode Prefix (Weight)
	20
	Weight-embedded labels
	PLU Digits
	4
	Number of digits in PLU code
	Primary Mode
	Price-embedded
	Which prefix your scales use primarily
	

13.3 Tax Rate Management
Rate Name
	Percentage
	Description
	Standard
	15%
	Most meat and non-basic products
	Zero-Rated
	0%
	Basic foodstuffs (if applicable under SA VAT rules)
	Exempt
	0%
	VAT exempt items
	

13.4 Notification Settings
Trigger
	Channel
	Recipient
	Shrinkage alert (critical)
	Dashboard + Email
	Owner
	Reorder needed
	Dashboard
	Owner, Manager
	Account overdue (7 days)
	Dashboard + optional Email/WhatsApp
	Owner
	Leave request pending
	Dashboard
	Owner, Manager
	Hunter job ready
	WhatsApp
	Customer
	Payslip generated
	WhatsApp / Email
	Staff
	AWOL flag — persistent (3+)
	Dashboard + Email
	Owner
	Stock slow-mover triggered
	Dashboard
	Owner, Manager
	Event sales spike detected
	Dashboard + prompt
	Owner
	

14. AUDIT LOG VIEWER
Sidebar → 📝 Audit Log
Searchable, filterable log of all system events:
Date/Time
	Action
	Who
	Authorised By
	Details
	06 Feb 15:42
	Void Line Item
	Sarah
	Mike (Mgr)
	T-Bone R150, reason: 'wrong'
	06 Feb 14:20
	Discount >10%
	Sarah
	Mike (Mgr)
	15% on R500 order
	06 Feb 12:05
	Cash Drawer Open
	Sarah
	Mike (Mgr)
	'Change for parking'
	06 Feb 10:30
	Price Override
	Johan
	Self (Owner)
	Rump R110→R95 promo
	06 Feb 08:00
	Stock Adjustment
	Johan
	Self (Owner)
	Mince +2.5kg stocktake
	

Filters: [Date Range]  [Action Type]  [Staff Member]  [Severity]


⚠️ IMPORTANT: Immutable: INSERT only — nobody can edit or delete audit logs. Enforced via database Row-Level Security (RLS).


15. ADMIN APP — DATABASE TABLES
Tables Admin WRITES (source of truth)
Table
	Module
	profiles
	HR — staff management
	staff_documents
	HR — document uploads
	business_settings
	Settings
	inventory_items
	Inventory — products, prices, PLUs
	stock_locations
	Inventory — 🆕 named storage locations
	categories
	Inventory
	modifier_groups / modifier_items
	Production
	yield_templates / yield_template_cuts
	Production
	carcass_intakes
	Production
	carcass_breakdown_sessions
	Production — 🆕 supports partial breakdowns
	stock_movements
	Production / Inventory (all types)
	recipes / recipe_ingredients
	Production
	production_batches / production_batch_ingredients
	Production
	dryer_batches / dryer_batch_ingredients
	Production — 🆕 biltong/droewors dryer module
	hunter_services
	Hunter
	hunter_jobs
	Hunter
	hunter_job_processes / hunter_process_materials
	Hunter
	business_accounts
	Accounts
	account_awol_records
	HR — 🆕 AWOL/absconding tracking
	staff_credit / staff_loans
	HR — 🆕 meat purchases + salary advances
	invoices / invoice_line_items
	Bookkeeping
	ledger_entries
	Bookkeeping
	chart_of_accounts
	Bookkeeping — 🆕 fully editable
	equipment_register
	Bookkeeping — 🆕 PTY Ltd conversion
	purchase_sale_agreement / purchase_sale_payments
	Bookkeeping — 🆕 PTY Ltd conversion
	sponsorships / donations
	Inventory — 🆕 separate from waste
	leave_requests
	HR
	payroll_periods / payroll_entries
	HR
	loyalty_customers
	Customers
	announcements
	Settings
	shrinkage_alerts
	Analytics (auto-generated)
	reorder_recommendations
	Analytics (auto-generated)
	event_tags / event_sales_history
	Analytics — 🆕 holiday/event intelligence
	

Tables Admin READS (from other apps)
Table
	Written By
	Admin Uses For
	transactions
	POS App
	Sales reports, P&L, analytics
	transaction_items
	POS App
	Product performance, margins
	till_sessions
	POS App
	Z-reports, cash variance
	parked_sales
	POS App
	View parked sales
	audit_logs
	POS App + Admin
	Audit trail viewer
	timecards
	Clock-In App
	Hours, payroll, compliance
	timecard_breaks
	Clock-In App
	Break tracking (individual break detail), BCEA
	loyalty_points
	Customer App
	Loyalty management
	loyalty_transactions
	Customer App + POS
	Customer analytics
	

16. ADMIN APP — FLUTTER PROJECT STRUCTURE
admin_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   └── admin_config.dart
│   │   ├── services/
│   │   │   ├── supabase_service.dart      # Direct Supabase connection
│   │   │   ├── auth_service.dart           # PIN login
│   │   │   ├── report_service.dart         # PDF/Excel generation
│   │   │   ├── ocr_service.dart            # Google Cloud Vision
│   │   │   ├── whatsapp_service.dart       # Twilio/Meta API
│   │   │   └── export_service.dart         # CSV/XLSX/PDF export
│   │   ├── models/
│   │   │   ├── inventory_item.dart
│   │   │   ├── carcass_intake.dart
│   │   │   ├── yield_template.dart
│   │   │   ├── production_batch.dart
│   │   │   ├── dryer_batch.dart            # NEW
│   │   │   ├── hunter_job.dart
│   │   │   ├── staff_profile.dart
│   │   │   ├── payroll_entry.dart
│   │   │   ├── staff_credit.dart           # NEW
│   │   │   ├── awol_record.dart            # NEW
│   │   │   ├── business_account.dart
│   │   │   ├── invoice.dart
│   │   │   ├── ledger_entry.dart
│   │   │   ├── equipment_asset.dart        # NEW
│   │   │   ├── purchase_sale_agreement.dart# NEW
│   │   │   ├── event_tag.dart              # NEW
│   │   │   └── shrinkage_alert.dart
│   │   └── utils/
│   │       ├── currency_formatter.dart
│   │       ├── date_formatter.dart
│   │       ├── pdf_generator.dart
│   │       └── excel_generator.dart
│   └── features/
│       ├── auth/
│       │   └── screens/pin_screen.dart
│       ├── dashboard/
│       │   ├── screens/dashboard_screen.dart
│       │   └── widgets/ (sales_widget, alerts_widget, chart_widget...)
│       ├── inventory/
│       │   └── screens/
│       │       ├── product_list_screen.dart
│       │       ├── product_form_screen.dart
│       │       ├── category_screen.dart
│       │       ├── modifier_screen.dart
│       │       ├── stock_levels_screen.dart
│       │       ├── stock_take_screen.dart   # Updated: multi-device
│       │       └── supplier_screen.dart
│       ├── production/
│       │   └── screens/
│       │       ├── yield_template_screen.dart
│       │       ├── carcass_intake_screen.dart
│       │       ├── carcass_breakdown_screen.dart  # Updated: partial
│       │       ├── recipe_screen.dart
│       │       ├── production_batch_screen.dart
│       │       └── dryer_batch_screen.dart  # NEW
│       ├── hunter/
│       │   └── screens/
│       │       ├── service_config_screen.dart
│       │       ├── job_list_screen.dart
│       │       ├── job_intake_screen.dart
│       │       ├── job_process_screen.dart
│       │       └── job_summary_screen.dart
│       ├── hr/
│       │   └── screens/
│       │       ├── staff_list_screen.dart
│       │       ├── staff_form_screen.dart
│       │       ├── timecard_screen.dart     # Updated: break detail
│       │       ├── leave_screen.dart
│       │       ├── awol_screen.dart         # NEW
│       │       ├── payroll_screen.dart      # Updated: per-frequency
│       │       ├── staff_credit_screen.dart # NEW
│       │       └── compliance_screen.dart
│       ├── accounts/
│       │   └── screens/
│       │       ├── account_list_screen.dart
│       │       ├── account_detail_screen.dart
│       │       └── statement_screen.dart
│       ├── bookkeeping/
│       │   └── screens/
│       │       ├── invoice_list_screen.dart # Updated: bulk import
│       │       ├── invoice_form_screen.dart
│       │       ├── ledger_screen.dart
│       │       ├── chart_of_accounts_screen.dart  # NEW: editable
│       │       ├── pl_screen.dart
│       │       ├── vat_report_screen.dart
│       │       ├── cash_flow_screen.dart
│       │       ├── equipment_register_screen.dart # NEW
│       │       └── pty_conversion_screen.dart     # NEW
│       ├── analytics/
│       │   └── screens/
│       │       ├── shrinkage_screen.dart
│       │       ├── pricing_screen.dart
│       │       ├── reorder_screen.dart
│       │       └── event_forecast_screen.dart     # NEW
│       ├── reports/
│       │   └── screens/report_hub_screen.dart
│       ├── customers/
│       │   └── screens/
│       │       ├── customer_list_screen.dart
│       │       ├── announcement_screen.dart
│       │       └── recipe_library_screen.dart
│       ├── audit/
│       │   └── screens/audit_log_screen.dart
│       └── settings/
│           └── screens/
│               ├── business_settings_screen.dart
│               ├── scale_settings_screen.dart
│               ├── tax_settings_screen.dart
│               └── notification_settings_screen.dart
└── shared/
    └── widgets/
        ├── sidebar_nav.dart
        ├── data_table.dart
        ├── chart_widgets.dart
        └── form_widgets.dart


pubspec.yaml
windows/


Key Packages
Package
	Version
	Purpose
	flutter_bloc
	^8.1.3
	State management
	supabase_flutter
	^2.0.0
	Database connection
	isar
	^3.1.0
	Offline production workflows
	isar_flutter_libs
	^3.1.0
	Isar support
	syncfusion_flutter_charts
	^24.0.0
	Charts/graphs
	syncfusion_flutter_datagrid
	^24.0.0
	Data tables
	pdf
	^3.10.0
	PDF generation
	excel
	^4.0.0
	Excel export
	csv
	^5.1.0
	CSV export + import
	printing
	^5.11.0
	Print PDFs
	file_picker
	^6.1.0
	File uploads (CSV, PDF, images)
	image_picker
	^1.0.0
	Camera (waste photos, invoices)
	crypto
	^3.0.3
	PIN hashing
	intl
	^0.18.1
	Currency and date formatting
	uuid
	^4.2.2
	Unique ID generation
	url_launcher
	^6.2.0
	Open emails/links
	googleapis
	^12.0.0
	Google Drive OCR
	http
	^1.2.0
	API calls (WhatsApp)
	

17. SUMMARY
Aspect
	Detail
	Purpose
	Manage all business operations behind the counter
	Platform
	Windows 10/11 Desktop (Flutter)
	Users
	Owner (full access), Manager (operational access)
	Database
	Supabase (online-preferred), Isar for production offline
	Modules
	14 — Dashboard, Inventory, Production, Hunter, HR, Accounts, Bookkeeping, Analytics, Reports, Customers, Audit, Settings, PTY Conversion, Dryer/Biltong
	Database Tables
	40+ owned (writes), reads from POS + Clock-In + Customer apps
	Feeds POS
	Products, prices, PLUs, categories, modifiers, staff PINs, tax rates
	Reads from POS
	Transactions, till sessions, audit logs, transaction items
	Reads from Clock-In
	Timecards, individual break records
	Reads from Customer App
	Loyalty points, loyalty transactions
	Key Workflows
	Carcass intake → partial/full breakdown → stock | Recipe → batch → stock | Dryer load → drying period → weigh out → stock | Invoice OCR → ledger → P&L | Event spike → tag → forecast
	PTY Ltd Effective
	1 March 2026 — opening balance, equipment register, purchase sale agreement all loaded on this date
	</content>
<parameter name="filePath">/workspaces/struisbaai_vleismark_admin_app/AdminAppBluePrintTruth.md