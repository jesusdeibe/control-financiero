-- ============================================================================
-- SUPABASE SCHEMA - Control Financiero App
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- ACCOUNTS TABLE
-- ============================================================================
CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#3B82F6',
  initial_balance DECIMAL(10,2) NOT NULL DEFAULT 0,
  include_in_patrimony BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- TRANSACTIONS TABLE
-- ============================================================================
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type TEXT NOT NULL, -- 'ingresos', 'gastos_personales', 'gastos_compartidos', 'inversiones'
  date DATE NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  account TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  fixed_expense_id UUID, -- Link to fixed expense if auto-created
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_account ON transactions(account);

-- ============================================================================
-- HOLDINGS (INVESTMENT POSITIONS) TABLE
-- ============================================================================
CREATE TABLE holdings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  type TEXT NOT NULL, -- 'Acciones', 'ETFs', 'Criptomonedas'
  account TEXT NOT NULL,
  capital DECIMAL(10,2) NOT NULL,
  current_value DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- TRANSFERS TABLE
-- ============================================================================
CREATE TABLE transfers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE NOT NULL,
  from_account TEXT NOT NULL,
  to_account TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  concept TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_transfers_date ON transfers(date);

-- ============================================================================
-- CONTRIBUTIONS (MONTHLY SHARED ACCOUNT) TABLE
-- ============================================================================
CREATE TABLE contributions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  month_key TEXT NOT NULL UNIQUE, -- '0-2025', '1-2025', etc.
  my DECIMAL(10,2) NOT NULL DEFAULT 0,
  partner DECIMAL(10,2) NOT NULL DEFAULT 0,
  external DECIMAL(10,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- FIXED EXPENSES TABLE
-- ============================================================================
CREATE TABLE fixed_expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  type TEXT NOT NULL, -- 'gastos_personales' or 'gastos_compartidos'
  category TEXT NOT NULL,
  account TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  months INTEGER[] NOT NULL, -- [0,1,2,3,4,5,6,7,8,9,10,11]
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- FIXED EXPENSES PAID TABLE (tracking which ones paid each month)
-- ============================================================================
CREATE TABLE fixed_expenses_paid (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  month_key TEXT NOT NULL, -- '0-2025', '1-2025', etc.
  fixed_expense_id UUID NOT NULL REFERENCES fixed_expenses(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(month_key, fixed_expense_id)
);

CREATE INDEX idx_fixed_expenses_paid_month ON fixed_expenses_paid(month_key);

-- ============================================================================
-- MONTHLY PATRIMONY SNAPSHOTS TABLE
-- ============================================================================
CREATE TABLE monthly_patrimony (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  month_key TEXT NOT NULL UNIQUE, -- '0-2025', '1-2025', etc.
  value DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- CUSTOM CATEGORIES TABLE (optional, for user-added categories)
-- ============================================================================
CREATE TABLE custom_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type TEXT NOT NULL, -- 'ingresos', 'gastos_personales', 'gastos_compartidos', 'inversiones'
  categories TEXT[] NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- FUNCTIONS FOR UPDATED_AT TRIGGERS
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_holdings_updated_at BEFORE UPDATE ON holdings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contributions_updated_at BEFORE UPDATE ON contributions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fixed_expenses_updated_at BEFORE UPDATE ON fixed_expenses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_monthly_patrimony_updated_at BEFORE UPDATE ON monthly_patrimony
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================
-- For now, allow all operations (later can add user authentication)
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE holdings ENABLE ROW LEVEL SECURITY;
ALTER TABLE transfers ENABLE ROW LEVEL SECURITY;
ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE fixed_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE fixed_expenses_paid ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_patrimony ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_categories ENABLE ROW LEVEL SECURITY;

-- Allow all operations for anon users (for now - single user app)
CREATE POLICY "Allow all for anon" ON accounts FOR ALL USING (true);
CREATE POLICY "Allow all for anon" ON transactions FOR ALL USING (true);
CREATE POLICY "Allow all for anon" ON holdings FOR ALL USING (true);
CREATE POLICY "Allow all for anon" ON transfers FOR ALL USING (true);
CREATE POLICY "Allow all for anon" ON contributions FOR ALL USING (true);
CREATE POLICY "Allow all for anon" ON fixed_expenses FOR ALL USING (true);
CREATE POLICY "Allow all for anon" ON fixed_expenses_paid FOR ALL USING (true);
CREATE POLICY "Allow all for anon" ON monthly_patrimony FOR ALL USING (true);
CREATE POLICY "Allow all for anon" ON custom_categories FOR ALL USING (true);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================
CREATE INDEX idx_transactions_fixed_expense ON transactions(fixed_expense_id);
CREATE INDEX idx_holdings_account ON holdings(account);
CREATE INDEX idx_fixed_expenses_type ON fixed_expenses(type);
