with fraud_signals as (

    select * from {{ ref('int_fraud_signals') }}

),

by_category as (

    select
        merchant_category,
        count(transaction_id)                                                     as total_transactions,
        countif(is_fraud)                                                         as labeled_fraud_count,
        countif(is_amount_anomaly)                                                as amount_anomaly_count,
        countif(is_fraud and is_amount_anomaly)                                   as fraud_and_anomaly_overlap,
        round(safe_divide(countif(is_fraud), count(transaction_id)) * 100, 3)     as fraud_rate_pct,
        sum(case when is_fraud then amount else 0 end)                           as total_fraud_amount

    from fraud_signals
    group by merchant_category

)

select * from by_category
order by fraud_rate_pct desc
