# Telecom Validation - dbt Project

This is the **Phase 1** dbt project for the Telecom Analytics Platform, focused on data structure validation and quality testing.

## 🎯 Phase 1 Objectives

- **Data Structure Validation**: Verify schema consistency and data types
- **Business Rule Testing**: Validate telecom domain logic and constraints
- **Quality Baseline**: Establish data quality metrics for Phase 2 advancement
- **Comprehensive Testing**: Implement generic, singular, and advanced statistical tests

## 🏗️ Project Structure

```
telecom_validation/
├── dbt_project.yml          # Project configuration
├── packages.yml             # Testing dependencies
├── models/
│   └── staging/            # Staging models with validation focus
├── tests/
│   ├── generic/           # Reusable test macros
│   └── singular/          # Specific validation tests
├── macros/                # Custom utility macros
├── seeds/                 # Reference data (e.g., valid plan types)
├── snapshots/             # Data change tracking (if needed)
└── analyses/              # Ad-hoc validation queries
```

## 🧪 Testing Framework

### Package Dependencies
- **dbt-expectations**: Advanced statistical and format validation
- **dbt_utils**: Essential utility functions and generic tests
- **elementary**: Data quality monitoring and alerting

### Test Categories
1. **Source Tests**: Table structure and constraint validation
2. **Generic Tests**: Reusable validation logic (unique, not_null, etc.)
3. **Singular Tests**: Custom business rule validation
4. **Advanced Tests**: Statistical validation using dbt-expectations

## 🚀 Quick Start

### 1. Setup Virtual Environment
```bash
cd ../../  # Go to phase1 directory
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Configure dbt Profile
Ensure `~/.dbt/profiles.yml` contains the `telecom_validation` profile pointing to your BigQuery project.

### 3. Install Dependencies
```bash
dbt deps
```

### 4. Test Connection
```bash
dbt debug
```

### 5. Run Validation
```bash
# Parse and compile
dbt parse

# Run staging models
dbt run

# Execute all tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

## 📊 Data Quality Variables

Configure validation thresholds in `dbt_project.yml`:

```yaml
vars:
  min_customer_age: 16
  max_customer_age: 120
  max_daily_data_gb: 100
  max_monthly_bill: 500
  valid_customer_statuses: ['Active', 'Inactive', 'Churned']
  valid_plan_types: ['prepaid', 'postpaid']
```

## 🎛️ Key Commands

### Development Workflow
```bash
# Run specific model with tests
dbt run --select +model_name+
dbt test --select model_name

# Run only source tests
dbt test --select source:*

# Store test failures for analysis
dbt test --store-failures
```

### Quality Monitoring
```bash
# Run Elementary data quality monitoring
dbt run --select elementary

# Generate Elementary report
dbt run-operation elementary.generate_elementary_cli_output
```

## 🔧 Configuration Notes

### Target Schemas
- **Development**: `telecom_dev`
- **Testing**: `telecom_test`
- **Validation Results**: `{target_schema}_validation_results`
- **Elementary Monitoring**: `telecom_data_qa_monitor`

### Performance Settings
- **Test Sample Size**: 10,000 rows for performance
- **Severity**: `error` (strict validation in Phase 1)
- **Store Failures**: `true` (for detailed analysis)

## 📈 Success Criteria

Phase 1 completion requires:
- [ ] All source structure tests passing
- [ ] Business rule validation complete
- [ ] Data quality baseline established
- [ ] Documentation generated and reviewed
- [ ] Performance benchmarks documented
- [ ] Test failure analysis complete

Once Phase 1 criteria are met, the project can advance to **Phase 2: Advanced Analytics**.

## 🆘 Troubleshooting

### Common Issues
1. **Connection Errors**: Verify BigQuery permissions and service account key
2. **Package Errors**: Run `dbt clean && dbt deps`
3. **Test Failures**: Check `dbt_test_failures` table in BigQuery
4. **Performance**: Adjust `test_sample_size` variable

### Debug Commands
```bash
dbt debug --verbose
dbt compile --select model_name
dbt show --select model_name
```

---

**Phase 1 Focus**: Establish robust data validation foundation for enterprise telecom analytics.