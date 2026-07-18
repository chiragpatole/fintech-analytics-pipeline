with source as (

    select * from {{ source('raw', 'transactions') }}

),

renamed as (

    select
        transaction_id,
        customer_id,
        account_id,
        cast(timestamp as timestamp) as transaction_timestamp,
        date(cast(timestamp as timestamp))  as transaction_date,
        round(amount, 2)                    as amount,
        upper(currency)                     as currency,
        merchant_name,
        lower(merchant_category)            as merchant_category,
        lower(transaction_type)             as transaction_type,
        upper(transaction_country)          as transaction_country,
        is_fraud

    from source

)

select * from renamed
