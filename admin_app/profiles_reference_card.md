profiles.id  ←─────────────────────────────────────────────
  stock_movements.staff_id
  audit_log.staff_id
  transactions.staff_id
  stock_take_sessions.started_by / approved_by
  stock_take_entries.counted_by
  carcass_breakdown_sessions.processed_by
  hunter_job_processes.processed_by
  staff_awol_records.staff_id / recorded_by
  staff_credit.staff_id / granted_by
  staff_loans.staff_id / granted_by
  staff_documents.employee_id / uploaded_by
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

staff_profiles.id  ←────────────────────────────────────────
  timecards.staff_id
  leave_requests.staff_id / approved_by
  payroll_entries.staff_id / approved_by
  staff_credits.staff_id
  awol_records.staff_id
  compliance_records.staff_id / verified_by
  shrinkage_alerts.acknowledged_by
  stock_takes.approved_by
  leave_balances.staff_id
  invoices.created_by
  ledger_entries.created_by