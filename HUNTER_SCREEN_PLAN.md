# Blueprint Audit: Hunter Screen Planning Document

**Authoritative Reference:** `AdminAppBluePrintTruth.md` (Lines 1140–1309)
**Domain Scope:** Sidebar → 🦌 Hunter
**Objective:** Planning the fully custom module that handles game carcass processing.

---

## 1. Blueprint Audit — Key Points & Constraints

### Constraints & Rules
- **Configuration Flexibility:** The system must not hardcode services. All processes (e.g., "Make Droewors", "Vacuum Seal") are managed dynamically by the owner through the `hunter_services` table.
- **Service Segregation:** General walk-in retail services are treated as normal POS line items. The Hunter module is dedicated exclusively to multi-step game carcass jobs.
- **Workflow Linearity:** Hunter Jobs move through a strict state progression: `Intake` → `Processing` (sequential service steps) → `Job Summary` → `Ready for Collection` → `Completed`.
- **Validation Mandates:** During processing, the Blockman must manually input the total yield, and it must equal the input weight exactly relative to process yields to prevent unlogged shrinkage.
- **Deposit Architecture:** The UI must calculate an upfront estimate during `Intake` and enforce the capturing of a deposit. This deposit affects the final job balance.

---

## 2. Planned Features & Interactions

### Tab 1: Hunter Dashboard (Active Jobs)
- **Features:** A grid or list visualizing all open processing orders.
- **Interactions:** Tap a job card to open the workflow progression wizard.
- **Validations:** Visual indicators (badges/colors) denote the current job state (Intake, Processing, Collection).

### Tab 2: New Job / Intake Form
- **Form Fields:**
  - Customer Information (Name, Phone, Email - Optional)
  - Carcass Data (Animal Type dropdown, Estimated Raw Weight, Special Notes)
  - Service Selection (Dynamically mapped checklist from `hunter_services`)
- **Interactions:**
  - Dynamic Cost Estimation: As checkboxes are selected, math calculates `(Est. Weight × Rate)`.
  - Deposit Input: Enforces capturing an upfront Rand deposit amount.
- **Actions:** Selecting `[CREATE JOB]` triggers an automated WhatsApp message to the customer with an estimated invoice and pushes the job state to `Intake`.

### Tab 3: Processing Workflow Wizard
- **Features:** A sequential UI guiding the Blockman through the specific services selected at Intake.
- **Process Step Structure:**
  - **Input:** Actual weighed raw meat entering the specific step.
  - **Outputs (Manual Input):** The specific yields generated (Steaks, Trim, Waste). 
  - **Auto-Suggestions:** If a service dictates it (e.g., Make Droewors), the system pre-populates `Materials` (Spices, Casings) based on `Qty per kg Input` multipliers, which the Blockman can manually override.
- **Validations:** The total sum of the outputs (Meat + Bone + Waste) MUST equal the inputted weight. A hard stop prevents moving forward until mathematically balanced.
- **Actions:** `[COMPLETE PROCESS X]` saves the outputs to `hunter_process_outputs` and materials into `hunter_process_materials`.

### Tab 4: Job Summary & Invoicing
- **Features:** Final generation of the absolute job costs.
- **Calculations:** 
  - Cost of processing steps based on exact output volumes.
  - Cost of physical materials consumed.
  - + 15% VAT calculation.
  - Subtraction of the initial deposit to display `BALANCE DUE`.
- **Actions:** `[PRINT INVOICE]`, `[MARK READY FOR COLLECTION]` (triggers "ready" WhatsApp API call).

### Tab 5: Service Configuration (Admin Only)
- **Features:** Settings terminal mapping to `hunter_services`.
- **Form Fields:** Service Name, Rate Type (`per_kg`, `per_pack`), Rate (ZAR), Expected Yield (%), Min Weight (kg), and Active boolean toggle.
- **Sub-Mapping:** Ability to bind default inventory commodities (Spices, Bags) to a service dynamically so they auto-suggest during Workflow Processing.

---

## 3. Integration & Dependencies

### Internal Database Tables (Supabase)
- `hunter_services`: The root configuration table powering the checklist UI and pricing rules.
- `hunter_jobs`: The core parent row holding the Customer, Animal, and deposit values.
- `hunter_job_processes`: Child rows to `hunter_jobs` tracking individual sub-steps (e.g. 1 process for Cut & Pack, 1 process for Biltong).
- `hunter_process_materials`: Logs consumed items (casings, spices).
- `hunter_process_outputs`: Logs the physical yields generated per process.

### External Table Dependencies
- `inventory_items`: Physical stocks deducted automatically upon `hunter_process_materials` submission.

### External System Capabilities
- **Messaging Service:** Native integration sending async WhatsApp templates upon `Job Created` and `Ready for Collection`.
- **Printing Service:** Connection to thermal printing libraries (`printing` package) executing Bluetooth/USB ticket rendering for the finalized Job Summary.

---

## 4. Notes & Rationale
- **Traceability:** Creating independent DB rows for `hunter_job_processes` prevents monolithic data structures and allows one Blockman to run Process 1, while another takes over Process 2.
- **Performance Grading:** Storing both the `Expected Yield` (from config) and actual weighed output allows the backend to generate performance grading charts (e.g., evaluating Blockman efficiency) outside of this specific screen.
- **Accounting Safety:** By rigidly capturing the Deposit upfront as a hard value on the `hunter_jobs` table, the Daily Cashup reporting logic can sync perfectly without manual double-entry.
