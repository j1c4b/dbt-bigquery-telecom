-- Telecom Analytics Phase 1: Source Table Creation
-- Project: dbt-bigquery-telecom
-- Date: 2025-09-03

-- =============================================
-- CUSTOMERS TABLE
-- =============================================
CREATE OR REPLACE TABLE `dbt-bigquery-telecom.telecom_raw_data.customers` (
  customer_id STRING NOT NULL,
  first_name STRING NOT NULL,
  last_name STRING NOT NULL,
  email STRING,
  phone_number STRING,
  date_of_birth DATE,
  customer_since DATE NOT NULL,
  customer_status STRING NOT NULL, -- active, suspended, cancelled
  account_type STRING NOT NULL, -- individual, business, family
  address_line1 STRING,
  address_line2 STRING,
  city STRING,
  state STRING,
  zip_code STRING,
  country STRING NOT NULL DEFAULT 'US',
  credit_score INT64,
  preferred_language STRING DEFAULT 'EN',
  marketing_consent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- =============================================
-- PLANS TABLE
-- =============================================
CREATE OR REPLACE TABLE `dbt-bigquery-telecom.telecom_raw_data.plans` (
  plan_id STRING NOT NULL,
  plan_name STRING NOT NULL,
  plan_type STRING NOT NULL, -- postpaid, prepaid
  service_type STRING NOT NULL, -- mobile, internet, tv, bundle
  monthly_fee NUMERIC(10,2) NOT NULL,
  data_allowance_gb INT64, -- NULL for unlimited
  voice_minutes INT64, -- NULL for unlimited
  sms_allowance INT64, -- NULL for unlimited
  international_included BOOLEAN DEFAULT FALSE,
  roaming_included BOOLEAN DEFAULT FALSE,
  contract_length_months INT64, -- NULL for no contract
  activation_fee NUMERIC(10,2) DEFAULT 0,
  early_termination_fee NUMERIC(10,2) DEFAULT 0,
  plan_status STRING NOT NULL DEFAULT 'active', -- active, discontinued
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- =============================================
-- CUSTOMER PLANS TABLE (subscription history)
-- =============================================
CREATE OR REPLACE TABLE `dbt-bigquery-telecom.telecom_raw_data.customer_plans` (
  subscription_id STRING NOT NULL,
  customer_id STRING NOT NULL,
  plan_id STRING NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE, -- NULL if active
  subscription_status STRING NOT NULL, -- active, suspended, cancelled
  activation_channel STRING, -- online, store, phone, partner
  monthly_discount_amount NUMERIC(10,2) DEFAULT 0,
  notes STRING,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- =============================================
-- USAGE TABLE
-- =============================================
CREATE OR REPLACE TABLE `dbt-bigquery-telecom.telecom_raw_data.usage` (
  usage_id STRING NOT NULL,
  customer_id STRING NOT NULL,
  subscription_id STRING NOT NULL,
  usage_date DATE NOT NULL,
  usage_type STRING NOT NULL, -- voice, sms, data, international
  usage_category STRING, -- domestic, international, roaming
  quantity NUMERIC(15,6) NOT NULL, -- minutes, SMS count, MB
  unit_type STRING NOT NULL, -- minutes, sms, mb, gb
  unit_rate NUMERIC(10,6), -- rate per unit if applicable
  total_cost NUMERIC(10,2) DEFAULT 0,
  network_type STRING, -- 3G, 4G, 5G, WiFi
  location_country STRING,
  location_city STRING,
  device_type STRING, -- smartphone, tablet, iot
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- =============================================
-- BILLING TABLE
-- =============================================
CREATE OR REPLACE TABLE `dbt-bigquery-telecom.telecom_raw_data.billing` (
  invoice_id STRING NOT NULL,
  customer_id STRING NOT NULL,
  billing_period_start DATE NOT NULL,
  billing_period_end DATE NOT NULL,
  invoice_date DATE NOT NULL,
  due_date DATE NOT NULL,
  
  -- Charges breakdown
  plan_charges NUMERIC(10,2) NOT NULL DEFAULT 0,
  usage_charges NUMERIC(10,2) NOT NULL DEFAULT 0,
  international_charges NUMERIC(10,2) NOT NULL DEFAULT 0,
  roaming_charges NUMERIC(10,2) NOT NULL DEFAULT 0,
  equipment_charges NUMERIC(10,2) NOT NULL DEFAULT 0,
  fees_and_taxes NUMERIC(10,2) NOT NULL DEFAULT 0,
  discounts NUMERIC(10,2) NOT NULL DEFAULT 0,
  
  -- Totals
  subtotal NUMERIC(10,2) NOT NULL,
  tax_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(10,2) NOT NULL,
  
  -- Payment info
  payment_status STRING NOT NULL DEFAULT 'pending', -- pending, paid, overdue, cancelled
  payment_date DATE,
  payment_method STRING, -- credit_card, bank_transfer, cash, auto_pay
  
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- =============================================
-- NETWORK EVENTS TABLE
-- =============================================
CREATE OR REPLACE TABLE `dbt-bigquery-telecom.telecom_raw_data.network_events` (
  event_id STRING NOT NULL,
  customer_id STRING NOT NULL,
  event_timestamp TIMESTAMP NOT NULL,
  event_type STRING NOT NULL, -- call_start, call_end, sms_sent, data_session
  event_status STRING NOT NULL, -- success, failed, dropped
  duration_seconds INT64, -- for calls and data sessions
  network_cell_id STRING,
  network_type STRING, -- 3G, 4G, 5G
  signal_strength INT64, -- dBm
  location_lat NUMERIC(10,6),
  location_lng NUMERIC(10,6),
  device_imei STRING,
  failure_reason STRING, -- if event_status = failed
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- =============================================
-- Add sample data for testing
-- =============================================

-- Sample customers
INSERT INTO `dbt-bigquery-telecom.telecom_raw_data.customers` 
(customer_id, first_name, last_name, email, phone_number, date_of_birth, customer_since, customer_status, account_type, city, state, country, credit_score)
VALUES 
('CUST001', 'John', 'Smith', 'john.smith@email.com', '+1234567890', '1985-03-15', '2023-01-15', 'active', 'individual', 'New York', 'NY', 'US', 750),
('CUST002', 'Jane', 'Johnson', 'jane.johnson@email.com', '+1234567891', '1990-07-22', '2023-02-01', 'active', 'individual', 'Los Angeles', 'CA', 'US', 680),
('CUST003', 'Bob', 'Wilson', 'bob.wilson@email.com', '+1234567892', '1978-11-30', '2022-12-10', 'active', 'business', 'Chicago', 'IL', 'US', 720);

-- Sample plans
INSERT INTO `dbt-bigquery-telecom.telecom_raw_data.plans`
(plan_id, plan_name, plan_type, service_type, monthly_fee, data_allowance_gb, voice_minutes, sms_allowance, contract_length_months)
VALUES
('PLAN001', 'Basic Mobile', 'postpaid', 'mobile', 29.99, 5, 500, 1000, 12),
('PLAN002', 'Unlimited Premium', 'postpaid', 'mobile', 79.99, NULL, NULL, NULL, 24),
('PLAN003', 'Business Data', 'postpaid', 'mobile', 49.99, 25, 1000, 2000, 12),
('PLAN004', 'Prepaid Starter', 'prepaid', 'mobile', 25.00, 3, 300, 500, NULL);

-- Sample customer plans (subscriptions)
INSERT INTO `dbt-bigquery-telecom.telecom_raw_data.customer_plans`
(subscription_id, customer_id, plan_id, start_date, subscription_status, activation_channel)
VALUES
('SUB001', 'CUST001', 'PLAN002', '2023-01-15', 'active', 'online'),
('SUB002', 'CUST002', 'PLAN001', '2023-02-01', 'active', 'store'),
('SUB003', 'CUST003', 'PLAN003', '2022-12-10', 'active', 'phone');

-- Sample usage data
INSERT INTO `dbt-bigquery-telecom.telecom_raw_data.usage`
(usage_id, customer_id, subscription_id, usage_date, usage_type, usage_category, quantity, unit_type, unit_rate, total_cost, network_type)
VALUES
('USG001', 'CUST001', 'SUB001', '2023-03-01', 'voice', 'domestic', 45.5, 'minutes', 0, 0, '5G'),
('USG002', 'CUST001', 'SUB001', '2023-03-01', 'data', 'domestic', 1024, 'mb', 0, 0, '5G'),
('USG003', 'CUST002', 'SUB002', '2023-03-01', 'voice', 'domestic', 125.2, 'minutes', 0.10, 12.52, '4G'),
('USG004', 'CUST002', 'SUB002', '2023-03-01', 'data', 'domestic', 2048, 'mb', 0.01, 20.48, '4G'),
('USG005', 'CUST003', 'SUB003', '2023-03-01', 'data', 'domestic', 15360, 'mb', 0, 0, '5G');

-- Sample billing data
INSERT INTO `dbt-bigquery-telecom.telecom_raw_data.billing`
(invoice_id, customer_id, billing_period_start, billing_period_end, invoice_date, due_date, plan_charges, usage_charges, subtotal, tax_amount, total_amount, payment_status)
VALUES
('INV001', 'CUST001', '2023-03-01', '2023-03-31', '2023-04-01', '2023-04-15', 79.99, 0, 79.99, 6.40, 86.39, 'paid'),
('INV002', 'CUST002', '2023-03-01', '2023-03-31', '2023-04-01', '2023-04-15', 29.99, 33.00, 62.99, 5.04, 68.03, 'paid'),
('INV003', 'CUST003', '2023-03-01', '2023-03-31', '2023-04-01', '2023-04-15', 49.99, 0, 49.99, 4.00, 53.99, 'pending');