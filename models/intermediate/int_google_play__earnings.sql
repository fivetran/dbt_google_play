{{ config(enabled=var('google_play__using_earnings', False)) }} 

with earnings as (

    select *
    from {{ var('earnings') }}

), 

calc_net_amounts as (

    select 
        *,
        sum(amount_merchant_currency) over (partition by order_id) as net_order_amount
    from earnings
),

daily_country_metrics as (

-- let's pivot out revenue metrics associated wit each type of transaction type
{% set transaction_types = dbt_utils.get_column_values(table=ref('stg_google_play__earnings'), column="transaction_type") %}

    select 
        transaction_date as date_day,
        buyer_country as country, -- rolling up past states/territories
        sku_id, -- this will be a subscription or in-app product
        package_name,
        merchant_currency, -- should be the same across the whole table....idk does this need to be included?? it would be wack to sum up different currencies if they changed
        sum(net_order_amount) as net_amount,
        count(distinct order_id) as transactions
        {% for t in transaction_types %}
        , sum( case when lower(transaction_type) = '{{ t | lower }}' then amount_merchant_currency else 0 end ) as {{ t | replace(' ', '_') | lower }}_amount
        , count( distinct case when lower(transaction_type) = '{{ t | lower }}' then order_id end ) as {{ t | replace(' ', '_') | lower }}_transactions
        {% endfor %}
    from calc_net_amounts
    {{ dbt_utils.group_by(n=5) }}
)

select *
from daily_country_metrics