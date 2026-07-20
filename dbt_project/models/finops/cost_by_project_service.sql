with billing as (

    select * from {{ ref('stg_billing_export') }}
    where cost_type = 'regular'  -- exclude tax, adjustments, rounding errors from the headline spend view

),

by_project_service as (

    select
        usage_date,
        invoice_month,
        project_id,
        project_name,
        service_description,
        currency,
        sum(net_cost)          as total_net_cost,
        sum(cost)               as total_gross_cost,
        sum(total_credits)      as total_credits

    from billing
    group by usage_date, invoice_month, project_id, project_name, service_description, currency

)

select * from by_project_service
order by usage_date desc, total_net_cost desc
