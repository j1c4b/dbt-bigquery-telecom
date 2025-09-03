#!/bin/bash

# Telecom dbt Analytics - Service Account Setup Script
# This script helps set up the BigQuery service account and datasets

set -e

echo "🔐 Telecom dbt Analytics - Service Account Setup"
echo "================================================="

# Variables
PROJECT_ID="mytrial-billinglearningaccount"
SERVICE_ACCOUNT_NAME="telecom-dbt-analytics"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="./keys/telecom-dbt-service-account.json"

echo "Project ID: $PROJECT_ID"
echo "Service Account: $SERVICE_ACCOUNT_EMAIL"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed. Please install it first:"
    echo "   https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ Please authenticate with gcloud first:"
    echo "   gcloud auth login"
    exit 1
fi

echo "✅ gcloud CLI found and authenticated"

# Set project
echo "🔧 Setting project context..."
gcloud config set project $PROJECT_ID

# Create service account
echo "👤 Creating service account..."
if gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL >/dev/null 2>&1; then
    echo "✅ Service account already exists: $SERVICE_ACCOUNT_EMAIL"
else
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --display-name="Telecom dbt Analytics" \
        --description="Service account for dbt telecom analytics project - data transformation and validation"
    echo "✅ Service account created: $SERVICE_ACCOUNT_EMAIL"
fi

# Grant required IAM roles
echo "🔑 Granting BigQuery permissions..."

roles=(
    "roles/bigquery.dataEditor"
    "roles/bigquery.jobUser"  
    "roles/bigquery.user"
)

for role in "${roles[@]}"; do
    echo "   Adding role: $role"
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="$role" \
        --quiet
done

echo "✅ IAM roles granted successfully"

# Create key file directory
mkdir -p keys

# Generate and download key file
echo "🔑 Generating service account key..."
if [ -f "$KEY_FILE" ]; then
    echo "⚠️  Key file already exists: $KEY_FILE"
    echo "   Delete it first if you want to generate a new one"
else
    gcloud iam service-accounts keys create $KEY_FILE \
        --iam-account=$SERVICE_ACCOUNT_EMAIL
    
    # Set secure permissions
    chmod 600 $KEY_FILE
    echo "✅ Key file created: $KEY_FILE"
fi

# Create BigQuery datasets
echo "📊 Creating BigQuery datasets..."
bq mk --location=US --description="Development dataset for telecom dbt analytics - Phase 1 validation" telecom_dev || echo "Dataset telecom_dev already exists"
bq mk --location=US --description="Test dataset for telecom dbt analytics - validation testing" telecom_test || echo "Dataset telecom_test already exists" 
bq mk --location=US --description="Production dataset for telecom dbt analytics - Phase 2 deployment" telecom_prod || echo "Dataset telecom_prod already exists"
bq mk --location=US --description="Raw telecom data sources for dbt transformation" telecom_raw_data || echo "Dataset telecom_raw_data already exists"
bq mk --location=US --description="Telecom data quality monitoring and Elementary tables" telecom_data_qa_monitor || echo "Dataset telecom_data_qa_monitor already exists"

echo "✅ BigQuery datasets created"

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Test connection: cd telecom_validation/telecom_validation && dbt debug"
echo "2. Install packages: dbt deps"  
echo "3. Start Phase 1 development"
echo ""
echo "Key file location: $KEY_FILE"
echo "Service account: $SERVICE_ACCOUNT_EMAIL"