{{
  config(
    materialized='view',
    description='PHASE 1: Usage records staging with basic validation and cleansing',
    tags=['phase1', 'staging', 'validation', 'high_volume']
  )
}}

-- PHASE 1 OBJECTIVES:
-- 1. Basic data type validation and cleaning
-- 2. Usage value normalization and range checks  
-- 3. Customer relationship validation preparation
-- 4. Performance optimized for high volume data

with source_data as (
    select * from {{ source('raw_telecom', 'usage_records') }}
),

usage_validation_cleaning as (
    select
        -- =============================================
        -- PRIMARY IDENTIFIERS
        -- =============================================
        usage_id,
        customer_id,
        
        -- =============================================
        -- DATE VALIDATION AND STANDARDIZATION
        -- =============================================
        cast(usage_date as date) as usage_date,
        
        -- Date validation flags
        case 
            when usage_date > current_date() then 1 
            else 0 
        end as future_date_flag,
        
        case 
            when usage_date < '2020-01-01' then 1 
            else 0 
        end as historical_date_flag,
        
        -- =============================================
        -- USAGE METRICS - Validation and normalization
        -- =============================================
        -- Voice usage
        coalesce(call_minutes, 0) as call_minutes,
        case 
            when call_minutes < 0 then 1
            when call_minutes > 1440 then 1  -- More than 24 hours
            else 0
        end as invalid_call_minutes_flag,
        
        -- SMS usage  
        coalesce(sms_count, 0) as sms_count,
        case 
            when sms_count < 0 then 1
            when sms_count > 10000 then 1  -- Extreme daily SMS count
            else 0
        end as invalid_sms_count_flag,
        
        -- Data usage (MB)
        coalesce(data_mb, 0) as data_mb,
        case 
            when data_mb < 0 then 1
            when data_mb > 102400 then 1  -- More than 100GB daily
            else 0
        end as invalid_data_mb_flag,
        
        -- =============================================
        -- DERIVED USAGE METRICS
        -- =============================================
        -- Convert to different units for analysis
        round(coalesce(data_mb, 0) / 1024, 2) as data_gb,
        
        -- Usage intensity indicators
        case 
            when coalesce(call_minutes, 0) = 0 
                and coalesce(sms_count, 0) = 0 
                and coalesce(data_mb, 0) = 0 then 'No Usage'
            when coalesce(call_minutes, 0) + coalesce(sms_count, 0) * 0.1 + coalesce(data_mb, 0) * 0.001 < 10 then 'Light'
            when coalesce(call_minutes, 0) + coalesce(sms_count, 0) * 0.1 + coalesce(data_mb, 0) * 0.001 < 100 then 'Medium'
            else 'Heavy'
        end as usage_intensity,
        
        -- Primary usage type
        case 
            when coalesce(data_mb, 0) > coalesce(call_minutes, 0) * 10 
                and coalesce(data_mb, 0) > coalesce(sms_count, 0) then 'Data Primary'
            when coalesce(call_minutes, 0) > coalesce(sms_count, 0) 
                and coalesce(call_minutes, 0) * 10 > coalesce(data_mb, 0) then 'Voice Primary'
            when coalesce(sms_count, 0) > 0 then 'SMS Primary'
            else 'Mixed'
        end as primary_usage_type,
        
        -- =============================================
        -- DATA QUALITY INDICATORS
        -- =============================================
        -- Completeness flags
        case when usage_id is null then 1 else 0 end as missing_usage_id_flag,
        case when customer_id is null then 1 else 0 end as missing_customer_id_flag,
        case when usage_date is null then 1 else 0 end as missing_usage_date_flag,
        
        -- Overall data quality score (0-1)
        case 
            when usage_id is null or customer_id is null or usage_date is null then 0
            when (case when call_minutes < 0 then 1 when call_minutes > 1440 then 1 else 0 end) = 1
                or (case when sms_count < 0 then 1 when sms_count > 10000 then 1 else 0 end) = 1  
                or (case when data_mb < 0 then 1 when data_mb > 102400 then 1 else 0 end) = 1 then 0.5
            else 1
        end as data_quality_score,
        
        -- =============================================
        -- AUDIT AND METADATA
        -- =============================================
        current_timestamp() as dbt_loaded_at,
        '{{ invocation_id }}' as dbt_run_id,
        'phase1_validation' as processing_phase

    from source_data
    
    -- =============================================
    -- BASIC QUALITY FILTERS
    -- =============================================
    where usage_id is not null
      and customer_id is not null
      and usage_date is not null
)

select * from usage_validation_cleaning

/*
PHASE 1 USAGE VALIDATION NOTES:
===============================

High Volume Considerations:
- Uses view materialization for flexibility
- Includes data quality scoring for monitoring
- Optimized WHERE clause for performance
- Derived metrics support validation testing

Validation Focus:
- Range checking for all usage metrics
- Date logic validation
- Data quality indicator creation
- Usage pattern classification

Phase 2 Enhancements (not included):
- Advanced usage pattern analysis
- Anomaly detection algorithms  
- Customer behavior segmentation
- Predictive usage modeling
*/