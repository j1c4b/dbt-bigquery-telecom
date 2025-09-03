# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a comprehensive **Telecom dbt Analytics Platform** demonstrating enterprise-level data transformation practices. The project is structured in phases:

- **Phase 1**: Data validation and structure testing (focus on data quality)  
- **Phase 2**: Advanced analytics, churn modeling, and revenue analysis

## Development Setup

### Virtual Environment & Dependencies
```bash
# Always activate virtual environment first
cd phase1
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Install dbt packages
cd telecom_validation/telecom_validation
dbt deps
```

### dbt Configuration
- **Profile**: `telecom_validation` (configured in `~/.dbt/profiles.yml`)
- **Target**: `dev` (development), `test` (testing)
- **BigQuery Project**: `mytrial-billinglearningaccount`
- **Datasets**: `telecom_dev`, `telecom_test`, `telecom_prod`, `telecom_raw_data`, `telecom_data_qa_monitor`

## Common Commands

### Development Workflow
```bash
# Test connection
dbt debug

# Install packages  
dbt deps

# Run models
dbt run

# Run tests
dbt test

# Generate and serve documentation
dbt docs generate
dbt docs serve

# Combined workflow
dbt deps && dbt run && dbt test
```

### Testing & Quality Assurance
```bash
# Run specific model with tests
dbt run --select +model_name+
dbt test --select model_name

# Run source tests (structure validation)
dbt test --select source:*

# Run tests with failure storage
dbt test --store-failures

# Run models modified in current branch
dbt run --select state:modified
```

## Project Architecture

### Directory Structure
```
phase1/
├── venv/                           # Python virtual environment
├── telecom_validation/
│   └── telecom_validation/         # dbt project root
│       ├── models/
│       │   └── staging/           # Data validation models
│       ├── tests/
│       │   ├── generic/           # Reusable test macros
│       │   └── singular/          # Specific validation tests
│       ├── dbt_project.yml        # Project configuration
│       ├── packages.yml           # Package dependencies
│       └── package-lock.yml       # Locked package versions
├── keys/
│   ├── README.md                  # Setup instructions
│   └── *.json                     # Service account keys (not in Git)
├── requirements.txt               # Python dependencies
├── setup_service_account.sh       # Automated setup script
└── .env                           # Environment variables (not in Git)
```

### Data Layers (Phase 1)
1. **Raw Sources**: External telecom data tables
2. **Staging Models**: Cleaned and standardized data with comprehensive testing
3. **Validation Tests**: Custom generic and singular tests for data quality

### Key Configuration Files

**dbt_project.yml**: Core project settings including:
- Model materialization strategies
- Test configurations (`+severity: 'error'`, `+store_failures: true`)
- Phase-specific variables and thresholds
- Business rule parameters

**packages.yml**: Testing dependencies:
- `dbt_expectations`: Advanced data validation tests
- `dbt_utils`: Utility functions and macros  
- `elementary`: Data quality monitoring

## Testing Strategy

### Test Types
1. **Source Tests**: Validate table structure and constraints
2. **Generic Tests**: Reusable validation logic (uniqueness, relationships, etc.)
3. **Singular Tests**: Custom business rule validation
4. **dbt-expectations Tests**: Advanced statistical and format validation

### Test Configuration Variables
```yaml
vars:
  min_customer_age: 16
  max_customer_age: 120
  max_daily_data_gb: 100
  max_monthly_bill: 500
  valid_customer_statuses: ['Active', 'Inactive', 'Churned']
  valid_plan_types: ['prepaid', 'postpaid']

# Dataset configurations
models:
  elementary:
    +schema: telecom_data_qa_monitor  # Data quality monitoring
```

## BigQuery Setup Requirements

### Permissions Needed
- `bigquery.jobs.create`
- `bigquery.datasets.create` 
- `bigquery.tables.create`
- `bigquery.tables.getData`

### Service Account
- **Dedicated service account**: `telecom-dbt-analytics@mytrial-billinglearningaccount.iam.gserviceaccount.com`
- **Key file location**: `/Users/jacobg/projects/dbt-bigquery-telecom/phase1/keys/telecom-dbt-service-account.json`
- **Setup script**: `phase1/setup_service_account.sh` (automated creation and configuration)

## Development Guidelines

### Phase 1 Focus Areas
1. **Data Structure Validation**: Ensure all required columns and data types exist
2. **Business Rule Testing**: Validate telecom domain logic (age ranges, plan types, etc.)
3. **Referential Integrity**: Test foreign key relationships between entities
4. **Data Quality Baseline**: Establish quality metrics for advancement to Phase 2

### Model Development
- **Materialization**: Views for development, tables for production
- **Naming**: Use clear, descriptive names following `stg_`, `int_`, `fct_`, `dim_` prefixes
- **Documentation**: Add descriptions for all models and columns
- **Testing**: Every model must have appropriate tests

### Performance Considerations
- **Partitioning**: Use date-based partitioning for time-series data
- **Clustering**: Implement customer/plan-based clustering
- **Incremental Models**: Use for large datasets (Phase 2)
- **Billing Limits**: 1GB safety limit configured (`maximum_bytes_billed: 1000000000`)

## Environment Variables

Reference `.env` file for:
- BigQuery project and dataset configuration
- Authentication settings
- Performance and safety limits
- Phase-specific parameters

## Troubleshooting

### Common Issues
1. **Connection Errors**: Check BigQuery permissions and service account key
2. **Test Failures**: Review `dbt_test_failures` table in BigQuery
3. **Package Installation**: Update `packages.yml` with latest compatible versions
4. **Performance**: Adjust thread count and timeout values in profiles.yml

### Debug Commands
```bash
# Detailed connection testing
dbt debug --verbose

# Compile models without running
dbt compile --select model_name

# Check SQL compilation
dbt show --select model_name

# View test results
dbt test --store-failures
```

## Phase Progression

### Phase 1 Completion Criteria
- ✅ All source structure tests passing
- ✅ Business rule validation complete
- ✅ Data quality baseline established
- ✅ Documentation generated
- ✅ Performance benchmarks documented

### Phase 2 Preview
- Advanced customer segmentation models
- Churn risk modeling and predictions  
- Revenue analytics and forecasting
- Incremental model optimization
- ML feature engineering for predictive analytics

## File Locations

- **Virtual Environment**: `/Users/jacobg/projects/dbt-bigquery-telecom/phase1/venv/`
- **dbt Project**: `/Users/jacobg/projects/dbt-bigquery-telecom/phase1/telecom_validation/telecom_validation/`
- **Service Account Key**: `/Users/jacobg/projects/dbt-bigquery-telecom/phase1/keys/telecom-dbt-service-account.json`
- **Environment Config**: `/Users/jacobg/projects/dbt-bigquery-telecom/phase1/.env` (not in Git)