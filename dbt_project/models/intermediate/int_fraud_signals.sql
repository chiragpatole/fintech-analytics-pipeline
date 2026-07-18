with transactions as (

    select * from {{ ref('stg_transactions') }}

),

customer_avg as (

    select
        customer_id,
        avg(amount) as customer_avg_amount

    from transactions
    group by customer_id

),

flagged as (

    select
        t.*,
        c.customer_avg_amount,
        -- flag transactions well above the customer's own typical spend —
        -- a common, simple fraud heuristic worth pairing with the is_fraud
        -- label the generator produced
        (t.amount > c.customer_avg_amount * 3)  as is_amount_anomaly

    from transactions t
    left join customer_avg c using (customer_id)

)

select * from flagged
