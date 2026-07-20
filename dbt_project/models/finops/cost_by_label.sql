with billing as (

    select * from {{ ref('stg_billing_export') }}
    where cost_type = 'regular'

),

-- LEFT JOIN UNNEST keeps rows with no labels at all (common for many GCP
-- resources) instead of silently dropping them from the cost total.
exploded as (

    select
        billing.usage_date,
        billing.invoice_month,
        coalesce(label.key, 'untagged')   as label_key,
        coalesce(label.value, 'untagged') as label_value,
        billing.net_cost,
        billing.currency

    from billing
    left join unnest(billing.labels) as label

),

by_label as (

    select
        usage_date,
        invoice_month,
        label_key,
        label_value,
        currency,
        sum(net_cost) as total_net_cost

    from exploded
    group by usage_date, invoice_month, label_key, label_value, currency

)

select * from by_label
order by usage_date desc, total_net_cost desc
