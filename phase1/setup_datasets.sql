-- BigQuery Dataset Setup for Telecom dbt Analytics Project
-- Run these commands in BigQuery Console or using bq CLI

-- Development dataset
CREATE SCHEMA IF NOT EXISTS `mytrial-billinglearningaccount.telecom_dev`
OPTIONS (
  description = "Development dataset for telecom dbt analytics - Phase 1 validation",
  location = "US"
);

-- Test dataset  
CREATE SCHEMA IF NOT EXISTS `mytrial-billinglearningaccount.telecom_test`
OPTIONS (
  description = "Test dataset for telecom dbt analytics - validation testing",
  location = "US"
);

-- Production dataset (for future use)
CREATE SCHEMA IF NOT EXISTS `mytrial-billinglearningaccount.telecom_prod`
OPTIONS (
  description = "Production dataset for telecom dbt analytics - Phase 2 deployment",
  location = "US"
);

-- Raw data dataset 
CREATE SCHEMA IF NOT EXISTS `mytrial-billinglearningaccount.telecom_raw_data`
OPTIONS (
  description = "Raw telecom data sources for dbt transformation",
  location = "US"
);

-- Data quality monitoring dataset
CREATE SCHEMA IF NOT EXISTS `mytrial-billinglearningaccount.telecom_data_qa_monitor`
OPTIONS (
  description = "Telecom data quality monitoring and Elementary tables",
  location = "US"
);