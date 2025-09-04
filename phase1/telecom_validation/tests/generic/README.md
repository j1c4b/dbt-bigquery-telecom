# Generic Tests

This directory contains custom generic tests for the telecom validation framework.

## Available Tests

### `test_table_is_partitioned`

**Purpose**: Validates that BigQuery tables have partitioning enabled by checking the `INFORMATION_SCHEMA.PARTITIONS` for partition entries.

**Usage**: 
```yaml
tests:
  - table_is_partitioned
```

**Important Notes**:
- ⚠️ **Requires data**: This test only passes when the table contains data
- 📊 **BigQuery behavior**: Empty partitioned tables don't appear in `INFORMATION_SCHEMA.PARTITIONS`
- 🔄 **Test order**: Run after sample data insertion

**Example**:
```yaml
sources:
  - name: raw_telecom
    tables:
      - name: billing
        description: "Monthly billing records"
        tests:
          - table_is_partitioned  # Validates billing_month partitioning
```

**Test Logic**:
1. Queries `INFORMATION_SCHEMA.PARTITIONS` for the table
2. Counts partition entries
3. Fails if count = 0 (no partitions found)
4. Passes if count > 0 (partitions exist)

**Troubleshooting**:
- If test fails on known partitioned table, check if table has data
- Empty tables will always fail this test
- Insert sample data first, then run partition validation