with transactions as (

    select * from {{ ref('stg_transactions') }}

),

daily_volume as (

    select
        transaction_date,
        currency,
        count(transaction_id)          as transaction_count,
        sum(amount)                    as total_amount,
        avg(amount)                    as avg_amount,
        countif(is_fraud)              as fraud_count,
        round(safe_divide(countif(is_fraud), count(transaction_id)) * 100, 3) as fraud_rate_pct

    from transactions
    group by transaction_date, currency

)

select * from daily_volume
order by transaction_date desc
