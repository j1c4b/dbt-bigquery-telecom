# Service Account Keys

This directory contains Google Cloud Service Account keys for the telecom dbt analytics project.

## Security Note
- Service account keys are **NOT** committed to version control
- The actual key file `telecom-dbt-service-account.json` is ignored by .gitignore
- Never commit secrets or service account keys to Git repositories

## Setup Instructions

1. **Create Service Account** (if not already done):
   ```bash
   cd /Users/jacobg/projects/dbt-bigquery-telecom/phase1
   ./setup_service_account.sh
   ```

2. **Manual Setup**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Navigate to IAM & Admin > Service Accounts
   - Create service account: `telecom-dbt-analytics`
   - Grant roles: `BigQuery Data Editor`, `BigQuery Job User`, `BigQuery User`
   - Generate JSON key and save as `telecom-dbt-service-account.json`

3. **File Location**:
   ```
   /Users/jacobg/projects/dbt-bigquery-telecom/phase1/keys/telecom-dbt-service-account.json
   ```

4. **Verify Setup**:
   ```bash
   cd phase1/telecom_validation/telecom_validation
   source ../../venv/bin/activate
   dbt debug
   ```

## Expected File Structure
```
keys/
├── README.md                           # This file
└── telecom-dbt-service-account.json   # Service account key (not in Git)
```