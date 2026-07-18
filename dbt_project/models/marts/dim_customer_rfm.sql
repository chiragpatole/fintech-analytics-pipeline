with activity as (

    select * from {{ ref('int_customer_activity') }}

),

scored as (

    select
        customer_id,
        account_id,
        total_transactions,
        total_amount,
        avg_transaction_amount,
        days_since_last_transaction,

        -- RFM scoring: 5 = best. Recency inverted since fewer days = better.
        ntile(5) over (order by days_since_last_transaction desc) as recency_score,
        ntile(5) over (order by total_transactions asc)           as frequency_score,
        ntile(5) over (order by total_amount asc)                 as monetary_score

    from activity

),

segmented as (

    select
        *,
        recency_score + frequency_score + monetary_score as rfm_total,
        case
            when recency_score >= 4 and frequency_score >= 4 and monetary_score >= 4 then 'champion'
            when recency_score >= 4 and frequency_score >= 3 then 'loyal'
            when recency_score <= 2 and frequency_score >= 4 then 'at_risk_high_value'
            when recency_score <= 2 and frequency_score <= 2 then 'churned'
            else 'developing'
        end as customer_segment

    from scored

)

select * from segmented
