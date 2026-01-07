{{ config(enabled=var('google_play__using_earnings', False)) }} 

with earnings as (

    select *
    from {{ ref('stg_google_play__earnings') }}
),  

daily_country_metrics as (

-- let's pivot out revenue metrics associated with each type of transaction type
{% set transaction_types = dbt_utils.get_column_values(table=ref('stg_google_play__earnings'), column="transaction_type") if execute and flags.WHICH in ('run', 'build') else [] %}

    select 
        source_relation,
        transaction_date as date_day,
        buyer_country as country_short, -- rolling up past states/territories
        sku_id, -- this will be a subscription or in-app product
        package_name,
        merchant_currency,
        sum(amount_merchant_currency) as net_amount,
        count(distinct order_id) as transactions
        {% for t in transaction_types %}
        , sum( case when lower(transaction_type) = '{{ t | lower }}' then amount_merchant_currency else 0 end ) as {{ t | replace(' ', '_') | lower }}_amount
        , count( distinct case when lower(transaction_type) = '{{ t | lower }}' then order_id end ) as {{ t | replace(' ', '_') | lower }}_transactions
        {% endfor %}
    from earnings
    {{ dbt_utils.group_by(6) }}
)

select *
from daily_country_metrics
