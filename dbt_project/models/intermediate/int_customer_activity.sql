with transactions as (

    select * from {{ ref('stg_transactions') }}

),

customer_activity as (

    select
        customer_id,
        account_id,
        count(transaction_id)                              as total_transactions,
        sum(amount)                                         as total_amount,
        avg(amount)                                         as avg_transaction_amount,
        min(transaction_date)                               as first_transaction_date,
        max(transaction_date)                               as last_transaction_date,
        count(distinct merchant_category)                   as distinct_merchant_categories,
        countif(is_fraud)                                   as fraud_transaction_count,
        date_diff(current_date(), max(transaction_date), day) as days_since_last_transaction

    from transactions
    group by customer_id, account_id

)

select * from customer_activity
