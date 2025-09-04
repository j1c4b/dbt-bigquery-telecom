{{ config(
    materialized='table',
    description="Revenue trend analysis with forecasting indicators and business intelligence"
) }}

-- Advanced Revenue Trend Analysis Model
-- Comprehensive revenue analytics with seasonality, growth trends, and forecasting
with monthly_revenue as (
    select 
        extract(year from billing_month) as revenue_year,
        extract(month from billing_month) as revenue_month,
        billing_month,
        
        -- Core revenue metrics
        sum(total_amount) as total_monthly_revenue,
        count(distinct customer_id) as active_customers,
        avg(total_amount) as avg_revenue_per_customer,
        
        -- Revenue distribution analysis (will be calculated later)
        stddev(total_amount) as revenue_standard_deviation,
        
        -- Customer segmentation
        sum(case when total_amount >= 100 then total_amount else 0 end) as premium_revenue,
        sum(case when total_amount between 50 and 99.99 then total_amount else 0 end) as standard_revenue, 
        sum(case when total_amount < 50 then total_amount else 0 end) as basic_revenue,
        
        count(case when total_amount >= 100 then 1 end) as premium_customers,
        count(case when total_amount between 50 and 99.99 then 1 end) as standard_customers,
        count(case when total_amount < 50 then 1 end) as basic_customers
        
    from {{ source('raw_telecom', 'billing') }}
    where billing_month is not null
    group by 1, 2, 3
),

monthly_percentiles as (
    select 
        billing_month,
        percentile_cont(total_amount, 0.5) over (partition by billing_month) as median_bill,
        percentile_cont(total_amount, 0.9) over (partition by billing_month) as p90_bill
    from {{ source('raw_telecom', 'billing') }}
    where billing_month is not null
    qualify row_number() over (partition by billing_month order by total_amount) = 1
),

revenue_trends as (
    select 
        mr.*,
        mp.median_bill,
        mp.p90_bill,
        -- Month-over-month growth calculations
        lag(mr.total_monthly_revenue, 1) over (order by mr.billing_month) as prev_month_revenue,
        lag(mr.active_customers, 1) over (order by mr.billing_month) as prev_month_customers,
        
        -- Year-over-year comparisons
        lag(mr.total_monthly_revenue, 12) over (order by mr.billing_month) as yoy_prev_revenue,
        lag(mr.active_customers, 12) over (order by mr.billing_month) as yoy_prev_customers,
        
        -- Rolling averages for smoothing
        avg(mr.total_monthly_revenue) over (
            order by mr.billing_month 
            rows between 2 preceding and current row
        ) as three_month_avg_revenue,
        
        avg(mr.avg_revenue_per_customer) over (
            order by mr.billing_month 
            rows between 5 preceding and current row  
        ) as six_month_avg_arpu
        
    from monthly_revenue mr
    left join monthly_percentiles mp on mr.billing_month = mp.billing_month
),

final_metrics as (
    select 
        revenue_year,
        revenue_month,
        billing_month,
        
        -- Core metrics
        total_monthly_revenue,
        active_customers,
        round(avg_revenue_per_customer, 2) as avg_revenue_per_customer,
        
        -- Growth metrics
        round(
            case 
                when prev_month_revenue > 0 
                then ((total_monthly_revenue - prev_month_revenue) / prev_month_revenue) * 100
                else null 
            end, 2
        ) as mom_revenue_growth_pct,
        
        round(
            case 
                when prev_month_customers > 0 
                then ((active_customers - prev_month_customers) / prev_month_customers) * 100
                else null 
            end, 2
        ) as mom_customer_growth_pct,
        
        round(
            case 
                when yoy_prev_revenue > 0 
                then ((total_monthly_revenue - yoy_prev_revenue) / yoy_prev_revenue) * 100
                else null 
            end, 2
        ) as yoy_revenue_growth_pct,
        
        -- Trend indicators
        round(three_month_avg_revenue, 2) as three_month_avg_revenue,
        round(six_month_avg_arpu, 2) as six_month_avg_arpu,
        
        -- Customer mix analysis
        round((premium_revenue / total_monthly_revenue) * 100, 1) as premium_revenue_share_pct,
        round((premium_customers / active_customers) * 100, 1) as premium_customer_share_pct,
        
        -- Revenue quality metrics
        round(median_bill, 2) as median_monthly_bill,
        round(p90_bill, 2) as p90_monthly_bill,
        round(revenue_standard_deviation, 2) as revenue_std_dev,
        
        -- Business health indicators
        case 
            when round(
                case 
                    when prev_month_revenue > 0 
                    then ((total_monthly_revenue - prev_month_revenue) / prev_month_revenue) * 100
                    else null 
                end, 2
            ) >= 5 then 'STRONG_GROWTH'
            when round(
                case 
                    when prev_month_revenue > 0 
                    then ((total_monthly_revenue - prev_month_revenue) / prev_month_revenue) * 100
                    else null 
                end, 2
            ) >= 0 then 'POSITIVE_GROWTH'
            when round(
                case 
                    when prev_month_revenue > 0 
                    then ((total_monthly_revenue - prev_month_revenue) / prev_month_revenue) * 100
                    else null 
                end, 2
            ) >= -5 then 'STABLE' 
            else 'DECLINING'
        end as revenue_trend_category,
        
        case 
            when (premium_revenue / total_monthly_revenue) >= 0.4 then 'PREMIUM_HEAVY'
            when (premium_revenue / total_monthly_revenue) >= 0.2 then 'BALANCED_MIX'
            else 'VALUE_FOCUSED'
        end as customer_mix_profile,
        
        -- Forecasting indicators (simple trend-based)
        round(
            three_month_avg_revenue * (1 + coalesce(
                case 
                    when prev_month_revenue > 0 
                    then ((total_monthly_revenue - prev_month_revenue) / prev_month_revenue) 
                    else 0 
                end, 0
            )), 2
        ) as next_month_revenue_forecast,
        
        current_timestamp() as model_run_timestamp
        
    from revenue_trends
)

select * 
from final_metrics
order by billing_month desc