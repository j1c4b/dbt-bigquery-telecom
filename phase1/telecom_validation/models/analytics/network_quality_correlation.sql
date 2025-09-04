{{ config(
    materialized='table',
    description="Network quality correlation analysis with customer satisfaction and business impact"
) }}

-- Advanced Network Quality Correlation Model
-- Analyzes relationships between network performance, customer behavior, and business outcomes
with quality_metrics as (
    select 
        nq.customer_id,
        
        -- Network quality aggregations
        avg(nq.call_quality_score) as avg_call_quality,
        min(nq.call_quality_score) as min_call_quality, 
        max(nq.call_quality_score) as max_call_quality,
        stddev(nq.call_quality_score) as call_quality_variance,
        count(*) as quality_measurements,
        
        -- Quality consistency metrics
        count(case when nq.call_quality_score >= 4 then 1 end) as high_quality_sessions,
        count(case when nq.call_quality_score <= 2 then 1 end) as poor_quality_sessions,
        
        -- Temporal quality patterns
        avg(case 
            when extract(hour from nq.recorded_at) between 9 and 17 then nq.call_quality_score 
        end) as business_hours_quality,
        avg(case 
            when extract(hour from nq.recorded_at) not between 9 and 17 then nq.call_quality_score 
        end) as off_hours_quality
        
    from {{ source('raw_telecom', 'network_quality') }} nq
    where nq.recorded_at is not null
    group by 1
),

customer_behavior as (
    select 
        u.customer_id,
        
        -- Usage behavior metrics
        avg(u.data_mb / 1024.0) as avg_data_usage,
        sum(u.call_minutes) as total_call_minutes,
        count(distinct u.usage_date) as active_usage_days,
        
        -- Usage patterns
        avg(case 
            when extract(dayofweek from u.usage_date) in (1, 7) then u.data_mb / 1024.0 
        end) as weekend_avg_usage,
        avg(case 
            when extract(dayofweek from u.usage_date) not in (1, 7) then u.data_mb / 1024.0 
        end) as weekday_avg_usage,
        
        -- Service utilization
        avg(u.sms_count) as avg_daily_sms,
        max(u.data_mb / 1024.0) as peak_daily_usage
        
    from {{ source('raw_telecom', 'usage_records') }} u
    where u.usage_date is not null
    group by 1
),

billing_impact as (
    select 
        b.customer_id,
        
        -- Billing metrics
        avg(b.total_amount) as avg_monthly_bill,
        sum(b.total_amount) as total_revenue,
        count(distinct b.billing_month) as billing_periods,
        stddev(b.total_amount) as billing_variance
        
    from {{ source('raw_telecom', 'billing') }} b  
    where b.billing_month is not null
    group by 1
),

correlation_analysis as (
    select 
        c.customer_id,
        c.customer_status,
        
        -- Network quality metrics
        coalesce(qm.avg_call_quality, 0) as avg_call_quality,
        coalesce(qm.call_quality_variance, 0) as call_quality_variance,
        coalesce(qm.quality_measurements, 0) as quality_measurements,
        
        -- Quality consistency ratios
        round(
            case 
                when qm.quality_measurements > 0 
                then (qm.high_quality_sessions * 100.0 / qm.quality_measurements)
                else 0 
            end, 2
        ) as high_quality_ratio_pct,
        
        round(
            case 
                when qm.quality_measurements > 0 
                then (qm.poor_quality_sessions * 100.0 / qm.quality_measurements) 
                else 0 
            end, 2
        ) as poor_quality_ratio_pct,
        
        -- Usage correlation
        coalesce(cb.avg_data_usage, 0) as avg_data_usage,
        coalesce(cb.total_call_minutes, 0) as total_call_minutes,
        coalesce(cb.active_usage_days, 0) as active_usage_days,
        
        -- Revenue correlation
        coalesce(bi.avg_monthly_bill, 0) as avg_monthly_bill,
        coalesce(bi.total_revenue, 0) as total_customer_revenue,
        
        -- Time-based quality patterns
        coalesce(qm.business_hours_quality, 0) as business_hours_quality,
        coalesce(qm.off_hours_quality, 0) as off_hours_quality
        
    from {{ source('raw_telecom', 'customers') }} c
    left join quality_metrics qm on c.customer_id = qm.customer_id
    left join customer_behavior cb on c.customer_id = cb.customer_id  
    left join billing_impact bi on c.customer_id = bi.customer_id
),

final_correlations as (
    select 
        *,
        
        -- Quality-Usage correlations
        case 
            when avg_call_quality >= 4.0 and avg_data_usage > 5.0 then 'HIGH_QUALITY_HIGH_USAGE'
            when avg_call_quality >= 4.0 and avg_data_usage <= 5.0 then 'HIGH_QUALITY_LOW_USAGE'
            when avg_call_quality < 3.0 and avg_data_usage > 5.0 then 'POOR_QUALITY_HIGH_USAGE'
            when avg_call_quality < 3.0 and avg_data_usage <= 5.0 then 'POOR_QUALITY_LOW_USAGE'
            else 'AVERAGE_QUALITY_USAGE'
        end as quality_usage_segment,
        
        -- Quality-Revenue correlations
        case 
            when avg_call_quality >= 4.0 and avg_monthly_bill > 75 then 'HIGH_QUALITY_HIGH_VALUE'
            when avg_call_quality >= 4.0 and avg_monthly_bill <= 75 then 'HIGH_QUALITY_STANDARD_VALUE'
            when avg_call_quality < 3.0 and avg_monthly_bill > 75 then 'POOR_QUALITY_HIGH_VALUE'
            else 'STANDARD_SEGMENT'
        end as quality_revenue_segment,
        
        -- Service satisfaction indicators
        case 
            when poor_quality_ratio_pct > 20 then 'AT_RISK'
            when poor_quality_ratio_pct > 10 then 'MONITOR'
            when high_quality_ratio_pct > 80 then 'SATISFIED'
            else 'NEUTRAL'
        end as satisfaction_indicator,
        
        -- Business impact scoring
        case 
            when avg_call_quality < 2.5 and avg_monthly_bill > 50 then 'HIGH_IMPACT_ISSUE'
            when avg_call_quality < 3.0 and poor_quality_ratio_pct > 15 then 'MEDIUM_IMPACT_ISSUE'
            when avg_call_quality >= 4.5 and high_quality_ratio_pct > 90 then 'EXCELLENT_SERVICE'
            else 'STANDARD_SERVICE'
        end as business_impact_category,
        
        -- Improvement priority
        case 
            when customer_status = 'Active' and avg_call_quality < 3.0 and avg_monthly_bill > 75 then 'CRITICAL_PRIORITY'
            when customer_status = 'Active' and poor_quality_ratio_pct > 25 then 'HIGH_PRIORITY'  
            when avg_call_quality < 3.5 and total_call_minutes > 500 then 'MEDIUM_PRIORITY'
            else 'LOW_PRIORITY'
        end as improvement_priority,
        
        current_timestamp() as model_run_timestamp
        
    from correlation_analysis
)

select *
from final_correlations
order by 
    case improvement_priority
        when 'CRITICAL_PRIORITY' then 1
        when 'HIGH_PRIORITY' then 2  
        when 'MEDIUM_PRIORITY' then 3
        else 4
    end,
    avg_monthly_bill desc