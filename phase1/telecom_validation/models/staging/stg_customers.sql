{{
  config(
    materialized='view',
    description='PHASE 1: Customer staging model focused on validation and clean structure',
    tags=['phase1', 'staging', 'validation']
  )
}}

-- PHASE 1 OBJECTIVES:
-- 1. Basic data cleaning for validation testing
-- 2. Standardize formats for consistent testing  
-- 3. Create derived fields needed for business rule validation
-- 4. Establish baseline for Phase 2 advanced analytics

with source_data as (
    select * from {{ source('raw_telecom', 'customers') }}
),

basic_validation_cleaning as (
    select
        -- =============================================
        -- PRIMARY IDENTIFIERS (tested in source)
        -- =============================================
        customer_id,
        
        -- =============================================
        -- CONTACT INFORMATION - Format standardization
        -- =============================================
        -- Email: lowercase, trimmed for consistent validation
        trim(lower(email)) as email,
        
        -- Phone: clean format for validation testing
        regexp_replace(phone_number, '[^0-9+]', '') as phone_number_clean,
        phone_number as phone_number_raw,  -- Keep original for audit
        
        -- =============================================
        -- DATE FIELDS - Type casting for validation
        -- =============================================
        cast(registration_date as date) as registration_date,
        cast(date_of_birth as date) as date_of_birth,
        
        -- =============================================
        -- GEOGRAPHIC DATA - Standardization
        -- =============================================
        upper(trim(address_state)) as state,
        trim(initcap(address_city)) as city,
        
        -- =============================================
        -- STATUS STANDARDIZATION - Business rule compliance
        -- =============================================
        case 
            when upper(trim(customer_status)) in ('ACTIVE', 'A', '1', 'TRUE') then 'Active'
            when upper(trim(customer_status)) in ('INACTIVE', 'I', '0', 'FALSE') then 'Inactive'
            when upper(trim(customer_status)) in ('CHURNED', 'C', 'CANCELLED', 'TERMINATED') then 'Churned'
            else 'Unknown'
        end as customer_status,
        
        -- =============================================
        -- DERIVED FIELDS - Business rule validation
        -- =============================================
        -- Age calculation for business rule testing
        date_diff(current_date(), cast(date_of_birth as date), year) as customer_age,
        
        -- Tenure calculation  
        date_diff(current_date(), cast(registration_date as date), day) as tenure_days,
        
        -- Customer lifecycle segment (basic for Phase 1)
        case 
            when date_diff(current_date(), cast(registration_date as date), day) < 90 then 'New'
            when date_diff(current_date(), cast(registration_date as date), day) < 365 then 'Established' 
            else 'Veteran'
        end as customer_segment_basic,
        
        -- =============================================
        -- DATA QUALITY INDICATORS - Validation flags
        -- =============================================
        -- Missing data flags for quality assessment
        case when email is null or trim(email) = '' then 1 else 0 end as missing_email_flag,
        case when phone_number is null or trim(phone_number) = '' then 1 else 0 end as missing_phone_flag,
        case when date_of_birth is null then 1 else 0 end as missing_dob_flag,
        case when address_state is null or trim(address_state) = '' then 1 else 0 end as missing_state_flag,
        
        -- Format validation indicators
        case 
            when email is null then null
            when regexp_contains(email, r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') then 1
            else 0 
        end as valid_email_format_flag,
        
        case
            when phone_number is null then null
            when length(regexp_replace(phone_number, '[^0-9]', '')) between 10 and 15 then 1
            else 0
        end as valid_phone_format_flag,
        
        -- Age validation flag
        case
            when date_of_birth is null then null
            when date_diff(current_date(), cast(date_of_birth as date), year) between 16 and 100 then 1
            else 0
        end as valid_age_flag,
        
        -- =============================================
        -- AUDIT AND METADATA - Phase 1 tracking
        -- =============================================
        updated_at,
        current_timestamp() as dbt_loaded_at,
        '{{ invocation_id }}' as dbt_run_id,
        
        -- Phase 1 validation metadata
        'phase1_validation' as processing_phase,
        current_date() as validation_date

    from source_data
    
    -- =============================================
    -- BASIC QUALITY FILTERS - Phase 1 focus
    -- =============================================
    where customer_id is not null
      and registration_date is not null
      and registration_date <= current_date()
      -- Additional filters can be added based on validation results
)

select * from basic_validation_cleaning

/*
PHASE 1 VALIDATION NOTES:
========================

This model focuses on:
1. Basic cleaning needed for test validation
2. Format standardization for consistent testing
3. Business rule compliance checking
4. Data quality indicator creation

NOT included in Phase 1 (saved for Phase 2):
- Complex customer segmentation
- Churn risk indicators  
- Advanced analytics features
- Performance optimization
- Machine learning feature engineering

The goal is to establish a clean, validated foundation
that Phase 2 can build advanced analytics upon.
*/