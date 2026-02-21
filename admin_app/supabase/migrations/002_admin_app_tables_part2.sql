-- Admin App Database Migrations - Part 2
-- Remaining tables from blueprint

-- 21. Account AWOL Records
CREATE TABLE IF NOT EXISTS account_awol_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  account_id UUID NOT NULL REFERENCES business_accounts(id) ON DELETE CASCADE,
  awol_date DATE NOT NULL,
  reason TEXT,
  recorded_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 22. Staff Credit
CREATE TABLE IF NOT EXISTS staff_credit (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  credit_amount DECIMAL(10,2) NOT NULL,
  reason TEXT NOT NULL,
  granted_date DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date DATE,
  is_paid BOOLEAN DEFAULT false,
  paid_date DATE,
  granted_by UUID NOT NULL REFERENCES profiles(id),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 23. Staff Loans
CREATE TABLE IF NOT EXISTS staff_loans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  loan_amount DECIMAL(10,2) NOT NULL,
  interest_rate DECIMAL(5,2) DEFAULT 0,
  term_months INTEGER,
  monthly_payment DECIMAL(10,2),
  granted_date DATE NOT NULL DEFAULT CURRENT_DATE,
  first_payment_date DATE,
  is_active BOOLEAN DEFAULT true,
  granted_by UUID NOT NULL REFERENCES profiles(id),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 24. Invoices
CREATE TABLE IF NOT EXISTS invoices (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  invoice_number TEXT UNIQUE NOT NULL,
  account_id UUID REFERENCES business_accounts(id),
  invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date DATE NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
  notes TEXT,
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 25. Invoice Line Items
CREATE TABLE IF NOT EXISTS invoice_line_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  quantity DECIMAL(10,3) NOT NULL DEFAULT 1,
  unit_price DECIMAL(10,2) NOT NULL,
  line_total DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 26. Ledger Entries
CREATE TABLE IF NOT EXISTS ledger_entries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
  account_code TEXT NOT NULL,
  account_name TEXT NOT NULL,
  debit DECIMAL(10,2) DEFAULT 0,
  credit DECIMAL(10,2) DEFAULT 0,
  description TEXT NOT NULL,
  reference_type TEXT CHECK (reference_type IN ('invoice', 'payment', 'adjustment', 'transfer')),
  reference_id UUID,
  recorded_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 27. Chart of Accounts
CREATE TABLE IF NOT EXISTS chart_of_accounts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  account_code TEXT UNIQUE NOT NULL,
  account_name TEXT NOT NULL,
  account_type TEXT NOT NULL CHECK (account_type IN ('asset', 'liability', 'equity', 'income', 'expense')),
  subcategory TEXT,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id)
);

-- 28. Equipment Register
CREATE TABLE IF NOT EXISTS equipment_register (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  asset_number TEXT UNIQUE NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  purchase_date DATE NOT NULL,
  purchase_price DECIMAL(10,2) NOT NULL,
  supplier_name TEXT,
  location TEXT,
  depreciation_method TEXT DEFAULT 'straight_line' CHECK (depreciation_method IN ('straight_line', 'declining_balance')),
  useful_life_years INTEGER NOT NULL,
  salvage_value DECIMAL(10,2) DEFAULT 0,
  accumulated_depreciation DECIMAL(10,2) DEFAULT 0,
  current_value DECIMAL(10,2) GENERATED ALWAYS AS (purchase_price - accumulated_depreciation) STORED,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES profiles(id)
);

-- 29. Purchase Sale Agreement
CREATE TABLE IF NOT EXISTS purchase_sale_agreement (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  agreement_number TEXT UNIQUE NOT NULL,
  agreement_type TEXT NOT NULL CHECK (agreement_type IN ('purchase', 'sale')),
  party_name TEXT NOT NULL,
  party_contact TEXT,
  asset_description TEXT NOT NULL,
  agreed_price DECIMAL(10,2) NOT NULL,
  agreement_date DATE NOT NULL DEFAULT CURRENT_DATE,
  completion_date DATE,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'signed', 'completed', 'cancelled')),
  payment_terms TEXT,
  special_conditions TEXT,
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 30. Purchase Sale Payments
CREATE TABLE IF NOT EXISTS purchase_sale_payments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  agreement_id UUID NOT NULL REFERENCES purchase_sale_agreement(id) ON DELETE CASCADE,
  payment_date DATE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  payment_method TEXT NOT NULL,
  reference_number TEXT,
  notes TEXT,
  recorded_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 31. Sponsorships
CREATE TABLE IF NOT EXISTS sponsorships (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sponsor_name TEXT NOT NULL,
  event_name TEXT NOT NULL,
  sponsorship_amount DECIMAL(10,2) NOT NULL,
  sponsorship_date DATE NOT NULL DEFAULT CURRENT_DATE,
  payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'cancelled')),
  contact_person TEXT,
  contact_details TEXT,
  benefits_provided TEXT,
  notes TEXT,
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 32. Donations
CREATE TABLE IF NOT EXISTS donations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  donor_name TEXT NOT NULL,
  donation_type TEXT NOT NULL CHECK (donation_type IN ('cash', 'goods', 'services')),
  donation_value DECIMAL(10,2),
  donation_date DATE NOT NULL DEFAULT CURRENT_DATE,
  payment_status TEXT NOT NULL DEFAULT 'received' CHECK (payment_status IN ('received', 'pending', 'cancelled')),
  contact_details TEXT,
  purpose TEXT,
  tax_certificate_issued BOOLEAN DEFAULT false,
  notes TEXT,
  recorded_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 33. Payroll Periods
CREATE TABLE IF NOT EXISTS payroll_periods (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  period_name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'processing', 'completed', 'closed')),
  processed_at TIMESTAMP WITH TIME ZONE,
  processed_by UUID REFERENCES profiles(id),
  total_gross DECIMAL(10,2) DEFAULT 0,
  total_deductions DECIMAL(10,2) DEFAULT 0,
  total_net DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 34. Payroll Entries
CREATE TABLE IF NOT EXISTS payroll_entries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  payroll_period_id UUID NOT NULL REFERENCES payroll_periods(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  basic_salary DECIMAL(10,2) NOT NULL DEFAULT 0,
  overtime_hours DECIMAL(5,2) DEFAULT 0,
  overtime_rate DECIMAL(10,2) DEFAULT 0,
  overtime_amount DECIMAL(10,2) DEFAULT 0,
  sunday_hours DECIMAL(5,2) DEFAULT 0,
  sunday_rate DECIMAL(10,2) DEFAULT 0,
  sunday_amount DECIMAL(10,2) DEFAULT 0,
  public_holiday_hours DECIMAL(5,2) DEFAULT 0,
  public_holiday_rate DECIMAL(10,2) DEFAULT 0,
  public_holiday_amount DECIMAL(10,2) DEFAULT 0,
  gross_pay DECIMAL(10,2) GENERATED ALWAYS AS (
    basic_salary + overtime_amount + sunday_amount + public_holiday_amount
  ) STORED,
  uif_deduction DECIMAL(10,2) GENERATED ALWAYS AS (basic_salary * 0.01) STORED,
  other_deductions DECIMAL(10,2) DEFAULT 0,
  total_deductions DECIMAL(10,2) GENERATED ALWAYS AS (uif_deduction + other_deductions) STORED,
  net_pay DECIMAL(10,2) GENERATED ALWAYS AS (gross_pay - total_deductions) STORED,
  payment_date DATE,
  payment_method TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 35. Loyalty Customers
CREATE TABLE IF NOT EXISTS loyalty_customers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_name TEXT NOT NULL,
  phone_number TEXT,
  email TEXT,
  date_of_birth DATE,
  join_date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_points INTEGER DEFAULT 0,
  points_used INTEGER DEFAULT 0,
  current_points INTEGER GENERATED ALWAYS AS (total_points - points_used) STORED,
  tier TEXT NOT NULL DEFAULT 'bronze' CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
  is_active BOOLEAN DEFAULT true,
  last_visit DATE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 36. Announcements
CREATE TABLE IF NOT EXISTS announcements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  announcement_type TEXT NOT NULL DEFAULT 'general' CHECK (announcement_type IN ('general', 'promotion', 'event', 'maintenance')),
  priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  is_active BOOLEAN DEFAULT true,
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date DATE,
  target_audience TEXT DEFAULT 'all' CHECK (target_audience IN ('all', 'customers', 'staff')),
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 37. Event Tags
CREATE TABLE IF NOT EXISTS event_tags (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_name TEXT NOT NULL,
  event_date DATE NOT NULL,
  event_type TEXT NOT NULL CHECK (event_type IN ('holiday', 'school_holiday', 'public_holiday', 'sporting_event', 'local_event')),
  expected_impact TEXT CHECK (expected_impact IN ('high', 'medium', 'low')),
  notes TEXT,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 38. Event Sales History
CREATE TABLE IF NOT EXISTS event_sales_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id UUID NOT NULL REFERENCES event_tags(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  sales_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  transaction_count INTEGER NOT NULL DEFAULT 0,
  avg_transaction DECIMAL(10,2) GENERATED ALWAYS AS (
    CASE WHEN transaction_count > 0 THEN sales_amount / transaction_count ELSE 0 END
  ) STORED,
  top_products JSONB, -- Store array of top product objects
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);