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
6. **🚀 Advanced Statistical Tests**: dbt-expectations powered analytics
7. **🔴 Intentional Failure Tests**: Validate test framework functionality

### 🚀 Advanced Statistical Validation

Our platform includes **sophisticated data quality analysis** using dbt-expectations:

#### **Statistical Analysis Tests:**
- **Mean/Average Validation**: `expect_column_mean_to_be_between`
- **Quantile Analysis**: `expect_column_quantile_values_to_be_between` 
- **Standard Deviation**: `expect_column_stdev_to_be_between`
- **Distribution Analysis**: `expect_column_distinct_count_to_be_between`

#### **Telecom-Specific Business Rules:**
- **Customer ID Format**: `CUST_[A-Z0-9]{3,10}` pattern validation
- **Email Format**: RFC-compliant email regex validation
- **Pricing Bounds**: Monthly fees $5-$500 business rule enforcement
- **Quality Scores**: 1-5 scale validation with statistical distribution analysis
- **Financial Integrity**: Revenue protection with anomaly detection

#### **Advanced Test Examples:**
```yaml
# Pricing anomaly detection
- dbt_expectations.expect_column_mean_to_be_between:
    min_value: 20.00
    max_value: 150.00
    tags: ['statistical_validation', 'pricing_anomaly']

# Quality distribution monitoring
- dbt_expectations.expect_column_stdev_to_be_between:
    min_value: 0.1
    max_value: 2.0
    tags: ['service_monitoring', 'quality_variance']

# Revenue integrity protection
- dbt_expectations.expect_column_quantile_values_to_be_between:
    quantile: 0.95
    min_value: 50
    max_value: 500
    tags: ['anomaly_detection', 'revenue_protection']
```

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
# Expected: ✅ 5 PASS, 🔴 2 FAIL (proves framework works!)

# Test advanced statistical validation
dbt test --select "tag:advanced"
# Expected: ✅ ~14 PASS, ⚠️ 1 WARN (shows anomaly detection works!)

# Test all validation levels
dbt test
# Expected: ✅ ~50+ PASS, ⚠️ 1 WARN, 🔴 2 FAIL (comprehensive validation!)
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
# ✅ PASS: ~50+ tests (data quality, relationships, partitions, statistical)
# ⚠️ WARN: 1 test (pricing anomaly detection - shows system working!)
# 🔴 FAIL: 2 tests (intentional failures in billing_test_fail)
# 
# Test Breakdown by Category:
# - Basic validation: ~30 tests (uniqueness, null checks, relationships)
# - Advanced statistical: ~14 tests (mean, quantile, pattern analysis)
# - Partition validation: 5 tests (table structure validation)
# - Intentional failures: 2 tests (framework validation)
# 
# If you see different results, check:
# - Did you run the data insertion step?
# - Are partition tests included in the run?
# - Is dbt-expectations package installed?
```

## 📊 **Complete Test Coverage Overview**

### **Production-Ready Validation (56+ Tests)**

| **Test Category** | **Count** | **Purpose** | **Examples** |
|---|---|---|---|
| **Basic Validation** | ~30 | Data integrity | Uniqueness, null checks, relationships |
| **Advanced Statistical** | ~14 | Anomaly detection | Mean analysis, quantile validation |
| **Partition Structure** | 5 | Table optimization | Partition metadata validation |
| **Business Rules** | ~7 | Telecom compliance | Pricing bounds, format validation |
| **Intentional Failures** | 2 | Framework proof | NULL detection, type validation |

### **Tag-Based Test Execution**
```bash
# Execute specific test categories
dbt test --select "tag:advanced"              # Advanced statistical tests
dbt test --select "tag:business_rule"         # Telecom business rules  
dbt test --select "tag:statistical_validation" # Anomaly detection
dbt test --select "tag:revenue_protection"    # Financial integrity
dbt test --select "tag:intentional_failure"   # Framework validation
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
dbt test                         # Run all tests including advanced statistical validation
                                # Expected: ~50+ PASS, 1 WARN, 2 FAIL (intentional)

# Advanced testing workflows
dbt test --select "tag:advanced"              # Test advanced statistical validation
dbt test --select "tag:business_rule"         # Test telecom business rules
dbt test --select "tag:statistical_validation" # Test anomaly detection
dbt test --select source:raw_telecom.billing_test_fail  # Verify framework works
```

## 📊 **Elementary Data Quality Dashboard**

### **✅ Free Interactive Dashboard**
Your project includes a **professional data quality dashboard** powered by Elementary (open source):

```bash
# Generate beautiful HTML dashboard (FREE)
cd phase1/telecom_validation
source ../venv/bin/activate
edr monitor report --open-browser true --file-path elementary_dashboard.html
```

### **🎯 Dashboard Features**
- **📈 Test Results Visualization**: All 56+ tests displayed with charts and trends
- **🔍 Statistical Analysis**: Advanced dbt-expectations results with anomaly detection
- **📊 Test Coverage Matrix**: Comprehensive validation coverage across all tables
- **⚡ Real-time Status**: Live data quality health scores and alerts
- **🔗 Data Lineage**: Interactive source-to-model dependency visualization
- **📋 Executive Summary**: Single-pane data health overview for stakeholders

### **🚀 Perfect for Presentations**
The dashboard showcases:
- **Enterprise-grade reliability**: 52 PASS tests demonstrate robust validation
- **Advanced analytics capabilities**: Statistical anomaly detection and business rules
- **Professional reporting**: Interactive HTML dashboard with modern UI
- **Comprehensive coverage**: Data quality monitoring across entire telecom pipeline

### **📍 Dashboard Location**
- **File**: `phase1/telecom_validation/elementary_dashboard.html`
- **Size**: ~4MB (rich interactive content)
- **Opens in**: Any modern web browser
- **Updates**: Regenerate after running `dbt test` for latest results

## 🧠 **Advanced Analytics Models**

### **🚀 Production-Ready ML-Inspired Analytics**
Your platform now includes **three sophisticated analytics models** that demonstrate enterprise-grade business intelligence:

#### **1. Customer Churn Risk Scoring Model** ⭐⭐⭐
```sql
-- Advanced ML-inspired churn prediction
models/analytics/customer_churn_risk.sql
```
- **Risk Scoring**: 0-10 scale with behavioral pattern analysis
- **Risk Categories**: STABLE → LOW_RISK → MEDIUM_RISK → HIGH_RISK
- **Key Features**:
  - Usage behavior volatility analysis
  - Billing pattern irregularities detection  
  - Service quality correlation scoring
  - Plan instability risk indicators
  - Immediate intervention flags for at-risk customers
- **Business Impact**: Proactive customer retention strategy

#### **2. Revenue Trend Analysis Model** ⭐⭐⭐
```sql
-- Comprehensive business intelligence with forecasting
models/analytics/revenue_trend_analysis.sql
```
- **Growth Analytics**: Month-over-month and year-over-year tracking
- **Customer Segmentation**: Premium/Standard/Basic revenue analysis
- **Key Metrics**:
  - ARPU (Average Revenue Per User) trends
  - Customer mix profiling (Premium Heavy → Value Focused)
  - Revenue forecasting with trend analysis
  - Growth categorization (Strong Growth → Declining)
- **Business Impact**: Strategic revenue planning and optimization

#### **3. Network Quality Correlation Model** ⭐⭐⭐
```sql
-- Quality-business impact correlation analysis  
models/analytics/network_quality_correlation.sql
```
- **Quality-Revenue Correlation**: Service performance vs. business outcomes
- **Customer Satisfaction Indicators**: AT_RISK → MONITOR → SATISFIED
- **Key Features**:
  - Quality-usage behavior segmentation
  - Service improvement prioritization (Critical → Low Priority)
  - Business impact categorization
  - Revenue-quality relationship analysis
- **Business Impact**: Service quality optimization ROI

### **📊 Analytics Model Testing**
```bash
# Run analytics models
dbt run --select models/analytics/

# Test advanced analytics (32 additional tests)
dbt test --select models/analytics/
# Expected: 31 PASS, 1 WARN (anomaly detection working!)

# View results
dbt docs generate && dbt docs serve
```

### **🎯 Analytics Dashboard Integration**
All analytics models are automatically included in your Elementary dashboard:
- **Churn risk trends** with customer segmentation charts
- **Revenue forecasting** with growth trajectory visualization  
- **Quality correlation** with business impact matrices
- **Predictive insights** for executive decision-making

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
- ✅ **Comprehensive data validation framework** (50+ tests)
- ✅ **Advanced statistical validation** (dbt-expectations powered)
- ✅ **Telecom-specific business rules** (industry expertise)
- ✅ **Test framework validation** (intentional failure testing)
- ✅ **Anomaly detection** (pricing, quality, usage patterns)
- ✅ **Revenue protection** (financial integrity monitoring)
- ✅ Partition validation with data dependency handling
- ✅ **Real-time data quality dashboard** (Elementary HTML report)
- ✅ **Interactive test visualization** (comprehensive reporting)
- ✅ **🧠 Advanced Analytics Models** (ML-inspired customer intelligence)
- ✅ **🎯 Customer Churn Prediction** (0-10 risk scoring with intervention flags)
- ✅ **📈 Revenue Trend Forecasting** (growth analytics with customer segmentation)
- ✅ **🔗 Network Quality Correlation** (service-revenue impact analysis)
- ✅ Documentation generation
- ✅ Virtual environment isolation

### Planned Phase 2 Features
- 🔮 Customer lifetime value modeling (CLV)
- 🔮 Real-time streaming analytics
- 🔮 Advanced ML feature stores
- 🔮 Automated alerting and notifications
- 🔮 Multi-tenant analytics deployment
- 🔮 Advanced dashboard customization

## 🚦 Getting Started Checklist

- [ ] Clone repository
- [ ] Set up Python virtual environment
- [ ] Configure Google Cloud authentication
- [ ] Run service account setup script
- [ ] Test dbt connection (`dbt debug`)
- [ ] Install dbt packages (`dbt deps`)
- [ ] Create tables with sample data (`bq query < phase1/create_telecom_tables.sql`)
- [ ] Run comprehensive validation (`dbt test`) - Expect ~50+ PASS, 1 WARN, 2 FAIL (intentional)
- [ ] Test advanced statistical validation (`dbt test --select "tag:advanced"`)
- [ ] Verify test framework works (`dbt test --select source:raw_telecom.billing_test_fail`)
- [ ] **🧠 Run advanced analytics models** (`dbt run --select models/analytics/`)
- [ ] **🧠 Test analytics models** (`dbt test --select models/analytics/`) - Expect 31 PASS, 1 WARN
- [ ] **Generate interactive dashboard** (`edr monitor report --open-browser true`)
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