# Test Framework Validation Guide

## 🎯 Purpose

This document explains our **intentional test failure strategy** to prove the dbt validation framework is working correctly.

## 🔴 billing_test_fail Table

### Table Design
**Location**: `dbt-bigquery-telecom.telecom_raw_data.billing_test_fail`

**Intentional Schema Issues**:
- ❌ **`billing_month`**: STRING (should be DATE)
- ❌ **`total_amount`**: Nullable (should be NOT NULL)
- ❌ **Not partitioned** (unlike the main billing table)

### Sample Data
```sql
-- Record with NULL total_amount (triggers not_null test failure)
INSERT INTO billing_test_fail VALUES 
('BILL_FAIL_002', 'CUST_002', '2024-08', NULL, '2024-08-10');

-- Record with STRING date format (triggers type validation issues)  
INSERT INTO billing_test_fail VALUES
('BILL_FAIL_001', 'CUST_001', '2024-08', 85.49, '2024-08-15');
```

## 🧪 Expected Test Results

### ✅ Tests That Should PASS (5 tests)
1. **`source_unique_raw_telecom_billing_test_fail_bill_id`** - Unique constraint
2. **`source_not_null_raw_telecom_billing_test_fail_bill_id`** - Primary key not null
3. **`source_not_null_raw_telecom_billing_test_fail_customer_id`** - Foreign key not null
4. **`source_not_null_raw_telecom_billing_test_fail_billing_month`** - Date field not null
5. **`source_relationships_...customer_id`** - Foreign key relationship

### 🔴 Tests That Should FAIL (2 tests)
1. **`source_not_null_raw_telecom_billing_test_fail_total_amount`** - **FAILS** ❌
   - **Reason**: Record `BILL_FAIL_002` has `NULL` in `total_amount`
   - **This proves**: NOT NULL constraint validation works

2. **`dbt_utils_expression_is_true...billing_month`** - **ERROR** ❌
   - **Reason**: Data type/format validation issues
   - **This proves**: Data type validation framework is active

## 🚀 How to Test

### Run Framework Validation
```bash
# Test only the intentional failure table
dbt test --select source:raw_telecom.billing_test_fail

# Expected results:
# ✅ PASS: 5 tests
# 🔴 FAIL/ERROR: 2 tests
```

### Verify Specific Failures
```bash
# Check the NULL value that caused failure
bq query --use_legacy_sql=false --project_id=dbt-bigquery-telecom \
"SELECT * FROM \`dbt-bigquery-telecom\`.\`telecom_dev_dbt_test__audit\`.\`source_not_null_raw_telecom_billing_test_fail_total_amount\`"

# Should return: BILL_FAIL_002 | CUST_002 | 2024-08 | NULL | 2024-08-10
```

## 🎉 Success Criteria

If you see the expected failures above, **your dbt test framework is working correctly!**

### What This Proves
- ✅ **NULL Detection**: Framework catches missing required values
- ✅ **Data Type Validation**: Framework detects schema inconsistencies  
- ✅ **Foreign Key Validation**: Relationship integrity is enforced
- ✅ **Uniqueness Constraints**: Duplicate detection works
- ✅ **Test Execution**: dbt test runner is functioning properly

### Production Readiness
With these validation tests passing (by failing!), you can be confident that:
- Real data quality issues will be detected
- Constraint violations will trigger alerts
- The telecom analytics pipeline has robust quality gates

## 🔧 Troubleshooting

### If All Tests Pass (Unexpected)
- Check that the `billing_test_fail` table has the NULL data
- Verify the test configuration includes the intentional failure tests
- Ensure you're running tests on the correct table

### If Too Many Tests Fail
- Verify you ran the data insertion script first: `bq query < phase1/create_telecom_tables.sql`
- Check that partition tests aren't failing due to empty tables
- Ensure your BigQuery project has billing enabled

---

**Remember**: These failures are **intentional and expected**. They prove your data quality framework works! 🎯