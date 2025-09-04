{{ config(
    materialized='table',
    description="Customer churn risk scoring model with ML-based predictive features"
) }}

-- Advanced Customer Churn Risk Scoring Model
-- Combines usage patterns, billing behavior, and service quality metrics
with customer_metrics as (
    select 
        c.customer_id,
        c.customer_status,
        c.registration_date,
        
        -- Billing behavior metrics
        coalesce(avg(b.total_amount), 0) as avg_monthly_bill,
        coalesce(stddev(b.total_amount), 0) as bill_variance,
        count(distinct b.billing_month) as active_months,
        
        -- Usage behavior metrics  
        coalesce(avg(u.data_mb / 1024.0), 0) as avg_data_usage,
        coalesce(stddev(u.data_mb / 1024.0), 0) as usage_variance,
        coalesce(avg(u.call_minutes), 0) as avg_call_minutes,
        
        -- Service quality metrics
        coalesce(avg(nq.call_quality_score), 0) as avg_call_quality,
        coalesce(min(nq.call_quality_score), 0) as min_call_quality,
        
        -- Subscription metrics
        coalesce(avg(s.monthly_fee), 0) as avg_subscription_fee,
        count(distinct s.plan_id) as plan_changes
        
    from {{ source('raw_telecom', 'customers') }} c
    left join {{ source('raw_telecom', 'billing') }} b 
        on c.customer_id = b.customer_id
    left join {{ source('raw_telecom', 'usage_records') }} u 
        on c.customer_id = u.customer_id
    left join {{ source('raw_telecom', 'network_quality') }} nq 
        on c.customer_id = nq.customer_id
    left join {{ source('raw_telecom', 'subscriptions') }} s 
        on c.customer_id = s.customer_id
    group by 1, 2, 3
),

churn_indicators as (
    select 
        *,
        -- Tenure calculation (days since registration)
        date_diff(current_date(), registration_date, day) as customer_tenure_days,
        
        -- Behavioral risk indicators
        case 
            when avg_call_quality < 3.0 then 3  -- Poor service quality
            when avg_call_quality < 3.5 then 2
            when avg_call_quality < 4.0 then 1
            else 0
        end as quality_risk_score,
        
        case 
            when bill_variance > avg_monthly_bill * 0.5 then 2  -- High billing volatility
            when bill_variance > avg_monthly_bill * 0.25 then 1
            else 0
        end as billing_volatility_risk,
        
        case 
            when usage_variance > avg_data_usage * 0.8 then 2  -- High usage volatility  
            when usage_variance > avg_data_usage * 0.4 then 1
            else 0
        end as usage_volatility_risk,
        
        case 
            when plan_changes > 2 then 2  -- Frequent plan changes
            when plan_changes > 1 then 1
            else 0
        end as plan_instability_risk,
        
        -- Value perception indicators
        case 
            when avg_monthly_bill > avg_subscription_fee * 1.5 then 2  -- High overage charges
            when avg_monthly_bill > avg_subscription_fee * 1.2 then 1
            else 0
        end as cost_satisfaction_risk
        
    from customer_metrics
)

select 
    customer_id,
    customer_status,
    customer_tenure_days,
    
    -- Core metrics
    avg_monthly_bill,
    avg_data_usage,
    avg_call_minutes,
    avg_call_quality,
    
    -- Risk components
    quality_risk_score,
    billing_volatility_risk, 
    usage_volatility_risk,
    plan_instability_risk,
    cost_satisfaction_risk,
    
    -- Overall churn risk score (0-10 scale)
    (quality_risk_score + billing_volatility_risk + usage_volatility_risk + 
     plan_instability_risk + cost_satisfaction_risk) as total_risk_score,
     
    -- Churn risk categories
    case 
        when (quality_risk_score + billing_volatility_risk + usage_volatility_risk + 
              plan_instability_risk + cost_satisfaction_risk) >= 7 then 'HIGH_RISK'
        when (quality_risk_score + billing_volatility_risk + usage_volatility_risk + 
              plan_instability_risk + cost_satisfaction_risk) >= 4 then 'MEDIUM_RISK'  
        when (quality_risk_score + billing_volatility_risk + usage_volatility_risk + 
              plan_instability_risk + cost_satisfaction_risk) >= 2 then 'LOW_RISK'
        else 'STABLE'
    end as churn_risk_category,
    
    -- Predictive indicators
    case 
        when customer_tenure_days < 90 and (quality_risk_score + billing_volatility_risk + usage_volatility_risk + 
              plan_instability_risk + cost_satisfaction_risk) >= 3 then true
        when avg_call_quality < 2.5 then true
        when plan_changes > 2 and customer_tenure_days < 180 then true
        else false  
    end as immediate_intervention_required,
    
    current_timestamp() as model_run_timestamp

from churn_indicators
order by total_risk_score desc, avg_monthly_bill desc