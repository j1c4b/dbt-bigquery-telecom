# Telecom dbt Analytics Platform

Comprehensive telecom data transformation project with BigQuery integration, focused on data validation, quality testing, and advanced analytics.

## 🏗️ Project Structure

This project follows a **phased development approach** for scalable telecom analytics:

### Phase 1: Data Validation & Structure Testing ✅
- **Focus**: Data quality assurance and structural validation
- **Location**: `phase1/telecom_validation/`
- **Status**: Ready for development

### Phase 2: Advanced Analytics (Planned)
- **Focus**: Customer segmentation, churn modeling, revenue analytics
- **Features**: ML feature engineering, predictive analytics, dashboards
- **Status**: Planned after Phase 1 completion

## 🚀 Quick Start

### Prerequisites
- Python 3.13+
- Google Cloud Platform account with BigQuery enabled
- Git and GitHub account

### 1. Clone Repository
```bash
git clone https://github.com/j1c4b/dbt-bigquery-telecom.git
cd dbt-bigquery-telecom
```

### 2. Set Up Phase 1
```bash
cd phase1
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Configure BigQuery
```bash
# Run the automated setup script
./setup_service_account.sh

# Or manual setup - see phase1/keys/README.md
```

### 4. Initialize dbt Project
```bash
cd telecom_validation
dbt debug  # Test connection
dbt deps   # Install packages

# Create tables with sample data first
bq query < ../create_telecom_tables.sql

# Run transformations and tests
dbt run    # Run models
dbt test   # Run data quality tests (including partition validation)
```

## 📊 BigQuery Datasets

All datasets use consistent `telecom_` naming:

- **`telecom_dev`**: Development environment
- **`telecom_test`**: Testing environment  
- **`telecom_prod`**: Production environment
- **`telecom_raw_data`**: Raw source data
- **`telecom_data_qa_monitor`**: Data quality monitoring

## 🧪 Testing Framework

Phase 1 implements comprehensive data validation:

- **dbt-expectations**: Advanced statistical tests
- **dbt_utils**: Utility functions and generic tests
- **Elementary**: Data quality monitoring and alerting
- **Custom tests**: Telecom-specific business rule validation

### Test Categories
1. **Structure Tests**: Schema and data type validation
2. **Business Rule Tests**: Telecom domain logic validation
3. **Quality Tests**: Completeness, accuracy, consistency
4. **Relationship Tests**: Foreign key and referential integrity
5. **Partition Tests**: Table partitioning validation (requires sample data)
6. **🔴 Intentional Failure Tests**: Validate test framework functionality

## 🧪 Test Framework Validation

### Intentional Test Failures (billing_test_fail table)
We've included a **test table with purposeful schema issues** to prove our dbt validation framework works correctly:

**Table**: `dbt-bigquery-telecom.telecom_raw_data.billing_test_fail`

**🔴 Expected Failures:**
- **`total_amount` NULL constraint**: Contains NULL values → **not_null test FAILS** ✅
- **`billing_month` data type**: STRING instead of DATE → **type validation FAILS** ✅

**✅ Expected Passes:**
- Primary key uniqueness, foreign key relationships, other constraints

### Testing the Test Framework
```bash
# Test only the intentional failure table
dbt test --select source:raw_telecom.billing_test_fail

# Expected output:
# ✅ PASS: 5 tests (uniqueness, relationships, etc.)  
# 🔴 FAIL: 2 tests (NULL constraint, data type validation)
# This proves your dbt test framework is working correctly!
```

## 📋 Partition Testing Instructions

### ⚠️ Critical: Partition Tests Require Data
The partition validation tests (`test_table_is_partitioned`) **only work on tables with data**. BigQuery doesn't create partition metadata entries for empty partitioned tables.

### Step-by-Step Testing Process

#### 1️⃣ **First: Create Tables with Sample Data**
```bash
# This creates all tables AND inserts sample data
bq query < phase1/create_telecom_tables.sql
```

#### 2️⃣ **Test Execution Options**

**Option A: Run All Tests (After Data Insertion)**
```bash
# Run everything - works after step 1
dbt test
# Expected: All tests pass except 2 intentional failures in billing_test_fail
```

**Option B: Staged Testing (More Control)**
```bash
# Run non-partition tests first (works on empty tables)
dbt test --exclude "test_name:table_is_partitioned"

# Then run partition validation (requires data)
dbt test --select "test_name:table_is_partitioned"

# Test the failure validation separately
dbt test --select source:raw_telecom.billing_test_fail
```

#### 3️⃣ **Understanding Test Results**
```bash
# Expected results after running all tests:
# ✅ PASS: ~38 tests (data quality, relationships, partitions)
# 🔴 FAIL: 2 tests (intentional failures in billing_test_fail)
# 
# If you see different results, check:
# - Did you run the data insertion step?
# - Are partition tests included in the run?
```

## 🔧 Development Workflow

```bash
# Activate environment
source venv/bin/activate

# Initial setup and data loading
bq query < phase1/create_telecom_tables.sql  # Create tables with sample data

# Development cycle
dbt run --select +model_name+    # Run model with dependencies
dbt test --select model_name     # Test specific model
dbt docs generate && dbt docs serve  # Generate documentation

# Quality assurance
dbt test --store-failures        # Store test failures for analysis
dbt run --target test           # Run against test environment

# Comprehensive validation (after data insertion)
dbt test                         # Run all tests including partition validation
                                # Expected: ~38 PASS, 2 FAIL (intentional)

# Test framework validation
dbt test --select source:raw_telecom.billing_test_fail  # Verify test framework works
```

## 🔐 Security

- **Service account keys**: Never committed to Git
- **Environment files**: Excluded from version control  
- **Automated setup**: Secure credential management
- **BigQuery permissions**: Principle of least privilege

## 📚 Documentation

- **[CLAUDE.md](CLAUDE.md)**: Development guidance for Claude Code
- **phase1/docs/**: Comprehensive templates and examples
- **phase1/keys/README.md**: Service account setup instructions

## 🛠️ Technology Stack

- **dbt 1.10+**: Data transformation framework
- **BigQuery**: Cloud data warehouse
- **Python 3.13**: Virtual environment and dependencies
- **Elementary**: Data quality monitoring
- **Google Cloud SDK**: Authentication and deployment

## 🎯 Key Features

### Phase 1 Capabilities
- ✅ Automated BigQuery dataset creation
- ✅ Service account security setup
- ✅ Comprehensive data validation framework
- ✅ **Test framework validation** (intentional failure testing)
- ✅ Partition validation with data dependency handling
- ✅ Quality monitoring and alerting
- ✅ Documentation generation
- ✅ Virtual environment isolation

### Planned Phase 2 Features
- 🔮 Customer lifetime value modeling
- 🔮 Churn risk prediction
- 🔮 Network usage analytics
- 🔮 Revenue forecasting
- 🔮 Real-time dashboards
- 🔮 ML feature stores

## 🚦 Getting Started Checklist

- [ ] Clone repository
- [ ] Set up Python virtual environment
- [ ] Configure Google Cloud authentication
- [ ] Run service account setup script
- [ ] Test dbt connection (`dbt debug`)
- [ ] Install dbt packages (`dbt deps`)
- [ ] Create tables with sample data (`bq query < phase1/create_telecom_tables.sql`)
- [ ] Run initial data validation (`dbt test`) - Expect ~38 PASS, 2 FAIL (intentional)
- [ ] Verify test framework works (`dbt test --select source:raw_telecom.billing_test_fail`)
- [ ] Generate documentation (`dbt docs generate`)

## 📈 Next Steps

1. **Complete Phase 1**: Focus on data validation and testing
2. **Data Source Integration**: Connect your telecom data sources
3. **Custom Test Development**: Add business-specific validation rules
4. **Quality Monitoring**: Set up Elementary alerts and monitoring
5. **Phase 2 Planning**: Advanced analytics and ML features

---

## 🤝 Contributing

This project demonstrates enterprise-level dbt practices for telecom analytics. See [CLAUDE.md](CLAUDE.md) for detailed development guidance.

## 📄 License

Private repository for telecom analytics development.

---

**Built with ❤️ using dbt, BigQuery, and modern data engineering practices**