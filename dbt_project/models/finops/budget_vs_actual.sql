with billing as (

    select * from {{ ref('stg_billing_export') }}
    where cost_type = 'regular'

),

daily as (

    select
        invoice_month,
        usage_date,
        sum(net_cost) as daily_cost

    from billing
    group by invoice_month, usage_date

),

cumulative as (

    select
        invoice_month,
        usage_date,
        daily_cost,
        sum(daily_cost) over (
            partition by invoice_month
            order by usage_date
            rows between unbounded preceding and current row
        ) as cumulative_cost,
        -- day-of-month position, used to project a simple linear month-end pace
        row_number() over (partition by invoice_month order by usage_date) as day_number_in_month

    from daily

),

final as (

    select
        *,
        {{ var('finops_monthly_budget_eur', 5) }}                                    as monthly_budget_eur,
        cumulative_cost - {{ var('finops_monthly_budget_eur', 5) }}                  as variance_vs_budget,
        -- naive projection: today's daily average, held flat for a 30-day month
        round(safe_divide(cumulative_cost, day_number_in_month) * 30, 2)             as projected_month_end_cost,
        round(safe_divide(cumulative_cost, day_number_in_month) * 30, 2)
            > {{ var('finops_monthly_budget_eur', 5) }}                              as projected_to_exceed_budget

    from cumulative

)

select * from final
order by usage_date desc
