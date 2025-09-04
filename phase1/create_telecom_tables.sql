-- =======================================================
-- Telecom Analytics Phase 1: Source Table Creation
-- Project: dbt-bigquery-telecom  
-- Dataset: telecom_raw_data
-- Purpose: Create source tables based on documentation specs
-- =======================================================

-- =============================================
-- CUSTOMERS TABLE
-- =============================================
CREATE OR REPLACE TABLE `dbt-bigquery-telecom.telecom_raw_data.customers` (
  customer_id STRING NOT NULL,
  email STRING NOT NULL,
  phone_number STRING NOT NULL,
  registration_date DATE NOT NULL,
  date_of_birth DATE,
  address_state STRING,
  address_city STRING,
  customer_status STRING NOT NULL,
  updated_at TIMESTAMP NOT NULL
)
PARTITION BY DATE(_PARTITIONTIME)
CLUSTER BY customer_status, address_state
OPTIONS(
  description="Customer master data - foundation for all relationships. Phase 1 validation focus on email uniqueness, phone format, age calculation, and status compliance."
);

-- =============================================
-- SUBSCRIPTIONS TABLE  
-- =============================================
CREATE OR REPLACE TABLE `dbt-bigquery-telecom.telecom_raw_data.subscriptions` (
  subscription_id STRING NOT NULL,
  customer_id STRING NOT NULL,
  plan_id STRING NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  monthly_fee NUMERIC(10,2) NOT NULL
)
PARTITION BY start_date
CLUSTER BY customer_id
OPTIONS(
  description="Customer subscription data - critical for usage attribution. Validates foreign keys, date logic, and pricing."
);

-- =============================================
-- USAGE_RECORDS TABLE (High Volume)
-- =============================================
CREATE OR REPLACE TABLE `dbt-bigquery-telecom.telecom_raw_data.usage_records` (
  usage_id STRING NOT NULL,
  customer_id STRING NOT NULL,
  usage_date DATE NOT NULL,
  call_minutes NUMERIC(10,2),
  sms_count INT64,
  data_mb NUMERIC(15,2)
)
PARTITION BY usage_date
CLUSTER BY customer_id
OPTIONS(
  description="Daily usage records - largest table. Validates customer relationships, usage ranges, and date consistency. Expected 100K-100M+ records daily."
);

-- =============================================
-- BILLING TABLE
-- =============================================
CREATE OR REPLACE TABLE `dbt-bigquery-telecom.telecom_raw_data.billing` (
  bill_id STRING NOT NULL,
  customer_id STRING NOT NULL,
  billing_month DATE NOT NULL,
  total_amount NUMERIC(10,2) NOT NULL,
  payment_date DATE
)
PARTITION BY billing_month  
CLUSTER BY customer_id
OPTIONS(
  description="Monthly billing records - financial integrity critical. Validates amounts, customer relationships, and payment logic."
);

-- =============================================
-- NETWORK_QUALITY TABLE
-- =============================================
CREATE OR REPLACE TABLE `dbt-bigquery-telecom.telecom_raw_data.network_quality` (
  quality_id STRING NOT NULL,
  customer_id STRING NOT NULL,
  call_quality_score INT64 NOT NULL,
  dropped_call BOOLEAN,
  network_type STRING,
  recorded_at TIMESTAMP NOT NULL
)
PARTITION BY DATE(recorded_at)
CLUSTER BY customer_id, network_type
OPTIONS(
  description="Network performance data. Validates score ranges (1-5), boolean fields, network types, and customer relationships."
);

-- =============================================
-- INSERT SAMPLE DATA FOR VALIDATION TESTING
-- =============================================

-- Sample customers data
INSERT INTO `dbt-bigquery-telecom.telecom_raw_data.customers` (
  customer_id, email, phone_number, registration_date, date_of_birth, 
  address_state, address_city, customer_status, updated_at
) VALUES
-- Valid customers for testing
('CUST_001', 'john.doe@email.com', '+1-555-0101', '2023-01-15', '1985-03-10', 'CA', 'Los Angeles', 'Active', CURRENT_TIMESTAMP()),
('CUST_002', 'jane.smith@email.com', '+1-555-0102', '2023-02-20', '1990-07-22', 'NY', 'New York', 'Active', CURRENT_TIMESTAMP()), 
('CUST_003', 'bob.wilson@email.com', '+1-555-0103', '2022-12-01', '1978-11-05', 'TX', 'Dallas', 'Inactive', CURRENT_TIMESTAMP()),
('CUST_004', 'alice.brown@email.com', '+1-555-0104', '2023-03-10', '1992-04-18', 'FL', 'Miami', 'Active', CURRENT_TIMESTAMP()),
('CUST_005', 'charlie.davis@email.com', '+1-555-0105', '2021-08-15', '1980-09-30', 'WA', 'Seattle', 'Churned', CURRENT_TIMESTAMP()),

-- Edge cases for validation testing
('CUST_EDGE1', 'test.validation@domain.co.uk', '15551234567', '2020-01-01', '2008-01-01', 'CA', 'San Francisco', 'Active', CURRENT_TIMESTAMP()), -- Min age
('CUST_EDGE2', 'senior@example.com', '5551234567', '2020-01-01', '1924-01-01', 'NY', 'Buffalo', 'Active', CURRENT_TIMESTAMP()), -- Max age  
('CUST_EDGE3', 'recent@customer.com', '555-123-4567', CURRENT_DATE(), '1985-01-01', 'IL', 'Chicago', 'Active', CURRENT_TIMESTAMP()); -- Recent registration

-- Sample subscriptions
INSERT INTO `dbt-bigquery-telecom.telecom_raw_data.subscriptions` (
  subscription_id, customer_id, plan_id, start_date, end_date, monthly_fee
) VALUES
('SUB_001', 'CUST_001', 'PLAN_UNLIMITED', '2023-01-15', NULL, 79.99),
('SUB_002', 'CUST_002', 'PLAN_BASIC', '2023-02-20', NULL, 39.99),
('SUB_003', 'CUST_003', 'PLAN_PREMIUM', '2022-12-01', '2023-06-01', 99.99),
('SUB_004', 'CUST_004', 'PLAN_BASIC', '2023-03-10', NULL, 39.99),
('SUB_005', 'CUST_005', 'PLAN_UNLIMITED', '2021-08-15', '2023-04-15', 79.99),

-- Test edge cases
('SUB_EDGE1', 'CUST_EDGE1', 'PLAN_STUDENT', CURRENT_DATE(), NULL, 19.99), -- New subscription
('SUB_EDGE2', 'CUST_EDGE2', 'PLAN_SENIOR', '2020-01-01', NULL, 29.99); -- Long-running subscription

-- Sample usage records (recent data)
INSERT INTO `dbt-bigquery-telecom.telecom_raw_data.usage_records` (
  usage_id, customer_id, usage_date, call_minutes, sms_count, data_mb
) VALUES
-- Normal usage patterns
('USG_001_20240901', 'CUST_001', '2024-09-01', 45.5, 25, 1024.0),
('USG_002_20240901', 'CUST_002', '2024-09-01', 120.0, 50, 2048.0),
('USG_003_20240901', 'CUST_004', '2024-09-01', 30.2, 15, 512.0),

-- Edge cases for validation
('USG_EDGE1_20240901', 'CUST_001', '2024-09-01', 0, 0, 0), -- Zero usage
('USG_EDGE2_20240901', 'CUST_002', '2024-09-01', 1440, 10000, 102400), -- Max daily usage
('USG_HEAVY_20240901', 'CUST_001', '2024-09-01', 300.5, 200, 5120.0); -- Heavy usage

-- Sample billing records
INSERT INTO `dbt-bigquery-telecom.telecom_raw_data.billing` (
  bill_id, customer_id, billing_month, total_amount, payment_date
) VALUES
('BILL_001_202408', 'CUST_001', '2024-08-01', 85.49, '2024-08-15'),
('BILL_002_202408', 'CUST_002', '2024-08-01', 42.99, '2024-08-10'),
('BILL_003_202408', 'CUST_004', '2024-08-01', 39.99, NULL), -- Unpaid bill
('BILL_004_202407', 'CUST_001', '2024-07-01', 79.99, '2024-07-12'),

-- Edge cases
('BILL_EDGE1_202408', 'CUST_EDGE1', '2024-08-01', 19.99, '2024-08-05'), -- Low amount
('BILL_EDGE2_202408', 'CUST_EDGE2', '2024-08-01', 5000.00, '2024-08-20'); -- High amount

-- Sample network quality data  
INSERT INTO `dbt-bigquery-telecom.telecom_raw_data.network_quality` (
  quality_id, customer_id, call_quality_score, dropped_call, network_type, recorded_at
) VALUES
('QUAL_001', 'CUST_001', 5, false, '5G', '2024-09-01 10:00:00'),
('QUAL_002', 'CUST_002', 4, false, '4G', '2024-09-01 11:00:00'), 
('QUAL_003', 'CUST_003', 2, true, '3G', '2024-09-01 12:00:00'),
('QUAL_004', 'CUST_004', 5, false, '5G', '2024-09-01 13:00:00'),

-- Edge cases
('QUAL_EDGE1', 'CUST_001', 1, true, 'WiFi', '2024-09-01 14:00:00'), -- Worst quality
('QUAL_EDGE2', 'CUST_002', 5, false, '5G', '2024-09-01 15:00:00'); -- Best quality

-- =============================================
-- VERIFY TABLE CREATION AND DATA
-- =============================================
SELECT 'Tables created successfully' as status;

-- Show row counts
SELECT 
  'customers' as table_name, 
  COUNT(*) as row_count 
FROM `dbt-bigquery-telecom.telecom_raw_data.customers`

UNION ALL

SELECT 
  'subscriptions' as table_name, 
  COUNT(*) as row_count 
FROM `dbt-bigquery-telecom.telecom_raw_data.subscriptions`

UNION ALL

SELECT 
  'usage_records' as table_name, 
  COUNT(*) as row_count 
FROM `dbt-bigquery-telecom.telecom_raw_data.usage_records`

UNION ALL

SELECT 
  'billing' as table_name, 
  COUNT(*) as row_count 
FROM `dbt-bigquery-telecom.telecom_raw_data.billing`

UNION ALL

SELECT 
  'network_quality' as table_name, 
  COUNT(*) as row_count 
FROM `dbt-bigquery-telecom.telecom_raw_data.network_quality`

ORDER BY table_name;