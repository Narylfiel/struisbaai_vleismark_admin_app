# Employee Reference Table Mapping
# =================================
# This document defines which table should be used as the source of truth
# for employee/staff references in all joins across the database.
# Use this mapping to prevent Foreign Key conflicts between the POS and Admin apps.

── USE profiles(full_name) when joining from the following columns: ──
stock_movements.staff_id
audit_log.staff_id
transactions.staff_id
stock_take_sessions.started_by
stock_take_sessions.approved_by
stock_take_entries.counted_by
carcass_breakdown_sessions.processed_by
hunter_job_processes.processed_by
staff_awol_records.staff_id
staff_awol_records.recorded_by
staff_credit.staff_id
staff_credit.granted_by
staff_loans.staff_id
staff_loans.granted_by
staff_documents.employee_id
staff_documents.uploaded_by
payroll_periods.processed_by
account_transactions.recorded_by
shrinkage_alerts.resolved_by
equipment_register.updated_by
announcements.created_by
supplier_invoices.created_by
customer_invoices.created_by
purchase_orders.created_by
ledger_entries.recorded_by
donations.recorded_by
sponsorships.created_by

── USE staff_profiles(full_name) when joining from the following columns: ──
timecards.staff_id
leave_requests.staff_id
leave_requests.approved_by
payroll_entries.staff_id
payroll_entries.approved_by
staff_credits.staff_id
awol_records.staff_id
compliance_records.staff_id
compliance_records.verified_by
shrinkage_alerts.acknowledged_by
stock_takes.approved_by
leave_balances.staff_id
invoices.created_by
ledger_entries.created_by

# Notes:
# 1. Always join using the full_name field when querying employee names for display.
# 2. Any new table or column referencing employees should follow this mapping to avoid FK conflicts.
# 3. Profiles table is primarily for POS transactions and reporting.
# 4. Staff_profiles table is primarily for Admin App HR, payroll, and compliance records.
