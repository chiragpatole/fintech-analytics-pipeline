with source as (

    select * from {{ source('billing', 'gcp_billing_export') }}

),

renamed as (

    select
        billing_account_id,
        service.description                        as service_description,
        sku.description                             as sku_description,
        usage_start_time,
        usage_end_time,
        date(usage_start_time)                      as usage_date,
        project.id                                  as project_id,
        project.name                                as project_name,
        location.location                           as location,
        cost,
        currency,
        cost_type,
        invoice.month                               as invoice_month,
        labels,
        (select sum(c.amount) from unnest(credits) as c) as total_credits,
        cost + coalesce((select sum(c.amount) from unnest(credits) as c), 0) as net_cost

    from source

)

select * from renamed
